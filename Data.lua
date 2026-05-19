local _, SR = ...

-- Category definitions for grouping factions
SR.CATEGORIES = {
    { key = "dungeon",   en = "Dungeon Factions",    kr = "던전 진영", ru = "Фракции подземелий" },
    { key = "shattrath", en = "Shattrath City",      kr = "샤트라스", ru = "Шаттрат" },
    { key = "raid",      en = "Raid Factions",       kr = "레이드 진영", ru = "Фракции рейдов" },
    { key = "quest",     en = "Quest Hub Factions",  kr = "일일 퀘스트 진영", ru = "Фракции заданий" },
    { key = "other",     en = "Other",               kr = "기타", ru = "Другие" },
}

-- Faction metadata lookup by ID.
-- The actual reputation list is enumerated from the WoW API at runtime;
-- this table only supplies grouping/dungeon/item metadata for known IDs.
-- Any faction the player has but isn't listed here falls into "other".
SR.FACTION_INFO = {
    -- ============ Dungeon factions ============
    [946] = { category = "dungeon", name_en = "Honor Hold", name_ru = "Оплот Чести", dungeons = {
        { en = "Hellfire Ramparts",   kr = "지옥불 성루", ru = "Бастионы Адского Пламени" },
        { en = "The Blood Furnace",   kr = "피의 용광로", ru = "Кузня Крови" },
        { en = "The Shattered Halls", kr = "으스러진 손의 전당", ru = "Разрушенные залы" },
    }},
    [947] = { category = "dungeon", name_en = "Thrallmar", name_ru = "Траллмар", dungeons = {
        { en = "Hellfire Ramparts",   kr = "지옥불 성루", ru = "Бастионы Адского Пламени" },
        { en = "The Blood Furnace",   kr = "피의 용광로", ru = "Кузня Крови" },
        { en = "The Shattered Halls", kr = "으스러진 손의 전당", ru = "Разрушенные залы" },
    }},
    [942] = { category = "dungeon", name_en = "Cenarion Expedition", name_ru = "Кенарийская экспедиция", dungeons = {
        { en = "The Slave Pens", kr = "강제 노역소", ru = "Узилище" },
        { en = "The Underbog",   kr = "지하수렁", ru = "Нижетопь" },
        { en = "The Steamvault", kr = "증기 저장고", ru = "Паровое подземелье" },
    }},
    [1011] = { category = "dungeon", name_en = "Lower City", name_ru = "Нижний Город", dungeons = {
        { en = "Mana-Tombs",       kr = "마나 무덤", ru = "Гробницы Маны" },
        { en = "Auchenai Crypts",  kr = "아키나이 납골당", ru = "Аукенайские гробницы" },
        { en = "Sethekk Halls",    kr = "세데크 전당", ru = "Сетеккские залы" },
        { en = "Shadow Labyrinth", kr = "어둠의 미궁", ru = "Темный лабиринт" },
    }},
    [935] = { category = "dungeon", name_en = "The Sha'tar", name_ru = "Ша'тар", dungeons = {
        { en = "The Mechanar", kr = "메카나르", ru = "Механар" },
        { en = "The Botanica", kr = "신록의 정원", ru = "Ботаника" },
        { en = "The Arcatraz", kr = "알카트라즈", ru = "Аркатрац" },
    }},
    [989] = { category = "dungeon", name_en = "Keepers of Time", name_ru = "Хранители Времени", dungeons = {
        { en = "Old Hillsbrad Foothills", kr = "옛 힐스브래드 구릉지", ru = "Старые предгорья Хилсбрада" },
        { en = "The Black Morass",        kr = "검은늪", ru = "Черные топи" },
    }},

    -- ============ Shattrath factions ============
    [932] = { category = "shattrath", name_en = "The Aldor", name_ru = "Алдоры", dungeons = {}, items = {
        { en = "Mark of Kil'jaeden", kr = "킬제덴의 징표", ru = "Знак Кил'джедена",
          note_en = "Neutral \226\134\146 Honored", note_kr = "중립 \226\134\146 존경", note_ru = "Равнодушие \226\134\146 Уважение",
          desc_en = "Outland demons (lv60-), 10 per turn-in",
          desc_ru = "Демоны Запределья (60- уровни), сдавать по 10 шт." },
        { en = "Mark of Sargeras", kr = "살게라스의 징표", ru = "Знак Саргераса",
          note_en = "Honored \226\134\146 Exalted", note_kr = "존경 \226\134\146 확고한 동맹", note_ru = "Уважение \226\134\146 Превознесение",
          desc_en = "Outland demons (lv66+), 25 rep each, 1 or 10 per turn-in",
          desc_ru = "Демоны Запределья (66+ уровни), 25 реп. за шт., сдавать по 1 или 10 шт." },
        { en = "Fel Armament", kr = "지옥의 무기", ru = "Боеприпасы Скверны",
          note_en = "All levels", note_kr = "전 등급", note_ru = "Все уровни репутации",
          desc_en = "Rare drop from Outland demons, 350 rep, rewards Holy Dust",
          desc_ru = "Редкий дроп с демонов Запределья, 350 реп., в награду дает Святую пыль" },
    }},
    [934] = { category = "shattrath", name_en = "The Scryers", name_ru = "Провидцы", dungeons = {}, items = {
        { en = "Firewing Signet", kr = "화날개 인장", ru = "Перстень Огнекрылых",
          note_en = "Neutral \226\134\146 Honored", note_kr = "중립 \226\134\146 존경", note_ru = "Равнодушие \226\134\146 Уважение",
          desc_en = "Firewing blood elves in Terokkar, 10 per turn-in",
          desc_ru = "Эльфы крови из армии Огнекрылых в Тероккаре, сдавать по 10 шт." },
        { en = "Sunfury Signet", kr = "선퓨리 인장", ru = "Перстень Ярости Солнца",
          note_en = "Honored \226\134\146 Exalted", note_kr = "존경 \226\134\146 확고한 동맹", note_ru = "Уважение \226\134\146 Превознесение",
          desc_en = "Sunfury blood elves (lv66+), 25 rep each, 1 or 10 per turn-in",
          desc_ru = "Эльфы крови из клана Ярости Солнца (66+ уровни), 25 реп. за шт., сдавать по 1 или 10 шт." },
        { en = "Arcane Tome", kr = "비전 고서", ru = "Чародейский фолиант",
          note_en = "All levels", note_kr = "전 등급", note_ru = "Все уровни репутации",
          desc_en = "Rare drop from blood elves, 350 rep, rewards Arcane Rune",
          desc_ru = "Редкий дроп с эльфов крови, 350 реп., в награду дает Чародейскую руну" },
    }},

    -- ============ Raid factions ============
    [1012] = { category = "raid", name_en = "Ashtongue Deathsworn", name_ru = "Пеплоусты-служители", dungeons = {
        { en = "Black Temple", kr = "검은 사원", ru = "Черный Храм", raid = true },
    }},
    [990] = { category = "raid", name_en = "The Scale of the Sands", name_ru = "Песчаная Чешуя", dungeons = {
        { en = "Hyjal Summit", kr = "하이잘 산 전투", ru = "Вершина Хиджала", raid = true },
    }},
    [967] = { category = "raid", name_en = "The Violet Eye", name_ru = "Аметистовое Око", dungeons = {
        { en = "Karazhan", kr = "카라잔", ru = "Каражан", raid = true },
    }},

    -- ============ Quest-hub factions (P2 onwards) ============
    [1038] = { category = "quest", name_en = "Ogri'la", name_ru = "Огри'ла",
        note_en = "Blade's Edge Mountains daily quests",
        note_ru = "Ежедневные задания в Острогорье" },
    [1031] = { category = "quest", name_en = "Sha'tari Skyguard", name_ru = "Ша'тарские стражи Небес",
        note_en = "Terokkar Forest skyguard dailies",
        note_ru = "Ежедневные задания стражей Небес в Лесу Тероккар" },
    [933]  = { category = "quest", name_en = "The Consortium", name_ru = "Консорциум",
        note_en = "Netherstorm quests, gem turn-ins",
        note_ru = "Задания в Пустоверти, сдача самоцветов" },
    [978]  = { category = "quest", name_en = "Kurenai", name_ru = "Куренай",
        note_en = "Nagrand Broken quest hub (Alliance)",
        note_ru = "Оплот Сломленных в Награнде (Альянс)" },
    [941]  = { category = "quest", name_en = "The Mag'har", name_ru = "Маг'хары",
        note_en = "Nagrand Mag'har orc quest hub (Horde)",
        note_ru = "Оплот орков Маг'харов в Награнде (Орда)" },
    -- P4+ (will appear in popup once the player has the faction unlocked)
    [1015] = { category = "quest", name_en = "Netherwing", name_ru = "Крылья Пустоты",
        note_en = "Shadowmoon Valley netherdrake dailies",
        note_ru = "Ежедневные задания на драконов Пустоты в Долине Призрачной Луны" },
    [1077] = { category = "quest", name_en = "Shattered Sun Offensive", name_ru = "Армия Расколотого Солнца",
        note_en = "Isle of Quel'Danas dailies",
        note_ru = "Ежедневные задания на Острове Кель'Данас" },
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
