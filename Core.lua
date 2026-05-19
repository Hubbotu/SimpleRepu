local ADDON_NAME, SR = ...
local LDB = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")
local isKoKR = (GetLocale() == "koKR")
local _GetMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local VERSION = _GetMeta and _GetMeta(ADDON_NAME, "Version") or "unknown"

-- ============================================================
-- Saved state
-- ============================================================
local defaults = {
    minimapPos = 180,
    popupPos = nil,
    collapsedCategories = {},
}

-- ============================================================
-- Runtime state
-- ============================================================
local sessionData = {}
local sessionReady = false
local demoMode = false
local enumerating = false  -- recursion guard around expand/collapse

local hoverTip = nil       -- transient LibQTip on hover
local popupTip = nil       -- persistent LibQTip on click
local subTooltip = nil     -- per-line sub-tooltip (GameTooltip)
local hoverAnchor = nil

-- Forward declarations
local BuildContent, RefreshHover, RefreshPopup, TogglePopup, ShowHover

-- ============================================================
-- Helpers
-- ============================================================
local function L(en, kr)
    if isKoKR and kr then return kr end
    return en
end

local function GetStandingLabel(standingID)
    return _G["FACTION_STANDING_LABEL" .. (standingID or 4)] or UNKNOWN
end

local function GetStandingColor(standingID)
    local c = SR.STANDING_COLORS[standingID]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function MakeEntry(factionID, name, standingID, current, maximum)
    if maximum <= 0 then maximum = 1 end
    local info = SR.FACTION_INFO[factionID]
    return {
        id = factionID,
        name = name,
        info = info or {},
        category = (info and info.category) or "other",
        repData = {
            name = name,
            standingID = standingID,
            current = current,
            maximum = maximum,
            percent = current / maximum,
        },
    }
end

-- ============================================================
-- Faction Enumeration (API-driven, like Broker_Everything)
-- ============================================================
local DEMO_PRESETS = {
    { id = 946,  standing = 6, current = 8500,  maximum = 12000 },
    { id = 947,  standing = 5, current = 4200,  maximum = 6000  },
    { id = 942,  standing = 7, current = 15600, maximum = 21000 },
    { id = 1011, standing = 5, current = 2100,  maximum = 6000  },
    { id = 935,  standing = 4, current = 1800,  maximum = 3000  },
    { id = 989,  standing = 8, current = 999,   maximum = 999   },
    { id = 932,  standing = 6, current = 5500,  maximum = 12000 },
    { id = 934,  standing = 3, current = 1500,  maximum = 3000  },
    { id = 1012, standing = 4, current = 500,   maximum = 3000  },
    { id = 990,  standing = 5, current = 3000,  maximum = 6000  },
    { id = 967,  standing = 7, current = 18200, maximum = 21000 },
    { id = 1038, standing = 4, current = 500,   maximum = 3000  },
    { id = 1031, standing = 5, current = 1200,  maximum = 6000  },
    { id = 933,  standing = 5, current = 800,   maximum = 6000  },
}

local function GetDemoEnumeration()
    local result = {}
    for _, cat in ipairs(SR.CATEGORIES) do result[cat.key] = {} end
    for _, p in ipairs(DEMO_PRESETS) do
        local info = SR.FACTION_INFO[p.id]
        local apiName = GetFactionInfoByID(p.id)
        local name = apiName or (info and info.name_en) or ("Faction " .. p.id)
        local entry = MakeEntry(p.id, name, p.standing, p.current, p.maximum)
        table.insert(result[entry.category], entry)
    end
    return result
end

local function EnumerateFactions()
    if demoMode then return GetDemoEnumeration() end
    if enumerating then return nil end
    enumerating = true

    local toRestore = {}
    local i = 1
    while i <= GetNumFactions() do
        local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
        if isHeader and isCollapsed then
            toRestore[name] = true
            ExpandFactionHeader(i)
        end
        i = i + 1
    end

    local result = {}
    for _, cat in ipairs(SR.CATEGORIES) do result[cat.key] = {} end

    for idx = 1, GetNumFactions() do
        local name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep, _, _, factionID = GetFactionInfo(idx)
        -- Include normal factions and "header-with-rep" entries; skip pure headers.
        -- hasRep is nil for regular factions in TBC Classic, so we cannot require it.
        if ((not isHeader) or hasRep) and factionID and factionID > 0 then
            local current = (barValue or 0) - (barMin or 0)
            local maximum = (barMax or 0) - (barMin or 0)
            local entry = MakeEntry(factionID, name, standingID, current, maximum)
            table.insert(result[entry.category], entry)
        end
    end

    for k = GetNumFactions(), 1, -1 do
        local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(k)
        if isHeader and (not isCollapsed) and toRestore[name] then
            CollapseFactionHeader(k)
            toRestore[name] = nil
        end
    end

    enumerating = false
    return result
end

-- ============================================================
-- Session Tracking (relative value across standings)
-- ============================================================
local function UpdateSession(factionID, repData)
    if not repData or not sessionReady then return end
    local s = sessionData[factionID]
    if not s then
        sessionData[factionID] = {
            standingID = repData.standingID,
            baseline = repData.current,
            max = repData.maximum,
            accumulated = 0,
            diff = 0,
        }
    else
        if s.standingID ~= repData.standingID then
            -- Ding: close out gain in the old standing into the accumulator,
            -- then re-baseline at 0 for the new standing. A rep loss that
            -- drops a standing inflates the result (rare edge case).
            s.accumulated = s.accumulated + (s.max - s.baseline)
            s.standingID = repData.standingID
            s.baseline = 0
            s.max = repData.maximum
        end
        s.diff = s.accumulated + (repData.current - s.baseline)
    end
end

local function GetSessionDiff(factionID)
    local s = sessionData[factionID]
    return s and s.diff ~= 0 and s.diff or nil
end

local function UpdateSessionsFrom(enumeration)
    if not enumeration then return end
    for _, cat in ipairs(SR.CATEGORIES) do
        for _, entry in ipairs(enumeration[cat.key]) do
            UpdateSession(entry.id, entry.repData)
        end
    end
end

local function UpdateAllSessions()
    UpdateSessionsFrom(EnumerateFactions())
end

local function ResetSession()
    wipe(sessionData)
    UpdateAllSessions()
    RefreshPopup()
    if hoverAnchor then ShowHover(hoverAnchor) end
end

-- ============================================================
-- Sub-tooltip (faction hover → dungeon list, gained, etc.)
-- ============================================================
local function GetSubTooltip()
    if not subTooltip then
        subTooltip = CreateFrame("GameTooltip", "SimpleRepuSubTooltip", UIParent, "GameTooltipTemplate")
        subTooltip:SetFrameStrata("TOOLTIP")
    end
    return subTooltip
end

local function HideSubTooltip()
    if subTooltip then subTooltip:Hide() end
end

local function FindTooltipFrame(frame)
    while frame and frame:GetParent() and frame:GetParent() ~= UIParent do
        frame = frame:GetParent()
    end
    return frame
end

local function OnFactionEnter(self, entry)
    if not entry then return end
    local repData = entry.repData
    local owner = FindTooltipFrame(self) or self
    local st = GetSubTooltip()
    st:SetOwner(owner, "ANCHOR_NONE")
    st:ClearAllPoints()
    st:SetPoint("TOPLEFT", owner, "TOPRIGHT", 4, 0)

    st:AddLine(entry.name, 1, 1, 1)

    if repData.standingID < 8 then
        local need = repData.maximum - repData.current
        st:AddDoubleLine(L("Need for next standing", "다음 평판까지 필요"), tostring(need), 0.7, 0.7, 0.7, 1, 1, 1)
    end

    local diff = GetSessionDiff(entry.id)
    if diff then
        local prefix = diff > 0 and "+" or ""
        local cr, cg, cb = 0.27, 1, 0.27
        if diff < 0 then cr, cg, cb = 1, 0.27, 0.27 end
        st:AddDoubleLine(L("Gained", "획득"), prefix .. diff, 0.7, 0.7, 0.7, cr, cg, cb)
    end

    local info = entry.info
    if info.dungeons and #info.dungeons > 0 then
        st:AddLine(" ")
        for _, d in ipairs(info.dungeons) do
            local dr, dg, db = 1, 1, 1
            if d.raid then dr, dg, db = 1, 0.4, 0.4 end
            st:AddLine("  " .. L(d.en, d.kr), dr, dg, db)
        end
    elseif info.note_en or info.note_kr then
        st:AddLine(" ")
        st:AddLine("  " .. L(info.note_en or "", info.note_kr or ""), 0.8, 0.8, 0.8)
    end

    st:Show()
end

local function OnFactionLeave()
    HideSubTooltip()
end

-- ============================================================
-- Shared rendering: builds rows into a LibQTip tooltip
-- ============================================================
local function ToggleCategory(_, payload)
    SimpleRepuDB.collapsedCategories[payload.key] =
        not SimpleRepuDB.collapsedCategories[payload.key] or nil
    if payload.popup then
        RefreshPopup()
    elseif hoverAnchor then
        ShowHover(hoverAnchor)
    end
end

BuildContent = function(tt, isPopup)
    tt:Clear()
    tt:AddHeader("|cff00ccff" .. L("Simple Repu", "평판 가이드") .. " v" .. VERSION .. "|r")
    tt:AddSeparator()

    local enumeration = EnumerateFactions()
    if not enumeration then return end
    UpdateSessionsFrom(enumeration)

    for _, cat in ipairs(SR.CATEGORIES) do
        local entries = enumeration[cat.key]
        if entries and #entries > 0 then
            local isCollapsed = SimpleRepuDB.collapsedCategories[cat.key]
            local arrow = isCollapsed and "\226\150\182 " or "\226\150\188 "  -- ▶ / ▼
            local color = isCollapsed and "|cff808080" or "|cff69ccf0"

            local headerLine = tt:AddLine()
            tt:SetCell(headerLine, 1,
                color .. arrow .. L(cat.en, cat.kr) .. "|r",
                nil, "LEFT", 3)
            tt:SetLineScript(headerLine, "OnMouseUp", ToggleCategory,
                { key = cat.key, popup = isPopup })

            if not isCollapsed then
                for _, entry in ipairs(entries) do
                    local repData = entry.repData
                    local standing = GetStandingLabel(repData.standingID)
                    local r, g, b = GetStandingColor(repData.standingID)
                    local standingHex = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)

                    local valueStr = ""
                    if repData.standingID < 8 then
                        local diff = GetSessionDiff(entry.id)
                        if diff and diff > 0 then
                            valueStr = string.format("|cff44ff44%d|r / %d", repData.current, repData.maximum)
                        else
                            valueStr = string.format("%d / %d", repData.current, repData.maximum)
                        end
                    end

                    local line = tt:AddLine(
                        "  |cfffff569" .. entry.name .. "|r",
                        standingHex .. standing .. "|r",
                        valueStr
                    )
                    tt:SetLineScript(line, "OnEnter", OnFactionEnter, entry)
                    tt:SetLineScript(line, "OnLeave", OnFactionLeave)
                end
            end
        end
    end

    tt:AddLine(" ")
    local hintLine = tt:AddLine()
    tt:SetCell(hintLine, 1,
        "|cff666666" .. L("Help: eomma-so", "도움: 엄마소") .. "|r",
        nil, "LEFT", 3)
end

-- ============================================================
-- Hover tooltip (LDB / minimap mouseover)
-- ============================================================
ShowHover = function(anchor)
    HideSubTooltip()
    if hoverTip then LibQTip:Release(hoverTip); hoverTip = nil end

    hoverAnchor = anchor
    hoverTip = LibQTip:Acquire("SimpleRepuHover", 3, "LEFT", "LEFT", "RIGHT")
    BuildContent(hoverTip, false)

    hoverTip:SetAutoHideDelay(0.25, anchor, function()
        HideSubTooltip()
        if hoverTip then LibQTip:Release(hoverTip); hoverTip = nil end
        hoverAnchor = nil
    end)
    hoverTip:SmartAnchorTo(anchor)
    hoverTip:Show()
end

-- ============================================================
-- Persistent popup (left-click)
-- ============================================================
local function SavePopupPos(frame)
    frame:StopMovingOrSizing()
    local point, _, relPoint, x, y = frame:GetPoint()
    SimpleRepuDB.popupPos = { point = point, relPoint = relPoint, x = x, y = y }
end

RefreshPopup = function()
    if not popupTip then return end
    BuildContent(popupTip, true)
end

local function HidePopup()
    HideSubTooltip()
    if popupTip then
        popupTip:EnableKeyboard(false)
        popupTip:SetScript("OnKeyDown", nil)
        LibQTip:Release(popupTip)
        popupTip = nil
    end
end

local function ShowPopup()
    if popupTip then return end
    popupTip = LibQTip:Acquire("SimpleRepuPopup", 3, "LEFT", "LEFT", "RIGHT")

    -- Make draggable & remember position
    popupTip:SetMovable(true)
    popupTip:EnableMouse(true)
    popupTip:RegisterForDrag("LeftButton")
    popupTip:SetScript("OnDragStart", popupTip.StartMoving)
    popupTip:SetScript("OnDragStop", SavePopupPos)

    -- ESC closes; let other keys pass through so chat / hotkeys still work
    popupTip:EnableKeyboard(true)
    popupTip:SetPropagateKeyboardInput(true)
    popupTip:SetScript("OnKeyDown", function(self, key)
        self:SetPropagateKeyboardInput(true)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            HidePopup()
        end
    end)

    popupTip:ClearAllPoints()
    local pos = SimpleRepuDB.popupPos
    if pos then
        popupTip:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        popupTip:SetPoint("CENTER")
    end

    BuildContent(popupTip, true)
    popupTip:Show()
end

TogglePopup = function()
    if popupTip then HidePopup() else ShowPopup() end
end

-- ============================================================
-- LDB Data Object
-- ============================================================
local dataObj = LDB:NewDataObject("SimpleRepu", {
    type = "data source",
    text = L("Simple Repu", "평판 가이드"),
    label = L("Simple Repu", "평판 가이드"),
    icon = "Interface\\Icons\\Achievement_Reputation_01",
    OnEnter = function(self) ShowHover(self) end,
    OnLeave = function() end,  -- LibQTip auto-hides
    OnClick = function(_, button)
        if button == "LeftButton" then TogglePopup() end
    end,
})

-- ============================================================
-- Event Frame, Minimap Button, Slash Commands
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        if not SimpleRepuDB then
            SimpleRepuDB = CopyTable(defaults)
        end
        for k, v in pairs(defaults) do
            if SimpleRepuDB[k] == nil then
                SimpleRepuDB[k] = type(v) == "table" and CopyTable(v) or v
            end
        end
        if type(SimpleRepuDB.collapsedCategories) ~= "table" then
            SimpleRepuDB.collapsedCategories = {}
        end

        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("UPDATE_FACTION")

        SLASH_SIMPLEREPU1 = "/sr"
        SLASH_SIMPLEREPU2 = "/simplerepu"
        SlashCmdList["SIMPLEREPU"] = function(msg)
            msg = (msg or ""):trim():lower()
            if msg == "reset" then
                ResetSession()
                print("|cff00ccff[SimpleRepu]|r " .. L("Session reset.", "세션이 초기화되었습니다."))
            elseif msg == "demo" then
                demoMode = not demoMode
                wipe(sessionData)
                if demoMode then
                    sessionData[942]  = { standingID = 7, baseline = 15600 - 350, max = 21000, accumulated = 0, diff = 350 }
                    sessionData[967]  = { standingID = 7, baseline = 18200 - 120, max = 21000, accumulated = 0, diff = 120 }
                    sessionData[1011] = { standingID = 5, baseline = 2100 - 75,   max = 6000,  accumulated = 0, diff = 75  }
                    print("|cff00ccff[SimpleRepu]|r " .. L("Demo mode ON", "데모 모드 켜짐"))
                else
                    UpdateAllSessions()
                    print("|cff00ccff[SimpleRepu]|r " .. L("Demo mode OFF", "데모 모드 꺼짐"))
                end
                if popupTip then RefreshPopup() else TogglePopup() end
            else
                TogglePopup()
            end
        end

        -- ======== Minimap Button ========
        local minimapBtn = CreateFrame("Button", "SimpleRepuMinimapBtn", Minimap)
        minimapBtn:SetSize(32, 32)
        minimapBtn:SetFrameStrata("MEDIUM")
        minimapBtn:SetFrameLevel(8)
        minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

        local bg = minimapBtn:CreateTexture(nil, "BACKGROUND")
        bg:SetSize(24, 24)
        bg:SetPoint("CENTER", 0, 0)
        bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

        local overlay = minimapBtn:CreateTexture(nil, "OVERLAY")
        overlay:SetSize(54, 54)
        overlay:SetPoint("TOPLEFT")
        overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

        local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(25, 25)
        icon:SetPoint("CENTER", 0, 0)
        icon:SetTexture("Interface\\Icons\\Achievement_Reputation_01")

        local function UpdateMinimapPos()
            local angle = math.rad(SimpleRepuDB.minimapPos)
            minimapBtn:ClearAllPoints()
            minimapBtn:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(angle), 80 * math.sin(angle))
        end
        UpdateMinimapPos()

        minimapBtn:RegisterForDrag("RightButton")
        minimapBtn:RegisterForClicks("LeftButtonUp")
        minimapBtn:SetScript("OnClick", function() TogglePopup() end)
        minimapBtn:SetScript("OnEnter", function(btn) ShowHover(btn) end)
        minimapBtn:SetScript("OnLeave", function() end)
        minimapBtn:SetScript("OnDragStart", function(btn)
            btn:SetScript("OnUpdate", function()
                local mx, my = Minimap:GetCenter()
                local cx, cy = GetCursorPosition()
                local scale = Minimap:GetEffectiveScale()
                cx, cy = cx / scale, cy / scale
                SimpleRepuDB.minimapPos = math.deg(math.atan2(cy - my, cx - mx))
                UpdateMinimapPos()
            end)
        end)
        minimapBtn:SetScript("OnDragStop", function(btn)
            btn:SetScript("OnUpdate", nil)
        end)

        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_ENTERING_WORLD" then
        sessionReady = true
        UpdateAllSessions()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    elseif event == "UPDATE_FACTION" then
        if enumerating then return end
        UpdateAllSessions()
        if popupTip then RefreshPopup() end
        if hoverTip and hoverAnchor then BuildContent(hoverTip, false) end
    end
end)
