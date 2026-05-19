local _, SR = ...

-- Category definitions for grouping factions
SR.CATEGORIES = {
    { key = "dungeon",   en = "Dungeon Factions",    kr = "던전 진영" },
    { key = "shattrath", en = "Shattrath City",      kr = "샤트라스" },
    { key = "raid",      en = "Raid Factions",       kr = "레이드 진영" },
    { key = "quest",     en = "Quest Hub Factions",  kr = "일일 퀘스트 진영" },
    { key = "other",     en = "Other",               kr = "기타" },
}

-- Faction metadata lookup by ID.
-- The actual reputation list is enumerated from the WoW API at runtime;
-- this table only supplies grouping/dungeon/item metadata for known IDs.
-- Any faction the player has but isn't listed here falls into "other".
SR.FACTION_INFO = {
    -- ============ Dungeon factions ============
    [946] = { category = "dungeon", name_en = "Honor Hold", dungeons = {
        { en = "Hellfire Ramparts",   kr = "지옥불 성루" },
        { en = "The Blood Furnace",   kr = "피의 용광로" },
        { en = "The Shattered Halls", kr = "으스러진 손의 전당" },
    }},
    [947] = { category = "dungeon", name_en = "Thrallmar", dungeons = {
        { en = "Hellfire Ramparts",   kr = "지옥불 성루" },
        { en = "The Blood Furnace",   kr = "피의 용광로" },
        { en = "The Shattered Halls", kr = "으스러진 손의 전당" },
    }},
    [942] = { category = "dungeon", name_en = "Cenarion Expedition", dungeons = {
        { en = "The Slave Pens", kr = "강제 노역소" },
        { en = "The Underbog",   kr = "지하수렁" },
        { en = "The Steamvault", kr = "증기 저장고" },
    }},
    [1011] = { category = "dungeon", name_en = "Lower City", dungeons = {
        { en = "Mana-Tombs",       kr = "마나 무덤" },
        { en = "Auchenai Crypts",  kr = "아키나이 납골당" },
        { en = "Sethekk Halls",    kr = "세데크 전당" },
        { en = "Shadow Labyrinth", kr = "어둠의 미궁" },
    }},
    [935] = { category = "dungeon", name_en = "The Sha'tar", dungeons = {
        { en = "The Mechanar", kr = "메카나르" },
        { en = "The Botanica", kr = "신록의 정원" },
        { en = "The Arcatraz", kr = "알카트라즈" },
    }},
    [989] = { category = "dungeon", name_en = "Keepers of Time", dungeons = {
        { en = "Old Hillsbrad Foothills", kr = "옛 힐스브래드 구릉지" },
        { en = "The Black Morass",        kr = "검은늪" },
    }},

    -- ============ Shattrath factions ============
    [932] = { category = "shattrath", name_en = "The Aldor", dungeons = {}, items = {
        { en = "Mark of Kil'jaeden", kr = "킬제덴의 징표",
          note_en = "Neutral \226\134\146 Honored", note_kr = "중립 \226\134\146 존경",
          desc_en = "Outland demons (lv60-), 10 per turn-in",
          desc_kr = "아웃랜드 악마 (60레벨 이하) 드랍, 10개 단위 반납" },
        { en = "Mark of Sargeras", kr = "살게라스의 징표",
          note_en = "Honored \226\134\146 Exalted", note_kr = "존경 \226\134\146 확고한 동맹",
          desc_en = "Outland demons (lv66+), 25 rep each, 1 or 10 per turn-in",
          desc_kr = "아웃랜드 악마 (66레벨+) 드랍, 개당 25 평판, 1개 또는 10개 반납" },
        { en = "Fel Armament", kr = "지옥의 무기",
          note_en = "All levels", note_kr = "전 등급",
          desc_en = "Rare drop from Outland demons, 350 rep, rewards Holy Dust",
          desc_kr = "아웃랜드 악마 희귀 드랍, 350 평판, 신성한 가루 보상" },
    }},
    [934] = { category = "shattrath", name_en = "The Scryers", dungeons = {}, items = {
        { en = "Firewing Signet", kr = "화날개 인장",
          note_en = "Neutral \226\134\146 Honored", note_kr = "중립 \226\134\146 존경",
          desc_en = "Firewing blood elves in Terokkar, 10 per turn-in",
          desc_kr = "테로카르 화날개 블러드엘프 드랍, 10개 단위 반납" },
        { en = "Sunfury Signet", kr = "선퓨리 인장",
          note_en = "Honored \226\134\146 Exalted", note_kr = "존경 \226\134\146 확고한 동맹",
          desc_en = "Sunfury blood elves (lv66+), 25 rep each, 1 or 10 per turn-in",
          desc_kr = "선퓨리 블러드엘프 (66레벨+) 드랍, 개당 25 평판, 1개 또는 10개 반납" },
        { en = "Arcane Tome", kr = "비전 고서",
          note_en = "All levels", note_kr = "전 등급",
          desc_en = "Rare drop from blood elves, 350 rep, rewards Arcane Rune",
          desc_kr = "블러드엘프 희귀 드랍, 350 평판, 비전의 룬 보상" },
    }},

    -- ============ Raid factions ============
    [1012] = { category = "raid", name_en = "Ashtongue Deathsworn", dungeons = {
        { en = "Black Temple", kr = "검은 사원", raid = true },
    }},
    [990] = { category = "raid", name_en = "The Scale of the Sands", dungeons = {
        { en = "Hyjal Summit", kr = "하이잘 산 전투", raid = true },
    }},
    [967] = { category = "raid", name_en = "The Violet Eye", dungeons = {
        { en = "Karazhan", kr = "카라잔", raid = true },
    }},

    -- ============ Quest-hub factions (P2 onwards) ============
    [1038] = { category = "quest", name_en = "Ogri'la",
        note_en = "Blade's Edge Mountains daily quests",
        note_kr = "칼날산맥 일일 퀘스트" },
    [1031] = { category = "quest", name_en = "Sha'tari Skyguard",
        note_en = "Terokkar Forest skyguard dailies",
        note_kr = "테로카르 숲 하늘경비대 일일 퀘스트" },
    [933]  = { category = "quest", name_en = "The Consortium",
        note_en = "Netherstorm quests, gem turn-ins",
        note_kr = "네더스톰 퀘스트, 보석 납품" },
    [978]  = { category = "quest", name_en = "Kurenai",
        note_en = "Nagrand Broken quest hub (Alliance)",
        note_kr = "나그란드 부서진 자들 (얼라이언스)" },
    [941]  = { category = "quest", name_en = "The Mag'har",
        note_en = "Nagrand Mag'har orc quest hub (Horde)",
        note_kr = "나그란드 마그하르 (호드)" },
    -- P4+ (will appear in popup once the player has the faction unlocked)
    [1015] = { category = "quest", name_en = "Netherwing",
        note_en = "Shadowmoon Valley netherdrake dailies",
        note_kr = "어둠달 골짜기 황천룡 일일 퀘스트" },
    [1077] = { category = "quest", name_en = "Shattered Sun Offensive",
        note_en = "Isle of Quel'Danas dailies",
        note_kr = "퀄다나스 섬 일일 퀘스트" },
}

-- Standing colors (better differentiation than FACTION_BAR_COLORS)
SR.STANDING_COLORS = {
    [1] = { r = 0.8,  g = 0.13, b = 0.13 }, -- Hated
    [2] = { r = 0.8,  g = 0.26, b = 0.13 }, -- Hostile
    [3] = { r = 0.75, g = 0.47, b = 0.07 }, -- Unfriendly
    [4] = { r = 0.9,  g = 0.7,  b = 0.0 },  -- Neutral
    [5] = { r = 0.0,  g = 0.7,  b = 0.0 },  -- Friendly
    [6] = { r = 0.0,  g = 0.6,  b = 0.1 },  -- Honored
    [7] = { r = 0.0,  g = 0.5,  b = 0.9 },  -- Revered
    [8] = { r = 0.0,  g = 0.9,  b = 0.7 },  -- Exalted
}
