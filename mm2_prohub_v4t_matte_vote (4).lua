--[[
    MM2 PRO HUB  |  v4.0  "Matte"
    v4.0: плоский матовый интерфейс без неона (боковая панель вкладок, спокойная палитра, один акцент,
          без градиентов, свечения и частиц) + новое интро: сетка точек, логотип, буквы «выезжают» из-под маски,
          тонкий прогресс с этапами и раскрытие «шторками» (две половины экрана разъезжаются).
          Логика Auto-Farm / ESP / Speed / Fly / Авто-подбор пистолета не менялась.
    v4.1: переключатель языка (Настройки -> Язык: English по умолчанию / Русский) и вкладка «Голосование»
          (отдельная панель: карты из workspace.Lobby.VotePads, клик = телепорт на Pad -> ресет -> повтор N раз). Остальная логика не менялась.
    Клик или любая клавиша во время интро — пропустить.
    Fly: WASD + Space / LeftShift (вниз). Не работает, пока включён Auto-Farm.
    Показать/скрыть окно: RightShift

]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TextService      = game:GetService("TextService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

-- ═══════════════ ТЕМА (плоская, матовая, один акцент) ═══════════════
local Theme = {
    Bg       = Color3.fromRGB(22, 23, 27),
    Sidebar  = Color3.fromRGB(17, 18, 21),
    Card     = Color3.fromRGB(30, 32, 37),
    CardHov  = Color3.fromRGB(37, 39, 45),
    Accent   = Color3.fromRGB(136, 98, 232),
    AccentHi = Color3.fromRGB(184, 160, 246),
    Text     = Color3.fromRGB(232, 233, 238),
    TextDim  = Color3.fromRGB(132, 136, 148),
    Stroke   = Color3.fromRGB(44, 46, 53),
    StrokeHi = Color3.fromRGB(62, 65, 75),
    Danger   = Color3.fromRGB(214, 84, 94),
    Good     = Color3.fromRGB(96, 190, 140),
}

local State = {
    ESP = false,
    Speed = false,
    SpeedValue = 50,
    Fly = false,
    AutoFarm = false,
    FarmReset = true,     -- после 40 монет сделать ресет (смерть) и ждать следующий раунд
    AntiAFK = true,
    AutoGun = false,
    FarmMethod = "touch", -- "touch": летим под монетой и тянемся головой / "teleport": сидим за картой, к монете — мгновенный телепорт
    FarmFlySpeed = 24,
    TpSpeed = 24, -- Teleport: максимальная скорость перемещения между монетами, стад/с (против кика за слишком быстрый телепорт)
    FarmHideDepth = 3,   -- на сколько стадов ниже пола лежим
    FarmStartDelay = 0,  -- сколько секунд после старта раунда ждём, прежде чем лететь за монетами
    FarmTrigger = "coins", -- что считать стартом раунда: "role" (выдача ролей) или "coins" (появление монет)
    FlySpeed = 50,
    Aimbot = false,
}

local Stats = { coins = 0, rounds = 0, resets = 0, t0 = os.clock() } -- статистика сессии

-- ═══════════════ ЯЗЫК / LANGUAGE ═══════════════
-- Исходные строки в скрипте русские и служат ключами. Lang = "en" (по умолчанию) показывает перевод из EN,
-- "ru" — исходный текст. Строка без перевода показывается как есть. Переключатель: Настройки -> Язык.
local I18N = { lang = "en" }
I18N.EN = {
    ["Фарм выкл"] = "Farm off",
    ["Привет, "] = "Hi, ",
    ["  ·  RightShift — скрыть / показать окно"] = "  ·  RightShift — hide / show window",
    ["Включено"] = "Enabled",
    ["Выключено"] = "Disabled",
    ["Основное"] = "Main",
    ["Движение и бой"] = "Movement and combat",
    ["Визуал"] = "Visuals",
    ["Подсветка игроков"] = "Player highlights",
    ["Фарм"] = "Farm",
    ["Автосбор монет и конфет"] = "Auto-collect coins and candy",
    ["Убийца"] = "Murderer",
    ["Телепорт к игроку и удар"] = "Teleport to a player and stab",
    ["Статистика"] = "Stats",
    ["Итоги этой сессии"] = "This session's totals",
    ["Настройки"] = "Settings",
    ["Интерфейс и сессия"] = "Interface and session",
    ["Голосование"] = "Voting",
    ["Панель голосования за карту"] = "Map vote panel",
    ["Движение"] = "Movement",
    ["Переопределяет WalkSpeed"] = "Overrides WalkSpeed",
    ["Скорость"] = "Speed",
    ["Fly (Полёт)"] = "Fly",
    ["WASD + Space вверх / Shift вниз"] = "WASD + Space up / Shift down",
    ["Скорость Fly"] = "Fly speed",
    ["Бой"] = "Combat",
    ["Авто-подбор пистолета"] = "Auto gun pickup",
    ["Шериф умер: на миг телепорт к пистолету и обратно (только в раунде)"] = "Sheriff died: briefly teleport to the gun and back (rounds only)",
    ["Пока без логики, как в исходнике"] = "No logic yet, same as the original",
    ["Игроки"] = "Players",
    ["ESP Игроков (Роли)"] = "Player ESP (roles)",
    ["Автоматизация"] = "Automation",
    ["Под картой, монеты находит сам. Лобби и смерть — выкл."] = "Works under the map and finds coins itself. Off in lobby and when dead.",
    ["Режим фарма"] = "Farm mode",
    ["Ресет после 40 монет"] = "Reset after 40 coins",
    ["Собрал 40 — ресет и ждём следующий раунд. Выкл: собирает без лимита"] = "Collected 40: reset and wait for the next round. Off: collects with no limit",
    ["Скорость полёта"] = "Flight speed",
    ["Скорость телепорта, стад/с"] = "Teleport speed, studs/s",
    ["Старт отсчёта"] = "Round start trigger",
    ["Выдача роли"] = "Role handout",
    ["Появление монет"] = "Coins appear",
    ["Ожидание перед фармом"] = "Delay before farming",
    ["0 с"] = "0 s",
    ["6 с"] = "6 s",
    ["12 с"] = "12 s",
    ["18 с"] = "18 s",
    ["Анти-АФК"] = "Anti-AFK",
    ["Не выкидывает с сервера за бездействие"] = "Prevents the idle kick",
    ["Диагностика"] = "Diagnostics",
    ["Статус: выключено"] = "Status: off",
    ["Монеты: авто (по умолчанию coin / candy)"] = "Coins: auto (default coin / candy)",
    ["Монеты: авто (%s)"] = "Coins: auto (%s)",
    ["Монеты в раунде"] = "Coins this round",
    ["Фарм: пауза"] = "Farm: paused",
    ["Фарм "] = "Farm ",
    ["УБИТЬ"] = "KILL",
    ["Статус"] = "Status",
    ["Твоя роль: …"] = "Your role: …",
    ["Ты убийца: выбери игрока ниже"] = "You are the murderer: pick a player below",
    ["Твоя роль: %s. Работает только у убийцы"] = "Your role: %s. Works only for the murderer",
    ["Макс. время у цели, мс"] = "Max time at target, ms",
    ["Игроки (нажми, чтобы убить)"] = "Players (tap to kill)",
    ["Эта сессия"] = "This session",
    ["Монет собрано"] = "Coins collected",
    ["Раундов в фарме"] = "Rounds farmed",
    ["Ресетов"] = "Resets",
    ["Время сессии"] = "Session time",
    ["Интерфейс"] = "Interface",
    ["Масштаб окна, %"] = "Window scale, %",
    ["Свернуть / показать  (RightShift)"] = "Minimize / show  (RightShift)",
    ["Сессия"] = "Session",
    ["Выгрузить скрипт"] = "Unload script",
    ["Язык"] = "Language",
    ["Инициализация ядра…"] = "Initializing core…",
    ["Загрузка интерфейса…"] = "Loading interface…",
    ["Сканирование карты…"] = "Scanning the map…",
    ["Подключение ESP…"] = "Connecting ESP…",
    ["Калибровка автофарма…"] = "Calibrating auto-farm…",
    ["Готово"] = "Done",
    ["Загружен. RightShift: скрыть/показать"] = "Loaded. RightShift: hide/show",
    ["Монеты"] = "Coins",
    ["Найдено автоматически: "] = "Auto-detected: ",
    ["удалена"] = "removed",
    ["прозрачность"] = "transparency",
    ["сдвинута"] = "moved",
    [" (дубль)"] = " (duplicate)",
    [" (не наша)"] = " (not ours)",
    ["Монеты кончились: жду"] = "Coins ran out: waiting",
    ["Унесло с карты: жду следующий раунд"] = "Left the map: waiting for the next round",
    ["40 монет: ресет"] = "40 coins: resetting",
    ["%s   |   монета: %.0f, %.0f, %.0f   |   до неё: %.0f"] = "%s   |   coin: %.0f, %.0f, %.0f   |   distance: %.0f",
    ["Телепорт к монете"] = "Teleporting to the coin",
    ["За картой"] = "Behind the map",
    ["Голова вверх"] = "Head up",
    ["Лёжа под картой"] = "Lying under the map",
    ["Старт раунда: ждём %.0f с (лёжа под полом)"] = "Round start: waiting %.0f s (lying under the floor)",
    ["Раунд идёт, свободных монет нет"] = "Round in progress, no free coins",
    ["Не в раунде (умер / в лобби): ждём следующий"] = "Not in a round (dead / in lobby): waiting for the next one",
    ["Монеты есть, но ты не на карте (лобби): не фармим"] = "Coins exist but you are not on the map (lobby): not farming",
    ["Лобби: ждём выдачу ролей"] = "Lobby: waiting for the role handout",
    ["Лобби: ждём появление монет"] = "Lobby: waiting for coins to appear",
    ["Монет найдено: %d   ·   Собрано: %d/%d   ·   Признак раунда: %s   ·   Ты на карте: %s   ·   Зачёт: %s"] = "Coins found: %d   ·   Collected: %d/%d   ·   Round signal: %s   ·   You are on the map: %s   ·   Counted by: %s",
    ["да"] = "yes",
    ["нет"] = "no",
    ["Собираю монеты"] = "Collecting coins",
    ["Старт раунда…"] = "Round starting…",
    ["Монет нет"] = "No coins",
    ["Ждём новый раунд"] = "Waiting for a new round",
    ["Не на карте"] = "Not on the map",
    ["Ждём раунд"] = "Waiting for a round",
    ["Мёртв / нет персонажа: фарм отключён"] = "Dead / no character: farm disabled",
    ["Мёртв / нет персонажа"] = "Dead / no character",
    ["Авто-подбор"] = "Auto pickup",
    ["Пистолет: попытка "] = "Gun: attempt ",
    ["Ты мёртв"] = "You are dead",
    ["Ты не убийца"] = "You are not the murderer",
    [": недоступен"] = ": unavailable",
    ["Нож не найден"] = "Knife not found",
    [": убит"] = ": killed",
    [": не засчитано"] = ": not registered",
    ["Загружен (интро пропущено из-за ошибки)"] = "Loaded (intro skipped because of an error)",
    ["Панель голосования"] = "Voting panel",
    ["Автопоказ панели"] = "Auto-show panel",
    ["Сама появляется, когда в лобби идёт голосование за карту"] = "Pops up by itself when a map vote is running in the lobby",
    ["Окно голосования, с"] = "Voting window, s",
    ["Макс. удержание на Pad, мс"] = "Max hold on Pad, ms",
    ["Показать панель сейчас"] = "Show panel now",
    ["Остановить голосование"] = "Stop voting",
    ["Остановить"] = "Stop",
    ["Голосование за карту"] = "Map vote",
    ["Голосов:"] = "Votes to cast:",
    ["Голоса"] = "Votes",
    [" с"] = " s",
    ["Pad не найден"] = "Pad not found",
    ["Поиск Lobby / VotePads…"] = "Looking for Lobby / VotePads…",
    ["Голосую: %d/%d  ·  Votes вырос раз: %d"] = "Voting: %d/%d  ·  Votes counter rose: %d time(s)",
    ["Lobby/VotePads не найдены в workspace"] = "Lobby/VotePads not found in workspace",
    ["Нажми на карту: голосование начнётся сразу"] = "Tap a map: voting starts right away",
    ["Лобби: %s  ·  Голосование: %s  ·  Карт: %d"] = "Lobby: %s  ·  Voting: %s  ·  Maps: %d",
    ["Уже идёт"] = "Already running",
    ["Занято другой функцией"] = "Busy with another feature",
    ["Персонаж не появился"] = "Character did not respawn",
    ["VotePads не найдены"] = "VotePads not found",
    ["Pad не найден в VotePad"] = "Pad part not found in the VotePad",
    ["Ресет не сработал"] = "Reset did not work",
    ["Остановлено"] = "Stopped",
    ["Время голосования вышло"] = "Voting time is over",
    ["Голосую за %s, раз: %d"] = "Voting for %s, times: %d",
    ["Итог: циклов %d/%d, Votes вырос раз: %d"] = "Result: cycles %d/%d, Votes rose %d time(s)",
}
I18N.reg = setmetatable({}, { __mode = "k" }) -- TextObject -> { ru = ключ, last = последний выставленный текст }
I18N.hooks = {}
local function L(ru)
    if I18N.lang == "ru" then return ru end
    return I18N.EN[ru] or ru
end
local function OnLang(fn) I18N.hooks[#I18N.hooks + 1] = fn end
local function ApplyLang()
    for o, e in pairs(I18N.reg) do
        -- если логика уже подменила текст (динамический статус), его не трогаем: он переводится при выставлении
        if o.Parent and o.Text == e.last then
            e.last = L(e.ru)
            o.Text = e.last
        end
    end
    for _, fn in ipairs(I18N.hooks) do pcall(fn) end
end

-- Состояние голосования за карту (логика и вкладка — в блоке «ГОЛОСОВАНИЕ» ниже)
local Vote = { Running = false, Sel = nil, Count = 3, Done = 0, Total = 0, Seen = 0, Auto = true, Window = 12 }

-- ═══════════════ УТИЛИТЫ ═══════════════
local Connections = {}
local Alive = true

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

local function New(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then o[k] = v end
    end
    local t = props.Text
    if type(t) == "string" and I18N.EN[t] then
        o.Text = L(t)
        I18N.reg[o] = { ru = t, last = o.Text }
    end
    if props.Parent then o.Parent = props.Parent end
    return o
end

local function Corner(p, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p })
end

local function Stroke(p, color, t)
    return New("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = t or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = p,
    })
end

local function Tween(o, t, props, style)
    TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function IsPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

-- ═══════════════ ЛОГО ═══════════════
-- JPG 160x160 (логотип MM2) вшит в base64. Нужен эксплоит с writefile + getcustomasset (getsynasset); иначе остаётся буква «P».
local LOGO_B64 = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAQDAwMDAgQDAwMEBAQFBgoGBgUFBgwICQcKDgwPDg4MDQ0PERYTDxAVEQ0NExoTFRcYGRkZDxIbHRsYHRYYGRj/2wBDAQQEBAYFBgsGBgsYEA0QGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBj/wAARCACgAKADASIAAhEBAxEB/8QAHQABAAEFAQEBAAAAAAAAAAAAAAcBAgQFBggDCf/EAD0QAAEDBAAEBAMGAwUJAAAAAAEAAgMEBQYRBxIhMRNBUWEiMnEUI4GRscEIY6EWM1LC8EJTYnKi0dLh8f/EABwBAQABBQEBAAAAAAAAAAAAAAADAQQFBgcCCP/EADMRAAICAQIFAQUFCQAAAAAAAAABAgMEBREGEiExQXETFCJRoRUjMtHhJDNCQ2GBscHw/9oADAMBAAIRAxEAPwD8/wBERAEREAREQBERAEX2pImVFwgge4tbJI1hI8gTpSAMQx6NmnCpefUy6/QICOUXaXGyY9R00kxjmDWDf9739lxjtcx5RoeSAoiIgCIiAIiIAiIgCIiAIiIAiIgCIqhpPZAVYS2RrgdEHYUhiqlfGD5kArhbfQVVfWspqWF0kjjoADamWkwSY2nmqKkRVZ6tYBzNaPQ+/wBOyzGmaFm6nu8aG6Xnx6F3jYVuRu612I5yLmNrB2dCQE/kVyp6HSkDLLVV2+0Sw1MBa9rmkHWw7r5HzXAkHmWOyMa7Gm67ouMl8yC2qVcnGS2ZaiaRQEYREQBERAEREAREQBERAERXgeSqkC0Ld4/jVxyCvbT0kR5e7pCOjQtviGCV2QTNqKhroKJp6yOHzewU2W200VnoG0dDC2OMdyB1cfUreeGuD7dQ2vyd41/V/oZnT9Jnf8dnSP8Ak1mM4nbsbog2naJKlw+OcjqfYegW+/BV0Vg3O60dqpRLVP8Aid8kbfmcf9ea7DXXj6fRyx2hCK/7c2yMa8eG0eiRkVdPS1VM6Ctjjkhd8JbJ2P8A7UZ5NwvY/nq7A8h3c07/APKsDMMkr6ujZUsndFyStLI4z0b3/M+67vCckGRY82SVw+1Q6ZKPX0K077Q0niO+eHOPVdpeX6GJd+LqFjpkvR/kQJXUNVQVJp6qJ8UjT1a4aWKvSl6xy136nMdfThz9abK3o5v4qIsm4d3Wyl9RStNVSDr4jR1b9QtI13gzK0/e2n46/wCndeqMPmaRbQ3KHWJxCK9zS06I0fRWLTWtjEBERUAREQBERAEREAX2heGTseQCGuB0fqviq7VYycXugnselMXutvvGPQS29zGhjA18TehYdei3RYf/AKvNmN5JcMcubKukkIb2ew9nBd/fuLEc1nbFZoXQ1D2/eSPO+T/l/wC67HpPG+K8TfJfLOPj5+ht+JrFTp+96NfUksGprq11utAhkqh0dJM/kih9OZ3r7DqrTwLy69SGsqcpx0yP7mSpOx7Aa7KBLVmN8juNPTz188tI6Yc9OT8J2ep1rv12pMfGCCCwfXS5xxJxHn6xZyws5K12X5mIy9U946NdDNyHgLkoonwNvNqqXtPMBTlz+34LDxTh1luEVQuF3jibQ1LxTfAXfOQSN7H/AArMw2ugtENVX7Pj/INHs0DZA+v7LQYnnea5pl8NDeb/AF9TbKeR9THQukPgxHqBpvsDobVjwz73VqdDUk/iW/TboRYFkPeIOMeu5JXKddwVZKzcDw4AgtPQ/RfblPmAse4SCltNTUHQEcTnb/BfRl18VCTfyZu0ukXueY7kNXapA7eIf1WGsiqk8atll6/E8nr9Vjr5qyJc1kmvmznE2nJtBERQnkIiIAiIgCIiAIiICoPRVJB81airuDpcIpKesy6ETsEgjY6VoPbmGtFSvyH0UYcOxzZm0fyJP0ClnwxvzVAYeHWWnveYx2irqJoYZmyEuh0Hba3Y7rpLXw/ocOy27fYnSvgkLBC6TXNotDndh25tgLVYK4wcTKEnQ3JI382uUoXiMS3Mv33YOy2LheyNecpy8J7Gb0KMZZPXwmaHwvquJ4n3dlpwmSna/U9UfDA8+Xuf2UgVJp6SkfU1EojijaXPefIDuvNHEDKn5Pk0ksbiKSH7uFm/Iea3TXdfVWLKMH1l0RsGsZSx6Gv4n0OUJHqrERcqZogREVAEREAREQBERAEREARFc0bCA63hsN5u0fyJP0CmHkUY8MbLcJL6+8NpniihjdG+YjQ5ndAApX8ND1KDjtuu5qsdIg4gUb9dBUH+oI/dSjcKykpaZ9bWzxwwsb8Uj3aGh+6i2kPhZjA8/wCzUt/VaLjjV1LHWdkVRI2CRkocxruhILdE/mVNjXuiznRe6fm+6W+1236Gq4j8Sn3+V9os7nRW5rvid2MxHmfZRgexQuJHVU2V6yMid8uabIcrKsybHZYyiIity2CIiAIiIAiIgCIiAIiaKAqG7XecOOHNfml524Oht0RBmnI/6R7rV4Lh1fmeUwWykaRFvmmm10jZ5kr01e7vj3CjBIaSkpw6QN5aenb88z/Nx9lj8zM9k1VDrJmxaLpUbv2nI6Vx+v6GVdbVabDhUNotsUVPGHt8OPY5n67n3+q5LlXDYzPnGW8RRf7rQXCWmMb2tAiPKzY6ABShFjN/mA5baIh/Pma3+g2VWq+FMdrprcrqGPfqN/Pj1PlSSXjscXN93kYcBrUrT+i0XGZni2K2T9CY6h7Cfq3f+VSXLw6vdRWmodU0EXUHl5nO7e4Cwsu4W33JbC23/a7fG9kwma8PcR0BGtEe6faWNv8AjRbPh7P235Dy5roqKUrnwIzmga58FNBWtH+4kBJ/BcBdLBebLO6G522opnA6+8YQPzVzXkVW/gkmWORp+Rj/AL2DRrEVS0juFRTFmEREAREQBERAEREAX2p4Xz1DIY2kveQ1oHmV8V3fCK2U104s2yKrDfBicZncx0PhG+qivtVVcrH4RcYtDvujUvLPSHC7CIcOwqGN7Aa+qaJKh+uo31Df9fsujfjNnnvDrrWUUdXVn5ZKgc/hjyDR2AWDdc9w+yMd9vv1Ixw7xsdzu/ILirj/ABBYXSEijirax3kWtDR/Vc9UM3JslbGL3f8AY6n7fDw640ymkkSw2NrYwxgDWjs0DQCpy6GlCVD/ABBsu9+prZbrB4bqiURtkmkJA35kBdbJnV6jiMhp7doddcr/APyUy0fNfeP1IHr+Cv5hIPL9FQjqtPg0+W5zaqy40FotzKelmEHNLUPj8V2tkN+Ejp03s+YWNd82s+M5b/ZnKJWWq5+G2Xw3Stlbyu+U8ze2/QgFQW6dl19ZQZcU6vh3PaFiOg0FosuqcdoMXqa7JoKeajjb1ZK0HmPoN+ZWznu9sgs8l2kroTRRt53TteHN0Pf19l5N4pcR6vNb46GBzorXA4iGLfzdfmPuVNpOFbk3b9VFd3/oh1jUqsOjd9ZPsjjr7V0Vffqipt1E2jpnOPJC0k6C1aIugpbLY5XObnJyfkIiKp5CIiAIiIAiIgC+1PWVVI9z6ad8LnN5SWHRI9F8URrcqm090XvllkdzPe5x9XHat5j6qiIG2+5v8Lfy8QLS9x0BUNJXpPFsTvHEDI4rNZWcrOhqKtw3HTs/xOPr303uVA/B7Hoco41WOzVM00VPLI98skWuYNZG5x1v11rfuvd9bl2CcFeG5rKhjKKhj2IaSHTp6ybXyjfVzz5uPQDqeio2NtzYZtkGHcAOCDJuRrmU7DBQUbiBJXVB6nZ9z8T3eQ/AL83MkyO7ZVllfkN6qjPX10zpppOw2fIDyaBoAeQAXR8VOKWR8WM4lyG/SCONu46OhicTFSRb2GN33J7ucerj+AHDIl5G5smX+8Ms0tpbcJ/scpBfCXbadLXbPVURFFR7I9TslPbme+wREVTwEREAREQBERAEREAREQBERAdtwvzSiwHNnZLVUklZLBSSspoGnlDpXgNHM7yb3JPUrXZnm+QZ5kj7zkNcZpNcsUTfhigZ/gjb5D+p7na5pEAREQBERAEREAREQBERAf/Z"

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function B64Decode(s)
    local map = {}
    for i = 1, 64 do map[B64_CHARS:byte(i)] = i - 1 end
    local out, buf, bits = {}, 0, 0
    for i = 1, #s do
        local v = map[s:byte(i)]
        if v then
            buf = buf * 64 + v
            bits += 6
            if bits >= 8 then
                bits -= 8
                local div = 2 ^ bits
                local byte = math.floor(buf / div)
                buf = buf - byte * div
                out[#out + 1] = string.char(byte)
            end
        end
    end
    return table.concat(out)
end

local function LoadLogo()
    local ok, asset = pcall(function()
        local write = writefile
        local get = getcustomasset or getsynasset
        if not (write and get) then error("no file api") end
        local name = "mm2prohub_logo_v2.jpg"
        write(name, B64Decode(LOGO_B64))
        return get(name)
    end)
    if ok and asset and asset ~= "" then return asset end
    return nil
end
local LogoAsset = LoadLogo() -- грузим один раз: нужен и окну, и интро

-- ═══════════════ ОПРЕДЕЛЕНИЕ РОЛЕЙ (ESP) ═══════════════
-- Запасной источник ролей: RemoteFunction «GetPlayerData» (если она есть в игре), опрашивается не чаще раза в 2 с.
-- ВАЖНО: формат ответа взят из публичного примера и в твоей версии игры НЕ проверен; всё под pcall, при несовпадении
-- формата просто остаётся прежний способ (нож/пистолет в руках или в рюкзаке).
local ServerRoles, ServerNext, ServerBusy = {}, 0, false
local function RefreshServerRoles()
    if ServerBusy or os.clock() < ServerNext then return end
    ServerNext = os.clock() + 2
    ServerBusy = true
    task.spawn(function()
        pcall(function()
            local rf = game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true)
            if not (rf and rf:IsA("RemoteFunction")) then return end
            local data = rf:InvokeServer()
            if type(data) ~= "table" then return end
            local out = {}
            for name, info in pairs(data) do
                if type(name) == "string" and type(info) == "table" and type(info.Role) == "string" then
                    local r = info.Role:lower()
                    if r == "murderer" then out[name] = "Murderer"
                    elseif r == "sheriff" or r == "hero" then out[name] = "Sheriff" end
                end
            end
            ServerRoles = out
        end)
        ServerBusy = false
    end)
end

local function GetRole(p)
    RefreshServerRoles()
    if not p or not p.Character then return "Innocent" end
    local function scan(c)
        if not c then return nil end
        for _, t in pairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") or n:find("dagger") or n:find("murder") then return "Murderer" end
                if n:find("gun") or n:find("pistol") or n:find("sheriff") then return "Sheriff" end
            end
        end
        return nil
    end
    -- Backpack чужих игроков может не реплицироваться: тогда видна только роль по оружию в руках
    return scan(p.Character) or scan(p:FindFirstChildOfClass("Backpack")) or ServerRoles[p.Name] or "Innocent"
end

-- Роль запоминается, пока персонаж жив: убийца убрал нож — всё равно Murderer.
-- Память сбрасывается при смерти/респауне игрока и когда на карте ~5 с нет монет (конец раунда / лобби).
local ESPNext = 0
local RoleMemo = setmetatable({}, { __mode = "k" })
local function RoleOf(p)
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local m = RoleMemo[p]
    if m and (m.char ~= char or not hum or hum.Health <= 0) then m, RoleMemo[p] = nil, nil end
    local r = GetRole(p)
    if r ~= "Innocent" then RoleMemo[p] = { char = char, role = r }; return r end
    return m and m.role or "Innocent"
end

local function ClearESP(p) -- убрать подсветку и ник (и старую подпись из прошлых версий)
    local char = p.Character
    if not char then return end
    local h = char:FindFirstChild("ProESP")
    if h then h:Destroy() end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local b = hrp:FindFirstChild("ProESP")
        if b then b:Destroy() end
        local n = hrp:FindFirstChild("ProESPName")
        if n then n:Destroy() end
    end
end

-- ═══════════════ ROOT GUI ═══════════════
local old = CoreGui:FindFirstChild("MM2ProHub")
if old then old:Destroy() end

local SG = New("ScreenGui", {
    Name = "MM2ProHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
if not pcall(function() SG.Parent = CoreGui end) then
    SG.Parent = LP:WaitForChild("PlayerGui")
end

-- ═══════════════ УВЕДОМЛЕНИЯ (плоские карточки справа) ═══════════════
local ToastHolder = New("Frame", {
    Size = UDim2.new(0, 280, 1, -24), Position = UDim2.new(1, -292, 0, 12),
    BackgroundTransparency = 1, ZIndex = 50, Parent = SG,
})
New("UIListLayout", {
    Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder, Parent = ToastHolder,
})
local ToastN = 0

local function Notify(title, text)
    title, text = L(title), L(text)
    ToastN += 1
    local slot = New("Frame", {
        Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = ToastN, ZIndex = 50, Parent = ToastHolder,
    })
    local t = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1, 40, 0, 0), BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 50, Parent = slot,
    })
    Corner(t, 10)
    Stroke(t, Theme.StrokeHi, 1)
    New("Frame", {
        Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0, ZIndex = 51, Parent = t,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -36, 0, 18), Position = UDim2.new(0, 22, 0, 9), BackgroundTransparency = 1,
        Text = title, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 51, Parent = t,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -36, 0, 16), Position = UDim2.new(0, 22, 0, 28), BackgroundTransparency = 1,
        Text = text, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 51, Parent = t,
    })
    local prog = New("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.StrokeHi,
        BorderSizePixel = 0, ZIndex = 51, Parent = t,
    })
    Tween(t, 0.35, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
    Tween(prog, 2.5, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(2.5, function()
        if not t.Parent then return end
        Tween(t, 0.3, { Position = UDim2.new(1, 40, 0, 0) })
        task.wait(0.32)
        slot:Destroy()
    end)
end

-- ═══════════════ HUD АВТОФАРМА (виден, пока Auto-Farm включён, даже если окно скрыто) ═══════════════
local H = {}
local HUD = New("Frame", {
    Name = "HUD", Size = UDim2.new(0, 290, 0, 48), AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 12), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
    Visible = false, ZIndex = 5, Parent = SG,
})
Corner(HUD, 10)
Stroke(HUD, Theme.StrokeHi, 1)
H.Dot = New("Frame", {
    Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 14, 0, 13), BackgroundColor3 = Theme.AccentHi,
    BorderSizePixel = 0, ZIndex = 6, Parent = HUD,
})
Corner(H.Dot, 4)
H.Title = New("TextLabel", {
    Size = UDim2.new(1, -100, 0, 16), Position = UDim2.new(0, 30, 0, 9), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = HUD,
})
H.Count = New("TextLabel", {
    Size = UDim2.new(0, 56, 0, 16), Position = UDim2.new(1, -70, 0, 9), BackgroundTransparency = 1, Text = "0/40",
    TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 6, Parent = HUD,
})
H.Track = New("Frame", {
    Size = UDim2.new(1, -28, 0, 4), Position = UDim2.new(0, 14, 1, -14), BackgroundColor3 = Theme.Stroke,
    BorderSizePixel = 0, ZIndex = 6, Parent = HUD,
})
Corner(H.Track, 2)
H.Fill = New("Frame", {
    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 7, Parent = H.Track,
})
Corner(H.Fill, 2)

-- ═══════════════ ГЛАВНОЕ ОКНО ═══════════════
local WIN_W, WIN_H, SIDE_W = 760, 470, 176

local function FitScale()
    local vp = SG.AbsoluteSize
    if vp.X < 1 or vp.Y < 1 then return 1 end
    return math.clamp(math.min(vp.X / (WIN_W + 60), vp.Y / (WIN_H + 60)) * 0.82, 0.4, 1) -- 0.82: окно меньше (ползунок «Масштаб окна» работает поверх)
end
local BaseScale = FitScale()

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false, -- покажет интро
    Parent = SG,
})
Corner(Main, 12)
Stroke(Main, Theme.StrokeHi, 1)
local MainScale = New("UIScale", { Scale = BaseScale * 0.94, Parent = Main })

-- ═══════════════ БОКОВАЯ ПАНЕЛЬ ═══════════════
local Sidebar = New("Frame", {
    Size = UDim2.new(0, SIDE_W, 1, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = Main,
})
New("Frame", {
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.Stroke,
    BorderSizePixel = 0, Parent = Sidebar,
})

do -- логотип
    local icon = New("Frame", {
        Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = Sidebar,
    })
    Corner(icon, 10)
    Stroke(icon, Theme.StrokeHi, 1)
    local glyph = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "P",
        TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 18, Parent = icon,
    })
    if LogoAsset then -- вместо буквы «P» — картинка (нож MM2)
        glyph.Visible = false
        icon.BackgroundColor3 = Color3.new(0, 0, 0)
        local img = New("ImageLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = LogoAsset,
            ScaleType = Enum.ScaleType.Fit, Parent = icon,
        })
        Corner(img, 10)
    end
    New("TextLabel", {
        Size = UDim2.new(1, -66, 0, 18), Position = UDim2.new(0, 62, 0, 15), BackgroundTransparency = 1,
        Text = "PRO HUB", TextColor3 = Theme.Text, Font = Enum.Font.GothamBlack, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -66, 0, 14), Position = UDim2.new(0, 62, 0, 33), BackgroundTransparency = 1,
        Text = "MM2  ·  v4.0", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar,
    })
end

local TAB_H, TAB_STEP = 38, 42
local TabList = New("Frame", {
    Size = UDim2.new(1, 0, 1, -170), Position = UDim2.new(0, 0, 0, 72), BackgroundTransparency = 1, Parent = Sidebar,
})
local TabHL = New("Frame", { -- подсветка активной вкладки
    Size = UDim2.new(1, -20, 0, TAB_H), Position = UDim2.new(0, 10, 0, 0),
    BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = TabList,
})
Corner(TabHL, 8)
do
    local bar = New("Frame", {
        Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = TabHL,
    })
    Corner(bar, 2)
end

-- статус фарма и FPS внизу панели
local ChipText, ChipDot, FpsLabel
do
    local Chip = New("Frame", {
        Size = UDim2.new(1, -20, 0, 32), Position = UDim2.new(0, 10, 1, -80),
        BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = Sidebar,
    })
    Corner(Chip, 8)
    ChipDot = New("Frame", {
        Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 12, 0.5, -4),
        BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0, Parent = Chip,
    })
    Corner(ChipDot, 4)
    ChipText = New("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 28, 0, 0), BackgroundTransparency = 1,
        Text = "Фарм выкл", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = Chip,
    })
    FpsLabel = New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 14, 1, -40), BackgroundTransparency = 1,
        Text = "", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar,
    })
end

-- ═══════════════ ПРАВАЯ ЧАСТЬ: шапка + страницы ═══════════════
local Body = New("Frame", {
    Size = UDim2.new(1, -SIDE_W, 1, 0), Position = UDim2.new(0, SIDE_W, 0, 0), BackgroundTransparency = 1, Parent = Main,
})
local Header = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = Body })
local HeaderTitle = New("TextLabel", {
    Size = UDim2.new(1, -140, 0, 22), Position = UDim2.new(0, 24, 0, 11), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header,
})
local HeaderSub = New("TextLabel", {
    Size = UDim2.new(1, -140, 0, 14), Position = UDim2.new(0, 24, 0, 33), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header,
})
New("Frame", {
    Size = UDim2.new(1, -48, 0, 1), Position = UDim2.new(0, 24, 1, 0), BackgroundColor3 = Theme.Stroke,
    BorderSizePixel = 0, Parent = Header,
})

local function WindowButton(text, xOffset, hoverColor)
    local b = New("TextButton", {
        Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, xOffset, 0, 16),
        BackgroundColor3 = Theme.Card, BorderSizePixel = 0, AutoButtonColor = false,
        Text = text, TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 14, Parent = Header,
    })
    Corner(b, 8)
    Connect(b.MouseEnter, function() Tween(b, 0.15, { BackgroundColor3 = hoverColor, TextColor3 = Theme.Text }) end)
    Connect(b.MouseLeave, function() Tween(b, 0.15, { BackgroundColor3 = Theme.Card, TextColor3 = Theme.TextDim }) end)
    return b
end
local MinBtn   = WindowButton("–", -72, Theme.CardHov)
local CloseBtn = WindowButton("×", -38, Theme.Danger)

-- Перетаскивание окна (за шапку)
do
    local dragging, dragStart, startPos = false, nil, nil
    Connect(Header.InputBegan, function(i)
        if IsPress(i) then dragging, dragStart, startPos = true, i.Position, Main.Position end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = (i.Position - dragStart) / MainScale.Scale
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if IsPress(i) then dragging = false end
    end)
end

local PagesHolder = New("Frame", {
    Size = UDim2.new(1, 0, 1, -61), Position = UDim2.new(0, 0, 0, 61),
    BackgroundTransparency = 1, ClipsDescendants = true, Parent = Body,
})

local Tabs, CurrentTab, TabCount = {}, nil, 0

local function SelectTab(name)
    for n, t in pairs(Tabs) do
        local on = (n == name)
        local was = t.Page.Visible
        t.Page.Visible = on
        if on and not was then -- плавный выезд страницы
            t.Page.Position = UDim2.new(0, 0, 0, 12)
            Tween(t.Page, 0.22, { Position = UDim2.new(0, 0, 0, 0) })
        end
        Tween(t.Label, 0.15, { TextColor3 = on and Theme.Text or Theme.TextDim })
        if on then
            Tween(TabHL, 0.25, { Position = UDim2.new(0, 10, 0, (t.Index - 1) * TAB_STEP) }, Enum.EasingStyle.Quint)
            HeaderTitle.Text = L(n)
            HeaderSub.Text = L(t.Sub)
        end
    end
    CurrentTab = name
end

local function AddTab(name, glyph, order, sub)
    TabCount += 1
    local idx = TabCount
    local btn = New("TextButton", {
        Size = UDim2.new(1, -20, 0, TAB_H), Position = UDim2.new(0, 10, 0, (idx - 1) * TAB_STEP),
        BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 2, Parent = TabList,
    })
    local lbl = New("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1,
        Text = glyph .. "   " .. L(name), TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = btn,
    })
    local dot = New("Frame", { -- индикатор «функция работает»
        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(1, -16, 0.5, -3),
        BackgroundColor3 = Theme.Good, BorderSizePixel = 0, Visible = false, ZIndex = 4, Parent = btn,
    })
    Corner(dot, 3)

    local page = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.StrokeHi,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        Visible = false, Parent = PagesHolder,
    })
    New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24), Parent = page,
    })

    Tabs[name] = { Btn = btn, Label = lbl, Page = page, Sub = sub or "", Dot = dot, Index = idx }
    OnLang(function()
        lbl.Text = glyph .. "   " .. L(name)
        if CurrentTab == name then HeaderTitle.Text = L(name); HeaderSub.Text = L(sub or "") end
    end)
    Connect(btn.MouseEnter, function()
        if CurrentTab ~= name then Tween(lbl, 0.15, { TextColor3 = Theme.Text }) end
    end)
    Connect(btn.MouseLeave, function()
        if CurrentTab ~= name then Tween(lbl, 0.15, { TextColor3 = Theme.TextDim }) end
    end)
    Connect(btn.MouseButton1Click, function() SelectTab(name) end)
    return page
end

-- ═══════════════ КОМПОНЕНТЫ ═══════════════
local function Card(page, height)
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = page,
    })
    Corner(f, 10)
    local st = Stroke(f, Theme.Stroke)
    return f, st
end

local function Hover(hit, card, st)
    Connect(hit.MouseEnter, function()
        Tween(card, 0.15, { BackgroundColor3 = Theme.CardHov })
        Tween(st, 0.15, { Color = Theme.StrokeHi })
    end)
    Connect(hit.MouseLeave, function()
        Tween(card, 0.15, { BackgroundColor3 = Theme.Card })
        Tween(st, 0.15, { Color = Theme.Stroke })
    end)
end

local function AddSection(page, text)
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = page })
    local lbl = New("TextLabel", {
        Size = UDim2.new(0, 220, 1, 0), BackgroundTransparency = 1, Text = L(text):upper(), TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })
    local line = New("Frame", {
        Size = UDim2.new(1, -60, 0, 1), Position = UDim2.new(0, 60, 0.5, 0),
        BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = f,
    })
    local function layout()
        local w = lbl.TextBounds.X + 12
        line.Position = UDim2.new(0, w, 0.5, 0)
        line.Size = UDim2.new(1, -w, 0, 1)
    end
    layout()
    Connect(lbl:GetPropertyChangedSignal("TextBounds"), layout)
    OnLang(function() lbl.Text = L(text):upper() end)
end

local function AddBanner(page)
    local card = Card(page, 76)
    local av = New("ImageLabel", {
        Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 16, 0.5, -24), BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150", Parent = card,
    })
    Corner(av, 24)
    local online = New("Frame", {
        Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 53, 0.5, 10), BackgroundColor3 = Theme.Good,
        BorderSizePixel = 0, Parent = card,
    })
    Corner(online, 6)
    Stroke(online, Theme.Card, 2)
    local greet = New("TextLabel", {
        Size = UDim2.new(1, -200, 0, 22), Position = UDim2.new(0, 78, 0, 16), BackgroundTransparency = 1,
        Text = L("Привет, ") .. LP.DisplayName, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })
    local bsub = New("TextLabel", {
        Size = UDim2.new(1, -200, 0, 16), Position = UDim2.new(0, 78, 0, 40), BackgroundTransparency = 1,
        Text = "@" .. LP.Name .. L("  ·  RightShift — скрыть / показать окно"), TextColor3 = Theme.TextDim,
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })
    OnLang(function()
        greet.Text = L("Привет, ") .. LP.DisplayName
        bsub.Text = "@" .. LP.Name .. L("  ·  RightShift — скрыть / показать окно")
    end)
    local badge = New("Frame", {
        Size = UDim2.new(0, 56, 0, 24), Position = UDim2.new(1, -72, 0.5, -12), BackgroundColor3 = Theme.CardHov,
        BorderSizePixel = 0, Parent = card,
    })
    Corner(badge, 12)
    New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "v4.0", TextColor3 = Theme.AccentHi,
        Font = Enum.Font.GothamBold, TextSize = 11, Parent = badge,
    })
end

local function AddToggle(page, title, desc, default, callback)
    local card, st = Card(page, 60)
    New("TextLabel", {
        Size = UDim2.new(1, -110, 0, 18), Position = UDim2.new(0, 18, 0, 11),
        BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -110, 0, 14), Position = UDim2.new(0, 18, 0, 31),
        BackgroundTransparency = 1, Text = desc, TextColor3 = Theme.TextDim,
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })
    local track = New("Frame", {
        Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -58, 0.5, -11),
        BackgroundColor3 = Theme.StrokeHi, BorderSizePixel = 0, Parent = card,
    })
    Corner(track, 11)
    local knob = New("Frame", {
        Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = track,
    })
    Corner(knob, 8)
    local hit = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = card })

    local state = default
    local function render()
        Tween(track, 0.18, { BackgroundColor3 = state and Theme.Accent or Theme.StrokeHi })
        Tween(knob, 0.2, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, Enum.EasingStyle.Quint)
    end
    render()

    Hover(hit, card, st)
    Connect(hit.MouseButton1Click, function()
        state = not state
        render()
        if callback then callback(state) end
        Notify(title, state and "Включено" or "Выключено")
    end)
end

local function AddSlider(page, title, min, max, default, callback)
    local card = Card(page, 64)
    New("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18), Position = UDim2.new(0, 18, 0, 10),
        BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    local valLbl = New("TextLabel", {
        Size = UDim2.new(0, 60, 0, 18), Position = UDim2.new(1, -78, 0, 10), BackgroundTransparency = 1,
        Text = tostring(default), TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
    })
    local hit = New("Frame", { -- широкая зона нажатия (удобно на телефоне)
        Size = UDim2.new(1, -36, 0, 26), Position = UDim2.new(0, 18, 0, 34), BackgroundTransparency = 1, Parent = card,
    })
    local track = New("Frame", {
        Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2),
        BackgroundColor3 = Theme.StrokeHi, BorderSizePixel = 0, Parent = hit,
    })
    Corner(track, 2)
    local fill = New("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track,
    })
    Corner(fill, 2)
    local knob = New("Frame", {
        Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = fill,
    })
    Corner(knob, 7)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = tostring(v)
        if callback then callback(v) end
    end
    Connect(hit.InputBegan, function(i)
        if IsPress(i) then
            dragging = true
            Tween(knob, 0.1, { Size = UDim2.new(0, 18, 0, 18) })
            update(i.Position.X)
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then update(i.Position.X) end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if IsPress(i) and dragging then
            dragging = false
            Tween(knob, 0.1, { Size = UDim2.new(0, 14, 0, 14) })
        end
    end)
end

local function AddButton(page, text, color, callback)
    local primary = color ~= nil and color ~= Theme.Card
    local base = primary and color or Theme.Card
    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = base,
        BorderSizePixel = 0, AutoButtonColor = false, Text = text, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold, TextSize = 12, Parent = page,
    })
    Corner(b, 10)
    local st = (not primary) and Stroke(b) or nil
    Connect(b.MouseEnter, function()
        if primary then
            Tween(b, 0.15, { BackgroundTransparency = 0.15 })
        else
            Tween(b, 0.15, { BackgroundColor3 = Theme.CardHov })
            Tween(st, 0.15, { Color = Theme.StrokeHi })
        end
    end)
    Connect(b.MouseLeave, function()
        if primary then
            Tween(b, 0.15, { BackgroundTransparency = 0 })
        else
            Tween(b, 0.15, { BackgroundColor3 = Theme.Card })
            Tween(st, 0.15, { Color = Theme.Stroke })
        end
    end)
    Connect(b.MouseButton1Click, callback)
end

local function AddSegmented(page, title, options, default, callback)
    local card = Card(page, 82)
    New("TextLabel", {
        Size = UDim2.new(1, -32, 0, 18), Position = UDim2.new(0, 18, 0, 10),
        BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    local bar = New("Frame", {
        Size = UDim2.new(1, -36, 0, 34), Position = UDim2.new(0, 18, 0, 36),
        BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = card,
    })
    Corner(bar, 8)
    local n = #options
    local hl = New("Frame", {
        Size = UDim2.new(1 / n, -6, 1, -6), Position = UDim2.new(0, 3, 0, 3),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar,
    })
    Corner(hl, 6)

    local labels = {}
    local function select(i, silent)
        Tween(hl, 0.22, { Position = UDim2.new((i - 1) / n, 3, 0, 3) }, Enum.EasingStyle.Quint)
        for k, l in ipairs(labels) do
            Tween(l, 0.18, { TextColor3 = (k == i) and Color3.new(1, 1, 1) or Theme.TextDim })
        end
        if not silent then
            callback(i, options[i])
            Notify(title, options[i])
        end
    end
    for i, text in ipairs(options) do
        local b = New("TextButton", {
            Size = UDim2.new(1 / n, 0, 1, 0), Position = UDim2.new((i - 1) / n, 0, 0, 0),
            BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextDim,
            Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false, ZIndex = 2, Parent = bar,
        })
        labels[i] = b
        Connect(b.MouseButton1Click, function() select(i) end)
    end
    select(default, true)
end

local function AddInfo(page, text, height)
    local card = Card(page, height or 46)
    local dot = New("Frame", {
        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 18, 0.5, -3),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = card,
    })
    Corner(dot, 3)
    return New("TextLabel", {
        Size = UDim2.new(1, -48, 1, 0), Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextDim,
        Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
end

-- Карточка с полосой прогресса. Возвращает функцию set(доля 0..1, текст)
local function AddProgress(page, title)
    local card = Card(page, 62)
    New("TextLabel", {
        Size = UDim2.new(1, -120, 0, 18), Position = UDim2.new(0, 18, 0, 10), BackgroundTransparency = 1,
        Text = title, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    local val = New("TextLabel", {
        Size = UDim2.new(0, 90, 0, 18), Position = UDim2.new(1, -108, 0, 10), BackgroundTransparency = 1,
        Text = "0 / 40", TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
    })
    local track = New("Frame", {
        Size = UDim2.new(1, -36, 0, 6), Position = UDim2.new(0, 18, 0, 40), BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0, Parent = card,
    })
    Corner(track, 3)
    local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track })
    Corner(fill, 3)
    return function(frac, text)
        Tween(fill, 0.2, { Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0) })
        val.Text = text
    end
end

-- Плитки статистики в 2 колонки. items = { {key=, title=}, ... }. Возвращает { key = TextLabel }
local function AddStats(page, items)
    local rows = math.ceil(#items / 2)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, rows * 88 - 8), BackgroundTransparency = 1, Parent = page,
    })
    local vals = {}
    for i, it in ipairs(items) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local tile = New("Frame", {
            Size = UDim2.new(0.5, -4, 0, 80), Position = UDim2.new(col * 0.5, col == 1 and 4 or 0, 0, row * 88),
            BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = holder,
        })
        Corner(tile, 10)
        Stroke(tile)
        vals[it.key] = New("TextLabel", {
            Size = UDim2.new(1, -32, 0, 34), Position = UDim2.new(0, 16, 0, 12), BackgroundTransparency = 1,
            Text = "0", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 24,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = tile,
        })
        New("TextLabel", {
            Size = UDim2.new(1, -32, 0, 14), Position = UDim2.new(0, 16, 0, 52), BackgroundTransparency = 1,
            Text = it.title, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = tile,
        })
    end
    return vals
end

-- ═══════════════ ВКЛАДКИ И ФУНКЦИИ ═══════════════
local PageMain     = AddTab("Основное", "◆", 1, "Движение и бой")
local PageVisual   = AddTab("Визуал", "◉", 2, "Подсветка игроков")
local PageFarm     = AddTab("Фарм", "★", 3, "Автосбор монет и конфет")
local PageKill     = AddTab("Убийца", "✦", 4, "Телепорт к игроку и удар")
AddTab("Голосование", "✔", 4, "Панель голосования за карту") -- страница берётся из Tabs внутри InitVoting
local PageStats    = AddTab("Статистика", "◈", 4, "Итоги этой сессии")
local PageSettings = AddTab("Настройки", "⚙", 5, "Интерфейс и сессия")

AddBanner(PageMain)
AddSection(PageMain, "Движение")
AddToggle(PageMain, "Speed Hack", "Переопределяет WalkSpeed", false, function(s) State.Speed = s end)
AddSlider(PageMain, "Скорость", 16, 100, State.SpeedValue, function(v) State.SpeedValue = v end)
AddToggle(PageMain, "Fly (Полёт)", "WASD + Space вверх / Shift вниз", false, function(s) State.Fly = s end)
AddSlider(PageMain, "Скорость Fly", 10, 100, State.FlySpeed, function(v) State.FlySpeed = v end)
AddSection(PageMain, "Бой")
AddToggle(PageMain, "Авто-подбор пистолета", "Шериф умер: на миг телепорт к пистолету и обратно (только в раунде)", false, function(s) State.AutoGun = s end)
AddToggle(PageMain, "Aimbot", "Пока без логики, как в исходнике", false, function(s) State.Aimbot = s end)

AddSection(PageVisual, "Игроки")
AddToggle(PageVisual, "ESP Игроков (Роли)", "Murderer / Sheriff / Innocent", false, function(s) State.ESP = s end)

AddSection(PageFarm, "Автоматизация")
AddToggle(PageFarm, "Auto-Farm", "Под картой, монеты находит сам. Лобби и смерть — выкл.", false, function(s) State.AutoFarm = s end)
AddSegmented(PageFarm, "Режим фарма", { "Touch", "Teleport" }, 1, function(i)
    State.FarmMethod = (i == 1) and "touch" or "teleport"
end)
AddToggle(PageFarm, "Ресет после 40 монет", "Собрал 40 — ресет и ждём следующий раунд. Выкл: собирает без лимита", true, function(s) State.FarmReset = s end)
AddSlider(PageFarm, "Скорость полёта", 5, 24, State.FarmFlySpeed, function(v) State.FarmFlySpeed = v end)
AddSlider(PageFarm, "Скорость телепорта, стад/с", 5, 60, State.TpSpeed, function(v) State.TpSpeed = v end)
AddSegmented(PageFarm, "Старт отсчёта", { "Выдача роли", "Появление монет" }, 2, function(i)
    State.FarmTrigger = (i == 1) and "role" or "coins"
end)
AddSegmented(PageFarm, "Ожидание перед фармом", { "0 с", "6 с", "12 с", "18 с" }, 1, function(i)
    State.FarmStartDelay = ({ 0, 6, 12, 18 })[i]
end)
AddToggle(PageFarm, "Анти-АФК", "Не выкидывает с сервера за бездействие", true, function(s) State.AntiAFK = s end)
AddSection(PageFarm, "Диагностика")
local FarmStatus = AddInfo(PageFarm, "Статус: выключено", 46)
local FarmDebug  = AddInfo(PageFarm, "—", 46)
local CoinSel    = AddInfo(PageFarm, "Монеты: авто (по умолчанию coin / candy)", 46)
local FarmBar    = AddProgress(PageFarm, "Монеты в раунде")
local lastUIKey  = ""
local function UpdateFarmUI(short, count, limit, collecting)
    Tabs["Фарм"].Dot.Visible = State.AutoFarm
    if not (State.AutoFarm and short) then
        HUD.Visible = false
        lastUIKey = ""
        ChipText.Text = State.AutoFarm and L("Фарм: пауза") or L("Фарм выкл")
        ChipText.TextColor3 = State.AutoFarm and Theme.Text or Theme.TextDim
        ChipDot.BackgroundColor3 = State.AutoFarm and Theme.AccentHi or Theme.TextDim
        return
    end
    HUD.Visible = true
    local method = State.FarmMethod == "teleport" and "Teleport" or "Touch"
    local key = short .. "|" .. count .. "|" .. method .. "|" .. tostring(collecting) .. "|" .. I18N.lang
    if key == lastUIKey then return end
    lastUIKey = key
    ChipText.Text = L("Фарм ") .. count .. "/" .. limit
    ChipText.TextColor3 = Theme.Text
    ChipDot.BackgroundColor3 = collecting and Theme.Good or Theme.AccentHi
    H.Title.Text = "Auto-Farm · " .. method .. " · " .. L(short)
    H.Count.Text = count .. "/" .. limit
    local frac = math.clamp(count / limit, 0, 1)
    Tween(H.Fill, 0.2, { Size = UDim2.new(frac, 0, 1, 0) })
    Tween(H.Dot, 0.2, { BackgroundColor3 = collecting and Theme.Good or Theme.AccentHi })
    FarmBar(frac, count .. " / " .. limit)
end

local RestoreCollisions -- задаётся в блоке Auto-Farm ниже
local RestoreFly        -- задаётся в блоке Fly ниже
local ReturnHome        -- задаётся в блоке Auto-Farm ниже
local IntroBlur         -- (оставлено для совместимости: в новом интро размытия нет)

local function Unload()
    Alive = false
    Vote.Running = false
    State.ESP, State.Speed, State.AutoFarm, State.Fly, State.Aimbot = false, false, false, false, false
    State.AutoGun = false
    if ReturnHome then ReturnHome() end
    if RestoreCollisions then RestoreCollisions() end
    if RestoreFly then RestoreFly() end
    for _, p in pairs(Players:GetPlayers()) do ClearESP(p) end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = 16 end
    if IntroBlur then pcall(function() IntroBlur:Destroy() end) end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    SG:Destroy()
end

-- ═══════════════ ВКЛАДКА «УБИЙЦА»: список игроков -> телепорт, удар ножом, возврат ═══════════════
local KillTarget            -- задаётся в блоке «Убийца» ниже (после логики)
local KillDwell = 0.15      -- максимум секунд у цели (выходим раньше, как только цель мертва)

local function AddPlayerList(page, onPick)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page,
    })
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.Name, Parent = holder })
    local function refresh()
        for _, c in ipairs(holder:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local b = New("TextButton", {
                    Name = p.Name:lower(), Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
                    AutoButtonColor = false, Text = "   " .. p.DisplayName .. "  (@" .. p.Name .. ")", TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, Parent = holder,
                })
                Corner(b, 10)
                local st = Stroke(b)
                New("TextLabel", {
                    Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -84, 0, 0), BackgroundTransparency = 1,
                    Text = "УБИТЬ", TextColor3 = Theme.Danger, Font = Enum.Font.GothamBold, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right, Parent = b,
                })
                Connect(b.MouseEnter, function()
                    Tween(b, 0.15, { BackgroundColor3 = Theme.CardHov }); Tween(st, 0.15, { Color = Theme.StrokeHi })
                end)
                Connect(b.MouseLeave, function()
                    Tween(b, 0.15, { BackgroundColor3 = Theme.Card }); Tween(st, 0.15, { Color = Theme.Stroke })
                end)
                Connect(b.MouseButton1Click, function() onPick(p) end)
            end
        end
    end
    refresh()
    Connect(Players.PlayerAdded, function() task.defer(refresh) end)
    Connect(Players.PlayerRemoving, function() task.defer(refresh) end)
end

AddSection(PageKill, "Статус")
local KillStatus = AddInfo(PageKill, "Твоя роль: …", 46)
task.spawn(function()
    while Alive do
        task.wait(0.5)
        local r = GetRole(LP)
        KillStatus.Text = (r == "Murderer") and L("Ты убийца: выбери игрока ниже") or string.format(L("Твоя роль: %s. Работает только у убийцы"), r)
    end
end)
AddSlider(PageKill, "Макс. время у цели, мс", 50, 400, math.floor(KillDwell * 1000), function(v) KillDwell = v / 1000 end)
AddSection(PageKill, "Игроки (нажми, чтобы убить)")
AddPlayerList(PageKill, function(p) if KillTarget then KillTarget(p) end end)

AddSection(PageStats, "Эта сессия")
local StatTiles = AddStats(PageStats, {
    { key = "coins",  title = "Монет собрано" },
    { key = "rounds", title = "Раундов в фарме" },
    { key = "resets", title = "Ресетов" },
    { key = "time",   title = "Время сессии" },
})
task.spawn(function()
    while Alive do
        task.wait(1)
        local t = math.floor(os.clock() - Stats.t0)
        StatTiles.coins.Text = tostring(Stats.coins)
        StatTiles.rounds.Text = tostring(Stats.rounds)
        StatTiles.resets.Text = tostring(Stats.resets)
        StatTiles.time.Text = string.format("%d:%02d:%02d", math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
    end
end)

AddSection(PageSettings, "Интерфейс")
AddSegmented(PageSettings, "Язык", { "English", "Русский" }, 1, function(i)
    I18N.lang = (i == 1) and "en" or "ru"
    ApplyLang()
end)
AddSlider(PageSettings, "Масштаб окна, %", 60, 130, 100, function(v)
    BaseScale = FitScale() * (v / 100)
    MainScale.Scale = BaseScale
end)
AddButton(PageSettings, "Свернуть / показать  (RightShift)", Theme.Card, function() Main.Visible = not Main.Visible end)
AddSection(PageSettings, "Сессия")
AddButton(PageSettings, "Выгрузить скрипт", Theme.Danger, Unload)

-- ═══════════════ СВОРАЧИВАНИЕ / ЗАКРЫТИЕ ═══════════════
-- Свёрнутое окно: круглая кнопка у правого края на уровне большого пальца (не в углу под меню Roblox).
-- Её можно перетащить: после отпускания она прилипает к ближайшему краю и запоминает место.
local Pill = New("TextButton", {
    Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(1, -66, 0.42, -26),
    BackgroundColor3 = Theme.Card, BorderSizePixel = 0, AutoButtonColor = false,
    Text = "PH", TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 14,
    Visible = false, ZIndex = 20, Parent = SG,
})
Corner(Pill, 26)
Stroke(Pill, Theme.StrokeHi, 1.5)
if LogoAsset then
    Pill.Text = ""
    local pimg = New("ImageLabel", {
        Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), BackgroundTransparency = 1,
        Image = LogoAsset, ScaleType = Enum.ScaleType.Fit, ZIndex = 21, Parent = Pill,
    })
    Corner(pimg, 22)
end

local IntroDone = false
local function SetOpen(open)
    if not IntroDone then return end
    if open then
        Main.Visible = true
        Pill.Visible = false
        MainScale.Scale = BaseScale * 0.92
        Tween(MainScale, 0.3, { Scale = BaseScale }, Enum.EasingStyle.Quint)
    else
        Tween(MainScale, 0.15, { Scale = BaseScale * 0.94 })
        task.delay(0.15, function()
            if Alive then Main.Visible = false; Pill.Visible = true end
        end)
    end
end

Connect(MinBtn.MouseButton1Click, function() SetOpen(false) end)
do
    local dragging, moved, dragStart, startAbs = false, false, nil, nil
    Connect(Pill.InputBegan, function(i)
        if IsPress(i) then
            dragging, moved, dragStart, startAbs = true, false, i.Position, Pill.AbsolutePosition
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = i.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            if moved then
                local vp = SG.AbsoluteSize
                local x = math.clamp(startAbs.X + d.X, 6, vp.X - Pill.AbsoluteSize.X - 6)
                local y = math.clamp(startAbs.Y + d.Y, 6, vp.Y - Pill.AbsoluteSize.Y - 6)
                Pill.Position = UDim2.new(0, x, 0, y)
            end
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if dragging and IsPress(i) then
            dragging = false
            if not moved then
                SetOpen(true)
            else -- прилипание к ближайшему боковому краю
                local vp = SG.AbsoluteSize
                local p = Pill.AbsolutePosition
                local toLeft = (p.X + Pill.AbsoluteSize.X / 2) < vp.X / 2
                local x = toLeft and 14 or (vp.X - Pill.AbsoluteSize.X - 14)
                Tween(Pill, 0.25, { Position = UDim2.new(0, x, 0, p.Y) }, Enum.EasingStyle.Quint)
            end
        end
    end)
end
-- HUD можно перетаскивать
do
    local dragging, dragStart, startPos = false, nil, nil
    Connect(HUD.InputBegan, function(i)
        if IsPress(i) then dragging, dragStart, startPos = true, i.Position, HUD.Position end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = i.Position - dragStart
            HUD.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if IsPress(i) then dragging = false end
    end)
end

-- FPS и время сессии (других анимаций у окна нет: интерфейс статичный)
do
    local fpsAcc, fpsN = 0, 0
    Connect(RunService.RenderStepped, function(dt)
        fpsAcc += dt
        fpsN += 1
        if fpsAcc >= 0.5 then
            local el = math.floor(os.clock() - Stats.t0)
            FpsLabel.Text = string.format("%d FPS  ·  %d:%02d:%02d", math.floor(fpsN / fpsAcc + 0.5),
                math.floor(el / 3600), math.floor(el / 60) % 60, el % 60)
            fpsAcc, fpsN = 0, 0
        end
    end)
end
Connect(CloseBtn.MouseButton1Click, Unload)
Connect(UserInputService.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then SetOpen(not Main.Visible) end
end)

-- ═══════════════ ИНТРО ═══════════════
-- Матовый фон -> логотип проявляется -> линия раскрывается от центра -> «PRO HUB» печатается по буквам ->
-- подзаголовок -> внизу «by shebx436» и тонкая полоса загрузки на всю ширину -> всё плавно тает, окно раскрывается.
-- Клик / клавиша = пропустить. Без TextService и CanvasGroup (меньше шансов, что что-то не отрисуется).
local function FadeAll(root, t) -- плавно гасит всё внутри root
    for _, d in ipairs(root:GetDescendants()) do
        local goal
        if d:IsA("TextLabel") then goal = { TextTransparency = 1, BackgroundTransparency = 1 }
        elseif d:IsA("ImageLabel") then goal = { ImageTransparency = 1, BackgroundTransparency = 1 }
        elseif d:IsA("Frame") then goal = { BackgroundTransparency = 1 }
        elseif d:IsA("UIStroke") then goal = { Transparency = 1 } end
        if goal then Tween(d, t, goal) end
    end
end

local function RunIntro()
    local active, skip = true, false
    local PANEL = Color3.fromRGB(14, 15, 18)

    local Intro = New("Frame", {
        Name = "Intro", Size = UDim2.fromScale(1, 1), BackgroundColor3 = PANEL,
        BorderSizePixel = 0, ZIndex = 100, Active = true, Parent = SG,
    })
    local C = New("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 101, Parent = Intro,
    })

    -- пропуск: только по прошествии 0.6 с, чтобы случайное касание при запуске не съело интро
    local startAt = os.clock()
    Connect(UserInputService.InputBegan, function(i)
        if active and os.clock() - startAt > 0.6
            and (IsPress(i) or i.UserInputType == Enum.UserInputType.Keyboard) then
            skip = true
        end
    end)

    -- логотип (картинка MM2) в тонкой рамке
    local logoBox = New("Frame", {
        Size = UDim2.new(0, 104, 0, 104), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -96),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = C,
    })
    Corner(logoBox, 24)
    local logoStroke = Stroke(logoBox, Theme.StrokeHi, 1)
    logoStroke.Transparency = 1
    local logoScale = New("UIScale", { Scale = 0.8, Parent = logoBox })
    local logoImg
    if LogoAsset then
        logoImg = New("ImageLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = LogoAsset, ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Fit, Parent = logoBox,
        })
        Corner(logoImg, 24)
    else
        logoBox.BackgroundColor3 = Theme.Accent
        logoImg = New("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "P", TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBlack, TextSize = 52, TextTransparency = 1, Parent = logoBox,
        })
    end
    Tween(logoBox, 0.8, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
    Tween(logoStroke, 0.8, { Transparency = 0 })
    Tween(logoImg, 0.8, LogoAsset and { ImageTransparency = 0 } or { TextTransparency = 0 }, Enum.EasingStyle.Quint)
    Tween(logoScale, 0.9, { Scale = 1 }, Enum.EasingStyle.Quint)

    -- «PRO HUB»: весь текст уже на месте по центру, буквы открываются по одной (MaxVisibleGraphemes)
    local title = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 52), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 6),
        BackgroundTransparency = 1, RichText = true, TextColor3 = Theme.Text, Font = Enum.Font.GothamBlack, TextSize = 42,
        Text = '<font color="#E8E9EE">PRO</font> <font color="#B8A0F6">HUB</font>',
        MaxVisibleGraphemes = 0, Parent = C,
    })
    task.spawn(function()
        task.wait(0.7)
        for n = 1, 7 do
            if not title.Parent then return end
            title.MaxVisibleGraphemes = n
            task.wait(skip and 0 or 0.09)
        end
    end)

    -- линия под названием раскрывается от центра
    local line = New("Frame", {
        Size = UDim2.new(0, 0, 0, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 44),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = C,
    })
    task.delay(0.6, function()
        if line.Parent then Tween(line, 1.0, { Size = UDim2.new(0, 260, 0, 2) }, Enum.EasingStyle.Quint) end
    end)

    local sub = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 66),
        BackgroundTransparency = 1, Text = "MURDER MYSTERY 2   ·   AUTOMATION SUITE", TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextTransparency = 1, Parent = C,
    })
    task.delay(1.4, function()
        if sub.Parent then Tween(sub, 0.7, { TextTransparency = 0 }) end
    end)

    local status = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 108),
        BackgroundTransparency = 1, Text = "", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, Parent = C,
    })

    -- внизу: подпись автора и тонкая полоса прогресса на всю ширину (подпись сразу видна, без задержек)
    local by = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -28),
        BackgroundTransparency = 1, Text = 'by <font color="#B8A0F6">shebx436</font>', RichText = true,
        TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 15, Parent = C,
    })
    local barBack = New("Frame", {
        Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = C,
    })
    local barFill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = barBack,
    })

    local steps = {
        "Инициализация ядра…", "Загрузка интерфейса…", "Сканирование карты…",
        "Подключение ESP…", "Калибровка автофарма…", "Готово",
    }
    local total, t0 = 3.6, os.clock()
    while Alive do
        local k = skip and 1 or math.min((os.clock() - t0) / total, 1)
        local e = k * k * (3 - 2 * k)
        barFill.Size = UDim2.new(e, 0, 1, 0)
        status.Text = L(steps[math.clamp(math.floor(e * #steps) + 1, 1, #steps)]) .. "   " .. math.floor(e * 100) .. "%"
        if k >= 1 then break end
        task.wait()
    end
    if not Alive then return end

    -- финал: всё тает, фон растворяется, окно раскрывается
    task.wait(skip and 0.05 or 0.35)
    active = false
    Main.Visible = true
    MainScale.Scale = BaseScale * 0.94
    Tween(MainScale, 0.8, { Scale = BaseScale }, Enum.EasingStyle.Quint)
    FadeAll(C, 0.45)
    Tween(Intro, 0.6, { BackgroundTransparency = 1 })
    IntroDone = true
    task.delay(0.5, function()
        if Alive then Notify("MM2 PRO HUB", "Загружен. RightShift: скрыть/показать") end
    end)
    task.wait(0.8)
    pcall(function() Intro:Destroy() end)
end

-- ═══════════════ ЛОГИКА ═══════════════

-- Авто-фарм: лёжа под картой.
-- Лобби / смерть -> фарм полностью отключён: персонажа, коллизии и физику не трогает.
--   Старт раунда разрешён только если одновременно: есть монеты, сработал признак старта (роль или монеты),
--   мы внутри зоны карты (рамка вокруг монет + FARM_ZONE_MARGIN) и не умирали в этом раунде.
--   Смерть или выход из зоны = sitOut: пока признак раунда не пропадёт, фарм не стартует (даже если монеты ещё есть).
-- Старт раунда -> State.FarmStartDelay секунд лежим под полом.
-- Дальше       -> лёжа летим под ближайшей монетой, поднимаем голову до монеты, опускаемся и берём следующую.
--   Пауз между монетами нет. Цель можно сменить на лучшую, пока летим (не в момент подъёма головы).
-- Все признаки раунда/зоны/монет — ЭВРИСТИКИ, в MM2 не проверены.
local CoinSkip    = setmetatable({}, { __mode = "k" }) -- part -> os.clock() до которого монета пропускается
local NoclipOrig  = setmetatable({}, { __mode = "k" }) -- part -> исходное CanCollide
local Coins       = setmetatable({}, { __mode = "k" }) -- part -> true (реестр монет, без обхода workspace каждый кадр)
local FarmTarget  = nil
local FarmMode    = nil        -- nil / "idle" / "warmup" / "collect"
local FarmPhase   = "cruise"   -- "cruise": лёжа летим под монетой / "reach": голова вверх к монете
local PhaseTarget = nil
local HideY       = nil        -- высота, на которой лежим под полом
local FarmPitch   = math.pi / 2 -- угол головы над горизонтом (0 = лежим, pi/2 = стоим)
local FarmHeading = Vector3.new(0, 0, -1)
local HeadOffset  = 1.5        -- расстояние HumanoidRootPart -> Head
local HomeCF, Displaced = nil, false -- где стояли до фарма; сдвинули ли мы персонажа
local TouchSince  = nil
local FarmHum, FarmHumOrigStand = nil, false
local Teleported, LastSet, Fired = false, nil, false -- Teleported: нас унесла игра; LastSet: последняя поставленная позиция

local TpTarget, TpPhase, TpUntil = nil, "away", 0 -- режим Teleport: фаза "away" (за картой) / "grab" (у монеты)
local lastCoinSeen = os.clock()
local function CoinsOnMap()
    for part in pairs(Coins) do
        if part.Parent and part:IsDescendantOf(workspace) then return true end
    end
    return false
end
local FarmCount = 0 -- собрано монет в этом раунде
local FARM_COIN_LIMIT = 40
local FARM_END_GRACE = 10 -- сколько секунд без монет терпим, прежде чем считать раунд законченным
local ZoneLo, ZoneHi = nil, nil -- рамка монет (для проверки «унесло ли нас игрой»)
local Taken = setmetatable({}, { __mode = "k" }) -- монеты, которые мы уже взяли в этом раунде (не берём повторно)
local ReachedTarget = nil -- монета, до которой мы реально дотянулись (касание / телепорт)
local GunBusy = false      -- true, пока идёт подбор пистолета: фарм не трогает персонажа
local CountedPos = {} -- позиции уже засчитанных монет (у одной монеты бывает несколько деталей)
local TargetSnap, LastTakenWhy = nil, "—"      -- состояние цели в момент выбора / по какому признаку засчитали последнюю
local TP_TIMEOUT = 0.5 -- сколько секунд ждём, что монету засчитают, прежде чем её пропустить
local TpNextFire = 0      -- троттлинг firetouchinterest (раз в 0.04 с)

local FARM_CLEARANCE   = 4  -- на сколько стадов ниже монеты плывём
local FARM_ZONE_MARGIN = 60 -- запас вокруг рамки монет (во время фарма)
local FARM_START_MARGIN = 20 -- запас вокруг рамки монет для СТАРТА фарма (тесный, чтобы не стартовать из лобби)
local FARM_PITCH_RATE  = 6  -- рад/с, скорость поднятия/опускания головы

RestoreCollisions = function()
    for part, orig in pairs(NoclipOrig) do
        if part.Parent then part.CanCollide = orig end
        NoclipOrig[part] = nil
    end
    if FarmHum then
        if FarmHum.Parent then FarmHum.PlatformStand = FarmHumOrigStand end
        FarmHum = nil
    end
    PhaseTarget, FarmPhase, TouchSince, LastSet = nil, "cruise", nil, nil
    TpTarget, TpPhase = nil, "away"
end

-- вернуть персонажа на место, где он стоял до фарма (если выключили фарм посреди раунда)
ReturnHome = function()
    if not Displaced then return end
    Displaced = false
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if HomeCF and hrp and hum and hum.Health > 0 then
        hrp.CFrame = HomeCF
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    HomeCF = nil
end

local COIN_WORDS = { "coin", "candy", "candies" }   -- имена по умолчанию; точное имя выбирается кнопкой «Определить монеты»
local BAD_WORDS  = { "container", "sound", "spawn", "effect", "particle" }
local DETECT_BAD = { "kill", "lava", "portal", "door", "teleport", "spawn", "button", "water", "trap" }
local CustomCoinName = nil -- имя (lower), выбранное в списке; nil = слова по умолчанию

local function NameHas(n, list)
    for _, w in ipairs(list) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

local function CoinPartOf(v)
    local n = v.Name:lower()
    if CustomCoinName then -- выбрано вручную: только точное совпадение имени
        if n ~= CustomCoinName then return nil end
        if v:IsA("BasePart") then return v end
        if v:IsA("Model") then return v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart") end
        return nil
    end
    if NameHas(n, BAD_WORDS) then return nil end
    if v:IsA("BasePart") then
        if NameHas(n, COIN_WORDS) then return v end
        -- часть внутри контейнера / модели с именем монеты (CoinContainer, Candy и т.п.)
        local p = v.Parent
        if p and p ~= workspace and (p:IsA("Model") or p:IsA("Folder")) then
            local pn = p.Name:lower()
            if NameHas(pn, COIN_WORDS) then
                if pn:find("container", 1, true) then
                    if v:FindFirstChild("TouchInterest") then return v end
                elseif v.Name == "Handle" or v == p:FindFirstChildWhichIsA("BasePart") then
                    return v
                end
            end
        end
        return nil
    end
    if v:IsA("Model") and NameHas(n, COIN_WORDS) then
        return v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
    end
end

-- Части игроков (аксессуары, оружие, скины с «coin/candy» в имени) монетами не считаем —
-- именно из-за них фарм «магнитился» к игрокам.
local function IsPlayerStuff(v)
    local o = v.Parent
    while o and o ~= workspace do
        if o:IsA("Accessory") or o:IsA("Tool") then return true end
        if o:IsA("Model") and (o:FindFirstChildOfClass("Humanoid") or Players:GetPlayerFromCharacter(o)) then return true end
        o = o.Parent
    end
    return false
end

local function RegisterCoin(v)
    local part = CoinPartOf(v)
    if not part then return end
    if part.Size.Magnitude > 12 or IsPlayerStuff(part) or (LP.Character and part:IsDescendantOf(LP.Character)) then
        Coins[part] = nil -- слишком большая деталь / часть игрока
        return
    end
    Coins[part] = true
end

local function RebuildCoins()
    for k in pairs(Coins) do Coins[k] = nil end
    for k in pairs(CoinSkip) do CoinSkip[k] = nil end
    FarmTarget = nil
    for _, v in ipairs(workspace:GetDescendants()) do RegisterCoin(v) end
end
RebuildCoins()
Connect(workspace.DescendantAdded, RegisterCoin)
Connect(workspace.DescendantRemoving, function(v) Coins[v] = nil end)

-- Автоопределение монет (без кнопки): группы маленьких частей с одинаковым именем, с TouchInterest.
-- Запускается само, пока фарм включён и монеты по умолчанию (coin / candy) не найдены.
-- ЭВРИСТИКА, в MM2 не проверена: берём группу только если >= 5 частей с TouchInterest.
local function AutoDetectCoins()
    local groups = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Size.Magnitude <= 10 then
            if not IsPlayerStuff(v) then
                local n = v.Name:lower()
                if not NameHas(n, DETECT_BAD) and v:FindFirstChild("TouchInterest") then
                    local g = groups[n]
                    if not g then
                        g = { name = n, count = 0, named = NameHas(n, COIN_WORDS) }
                        groups[n] = g
                    end
                    g.count += 1
                end
            end
        end
    end
    local top
    for _, g in pairs(groups) do
        if g.count >= 5 then
            local score = g.count + (g.named and 500 or 0)
            if not top or score > top.score then top = { name = g.name, score = score } end
        end
    end
    if top and top.name ~= CustomCoinName then
        CustomCoinName = top.name
        RebuildCoins()
        CoinSel.Text = string.format(L("Монеты: авто (%s)"), top.name)
        Notify("Монеты", L("Найдено автоматически: ") .. top.name)
    end
end

local function ResetCoinName()
    if CustomCoinName then
        CustomCoinName = nil
        RebuildCoins()
        CoinSel.Text = L("Монеты: авто (по умолчанию coin / candy)")
    end
end

local function CoinLive(part)
    return part.Parent ~= nil and part:IsDescendantOf(workspace) and part.CanTouch ~= false and not Taken[part]
end

-- Монета «взята», если после выбора цели с ней произошло хотя бы одно из: удалена / CanTouch выключен /
-- пропал TouchInterest / стала прозрачной / уехала далеко. Возвращает причину (строку) или nil.
-- Игра может не удалять монету, а просто прятать её, поэтому смотрим не только на Parent.
local function CoinTaken(part, snap)
    if not part.Parent or not part:IsDescendantOf(workspace) then return "удалена" end
    if part.CanTouch == false and snap.can ~= false then return "CanTouch" end
    if snap.ti and not part:FindFirstChild("TouchInterest") then return "TouchInterest" end
    if part.Transparency >= snap.tr + 0.5 then return "прозрачность" end
    if (part.Position - snap.pos).Magnitude > 20 then return "сдвинута" end
    return nil
end

-- "стоимость" монеты: горизонтальное расстояние + половина подъёма над плоскостью, в которой лежим
local function CoinCost(part, pos)
    local p = part.Position
    local dh = Vector3.new(p.X - pos.X, 0, p.Z - pos.Z).Magnitude
    return dh + math.max(0, p.Y - (HideY or pos.Y)) * 0.5
end

-- возвращает: лучшую свободную монету, её стоимость, число живых монет (включая пропущенные), рамку монет lo/hi
local function ScanCoins(hrp)
    local now, pos = os.clock(), hrp.Position
    local best, bestCost, total = nil, math.huge, 0
    local lo, hi
    for part in pairs(Coins) do
        if CoinLive(part) then
            total += 1
            local p = part.Position
            lo = lo and Vector3.new(math.min(lo.X, p.X), math.min(lo.Y, p.Y), math.min(lo.Z, p.Z)) or p
            hi = hi and Vector3.new(math.max(hi.X, p.X), math.max(hi.Y, p.Y), math.max(hi.Z, p.Z)) or p
            if (CoinSkip[part] or 0) < now then
                local c = CoinCost(part, pos)
                if c < bestCost then best, bestCost = part, c end
            end
        end
    end
    return best, bestCost, total, lo, hi
end

local function InZone(pos, lo, hi)
    if not lo then return false end
    local m = FARM_ZONE_MARGIN
    return pos.X >= lo.X - m and pos.X <= hi.X + m
        and pos.Y >= lo.Y - m and pos.Y <= hi.Y + m
        and pos.Z >= lo.Z - m and pos.Z <= hi.Z + m
end

local function TopAncestor(inst)
    local o = inst
    while o.Parent and o.Parent ~= workspace do o = o.Parent end
    return o
end

-- Стоим ли мы на карте: тесная рамка вокруг монет + пол под ногами лежит в том же объекте workspace, что и монеты.
-- Если монеты лежат прямо в workspace (без модели карты), работает только рамка.
local function OnMap(char, hrp, lo, hi)
    if not lo then return false end
    local p, m = hrp.Position, FARM_START_MARGIN
    if not (p.X >= lo.X - m and p.X <= hi.X + m and p.Z >= lo.Z - m and p.Z <= hi.Z + m
        and p.Y >= lo.Y - 30 and p.Y <= hi.Y + 30) then
        return false
    end
    local tops, any = {}, false
    for part in pairs(Coins) do
        if part.Parent and part:IsDescendantOf(workspace) then
            local top = TopAncestor(part)
            if top ~= part then tops[top] = true; any = true end
        end
    end
    if not any then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    local hit = workspace:Raycast(p, Vector3.new(0, -200, 0), params)
    return hit ~= nil and tops[TopAncestor(hit.Instance)] == true
end

-- высота пола под персонажем минус State.FarmHideDepth стадов
local function ComputeHideY(char, hrp)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), params)
    return (hit and hit.Position.Y or hrp.Position.Y) - State.FarmHideDepth
end

-- Признаки выдачи ролей (эвристики): у кого-то в руках/рюкзаке нож или пистолет
-- либо на экране виден текст ровно "Innocent" / "Murderer" / "Sheriff".
local ROLE_WORDS = { innocent = true, murderer = true, sheriff = true, hero = true }

local function HasRoleTool(plr)
    local function scan(c)
        if not c then return false end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") or n:find("dagger") or n:find("murder") or n:find("gun") or n:find("pistol") or n:find("sheriff") then
                    return true
                end
            end
        end
        return false
    end
    return scan(plr.Character) or scan(plr:FindFirstChildOfClass("Backpack"))
end

local function IsShown(gui)
    local o = gui
    while o and o ~= game do
        if o:IsA("GuiObject") and not o.Visible then return false end
        if o:IsA("ScreenGui") and not o.Enabled then return false end
        o = o.Parent
    end
    return true
end

local function RoleLabelShown()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return false end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and ROLE_WORDS[d.Text:lower()] and IsShown(d) then return true end
    end
    return false
end

local function RoleAssigned()
    for _, plr in ipairs(Players:GetPlayers()) do
        if HasRoleTool(plr) then return true end
    end
    return RoleLabelShown()
end

-- Выбор цели, режим и статус
task.spawn(function()
    local bestDist, progressAt, lastTarget = math.huge, 0, nil
    local nextSignal, nextMap, emptySince, roundStart = 0, 0, nil, nil
    local signal, onMap, roleNow = false, false, false
    local armed, sitOut = true, false -- armed: новый старт только после того, как признак раунда пропал; sitOut: умерли/унесло с карты
    local lastChar, hideChar = nil, nil
    local lastDebug = ""
    local nextDetect = 0
    local lastEndAt = -1e9
    local regEmptySince = nil
    local zLo, zHi = nil, nil -- рамка ВСЕХ монет раунда: не сжимается, когда монеты собирают
    while Alive do
        task.wait()
        local now = os.clock()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local alive = hrp ~= nil and hum ~= nil and hum.Health > 0

        -- смерть или респаун посреди раунда: до конца раунда не фармим
        if roundStart and (not alive or char ~= lastChar) then
            sitOut, roundStart = true, nil
            FarmTarget, FarmMode, HideY = nil, "idle", nil
            Displaced, HomeCF = false, nil
        end
        lastChar = char

        -- игра сама перенесла персонажа (лобби, конец раунда, смерть): не возвращаем и не фармим до следующего раунда
        if Teleported then
            Teleported = false
            if roundStart then
                sitOut, roundStart = true, nil
                FarmTarget, FarmMode, HideY = nil, "idle", nil
                Displaced, HomeCF = false, nil
            end
        end

        if State.AutoFarm and alive then
            local byRole = State.FarmTrigger == "role"
            local best, bestCost, total, lo, hi = ScanCoins(hrp)
            if total > 0 then emptySince = nil else emptySince = emptySince or now end
            -- автоопределение монет: если по умолчанию ничего нет — ищем группу с TouchInterest;
            -- если найденное имя давно не даёт монет — возвращаемся к умолчанию
            -- автоопределение только если монеты по умолчанию не зарегистрированы вообще (а не когда их просто собрали)
            if now >= nextDetect then
                nextDetect = now + 3
                local registered = next(Coins) ~= nil
                if registered then regEmptySince = nil else regEmptySince = regEmptySince or now end
                if CustomCoinName and regEmptySince and now - regEmptySince > 20 then ResetCoinName() end
                if not registered and not CustomCoinName then AutoDetectCoins() end
            end
            if roundStart then
                if lo then
                    zLo = zLo and Vector3.new(math.min(zLo.X, lo.X), math.min(zLo.Y, lo.Y), math.min(zLo.Z, lo.Z)) or lo
                    zHi = zHi and Vector3.new(math.max(zHi.X, hi.X), math.max(zHi.Y, hi.Y), math.max(zHi.Z, hi.Z)) or hi
                end
            else
                zLo, zHi = nil, nil
            end
            local zl, zh = zLo or lo, zHi or hi
            local inZone = InZone(hrp.Position, zl, zh)
            ZoneLo, ZoneHi = zl, zh

            if byRole then
                if now >= nextSignal then nextSignal = now + 0.4; roleNow = RoleAssigned() end
                signal = roleNow
            else
                signal = total > 0
            end
            if not signal then armed, sitOut = true, false end

            -- СТАРТ: только если мы реально стоим на карте (пол под ногами принадлежит тому же объекту, что и монеты,
            -- и мы в тесной рамке вокруг них). В лобби это не выполняется, даже если раунд идёт.
            if not roundStart then
                FarmMode, HideY = "idle", nil
                if now >= nextMap then
                    nextMap = now + 0.25
                    onMap = total > 0 and OnMap(char, hrp, lo, hi)
                end
                if signal and armed and not sitOut and onMap then roundStart = now
                    if now - lastEndAt > 25 then -- новый раунд, а не короткая пауза монет
                        FarmCount, CountedPos = 0, {}
                        Stats.rounds += 1
                        for k in pairs(Taken) do Taken[k] = nil end
                    end
                end
            end

            if roundStart then
                local ended = total == 0 and now - (emptySince or now) > FARM_END_GRACE -- монеты кончились
                local left = total > 0 and not inZone                      -- унесло далеко от карты
                if ended or left then
                    if ended then ReturnHome() else Displaced, HomeCF = false, nil end
                    if left then sitOut = true end
                    Notify("Auto-Farm", ended and "Монеты кончились: жду" or "Унесло с карты: жду следующий раунд")
                    lastEndAt = now
                    FarmMode, FarmTarget, HideY, roundStart, armed = "idle", nil, nil, nil, false
                elseif State.FarmReset and FarmCount >= FARM_COIN_LIMIT then
                    -- набрали лимит: ресет персонажа, до конца раунда не фармим
                    FarmCount, CountedPos = 0, {}
                    Stats.resets += 1
                    sitOut, roundStart = true, nil
                    FarmTarget, FarmMode, HideY = nil, "idle", nil
                    Displaced, HomeCF = false, nil
                    Notify("Auto-Farm", "40 монет: ресет")
                    pcall(function() hum.Health = 0 end)
                    pcall(function() char:BreakJoints() end)
                else
                    if hideChar ~= char or not HideY then
                        hideChar = char
                        HideY = ComputeHideY(char, hrp)
                        local head = char:FindFirstChild("Head")
                        if head then HeadOffset = hrp.CFrame:PointToObjectSpace(head.Position).Magnitude end
                    end
                    if now - roundStart < State.FarmStartDelay then
                        FarmMode = "warmup"
                    else
                        FarmMode = "collect"
                        if FarmTarget and TargetSnap and TargetSnap.part == FarmTarget then
                            local why = CoinTaken(FarmTarget, TargetSnap)
                            if why then -- монета подобрана: засчитываем
                                local sp, dup = TargetSnap.pos, false
                                for _, q in ipairs(CountedPos) do
                                    if (q - sp).Magnitude < 3 then dup = true; break end
                                end
                                local ours = (ReachedTarget == FarmTarget) -- пропала до нас = подобрал кто-то другой
                                if not dup and ours then
                                    FarmCount += 1
                                    Stats.coins += 1
                                    CountedPos[#CountedPos + 1] = sp
                                end
                                -- соседние детали той же монеты (в пределах 3 стадов) тоже считаем взятыми
                                for part in pairs(Coins) do
                                    if (part.Position - sp).Magnitude < 3 then Taken[part] = true end
                                end
                                Taken[FarmTarget] = true
                                LastTakenWhy = L(why) .. (dup and L(" (дубль)") or "") .. (ours and "" or L(" (не наша)"))
                                FarmTarget = nil
                            end
                        end
                        if FarmTarget and (not CoinLive(FarmTarget) or (CoinSkip[FarmTarget] or 0) > now) then
                            FarmTarget = nil -- монету подобрали: следующая берётся в этот же кадр, без паузы
                        end
                        if not FarmTarget then FarmPhase = "cruise" end
                        if FarmPhase ~= "reach" and TpPhase ~= "grab" and best then
                            if not FarmTarget or bestCost < CoinCost(FarmTarget, hrp.Position) * 0.7 then
                                FarmTarget = best
                            end
                        end
                        -- защита от застревания: нет приближения к цели 2.5 с -> берём другую
                        if FarmTarget ~= lastTarget then
                            lastTarget, bestDist, progressAt = FarmTarget, math.huge, now
                            TargetSnap = FarmTarget and {
                                part = FarmTarget, tr = FarmTarget.Transparency, can = FarmTarget.CanTouch,
                                ti = FarmTarget:FindFirstChild("TouchInterest") ~= nil, pos = FarmTarget.Position,
                            } or nil
                        end
                        if FarmTarget then
                            local d = (FarmTarget.Position - hrp.Position).Magnitude
                            if d < bestDist - 0.5 then
                                bestDist, progressAt = d, now
                            elseif now - progressAt > 2.5 then
                                CoinSkip[FarmTarget] = now + 3
                                FarmTarget = nil
                            end
                        end
                    end
                end
            end

            if FarmTarget then
                local tp = FarmTarget.Position
                FarmStatus.Text = string.format(L("%s   |   монета: %.0f, %.0f, %.0f   |   до неё: %.0f"),
                    State.FarmMethod == "teleport" and (TpPhase == "grab" and L("Телепорт к монете") or L("За картой"))
                        or (FarmPhase == "reach" and L("Голова вверх") or L("Лёжа под картой")),
                    tp.X, tp.Y, tp.Z, (tp - hrp.Position).Magnitude)
            elseif FarmMode == "warmup" and roundStart then
                FarmStatus.Text = string.format(L("Старт раунда: ждём %.0f с (лёжа под полом)"),
                    math.max(0, State.FarmStartDelay - (now - roundStart)))
            elseif FarmMode == "collect" then
                FarmStatus.Text = L("Раунд идёт, свободных монет нет")
            elseif sitOut then
                FarmStatus.Text = L("Не в раунде (умер / в лобби): ждём следующий")
            elseif signal and not onMap then
                FarmStatus.Text = L("Монеты есть, но ты не на карте (лобби): не фармим")
            elseif byRole then
                FarmStatus.Text = L("Лобби: ждём выдачу ролей")
            else
                FarmStatus.Text = L("Лобби: ждём появление монет")
            end
            local dbg = string.format(L("Монет найдено: %d   ·   Собрано: %d/%d   ·   Признак раунда: %s   ·   Ты на карте: %s   ·   Зачёт: %s"),
                total, FarmCount, FARM_COIN_LIMIT, signal and L("да") or L("нет"), (roundStart or onMap) and L("да") or L("нет"), LastTakenWhy)
            if dbg ~= lastDebug then lastDebug = dbg; FarmDebug.Text = dbg end

            local short
            if FarmTarget then short = "Собираю монеты"
            elseif FarmMode == "warmup" and roundStart then short = "Старт раунда…"
            elseif FarmMode == "collect" then short = "Монет нет"
            elseif sitOut then short = "Ждём новый раунд"
            elseif signal and not onMap then short = "Не на карте"
            else short = "Ждём раунд" end
            UpdateFarmUI(short, FarmCount, FARM_COIN_LIMIT, FarmTarget ~= nil)
        else
            if not State.AutoFarm then
                if Displaced then ReturnHome() end -- выключили посреди раунда: возвращаем наверх
                armed, roundStart = true, nil
                FarmStatus.Text = L("Статус: выключено")
            else
                FarmStatus.Text = L("Мёртв / нет персонажа: фарм отключён")
            end
            if lastDebug ~= "—" then lastDebug = "—"; FarmDebug.Text = "—" end
            UpdateFarmUI(State.AutoFarm and "Мёртв / нет персонажа" or nil, FarmCount, FARM_COIN_LIMIT, false)
            FarmTarget, FarmMode, HideY, emptySince = nil, nil, nil, nil
        end
    end
end)

-- Положение тела: heading — горизонтальное направление, pitch — угол головы над горизонтом.
-- pitch = 0: лежим лицом вниз головой вперёд; pitch = pi/2: стоим.
local function BodyCF(pos, heading, pitch)
    local c, s = math.cos(pitch), math.sin(pitch)
    local up = heading * c + Vector3.yAxis * s
    local look = -Vector3.yAxis * c + heading * s
    local back = -look
    return CFrame.fromMatrix(pos, up:Cross(back), up, back)
end

-- Полёт + noclip (каждый физический шаг), только пока идёт раунд
Connect(RunService.Stepped, function(_, dt)
    if GunBusy then return end -- идёт подбор пистолета
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local active = State.AutoFarm and not Teleported and (FarmMode == "warmup" or FarmMode == "collect")

    if active and hrp and hum and hum.Health > 0 then
        -- резкий скачок позиции, который сделали не мы = персонажа унесла игра (смерть, лобби, конец раунда)
        -- (если мы всё ещё у карты и скачок небольшой — это лаг/откат сервера, продолжаем фарм)
        local jump = (Displaced and LastSet) and (hrp.Position - LastSet).Magnitude or 0
        if jump > 12 and not (jump < 80 and InZone(hrp.Position, ZoneLo, ZoneHi)) then
            Teleported = true
            RestoreCollisions()
            return
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if NoclipOrig[part] == nil then NoclipOrig[part] = part.CanCollide end
                part.CanCollide = false
            end
        end

        if FarmHum ~= hum then
            FarmHum, FarmHumOrigStand = hum, false
        end
        if not Displaced then
            Displaced, HomeCF, LastSet = true, hrp.CFrame, nil
            local flat = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
            FarmHeading = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
            FarmPitch = math.pi / 2 -- начинаем стоя и ложимся по пути вниз
        end
        hum.PlatformStand = true
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        local pos = hrp.Position
        local goal, pitchTarget, speed = nil, 0, State.FarmFlySpeed
        local target = FarmTarget
        if FarmMode == "collect" and target and target:IsDescendantOf(workspace) and State.FarmMethod == "teleport" then
            -- Teleport: короткими прыжками (скорость ограничена) летим к монете, касаемся, затем к следующей.
            -- За картой (под полом) сидим только когда монет нет.
            local t = os.clock()
            local cp = target.Position
            if target ~= TpTarget then TpTarget, TpUntil = target, nil end
            local delta = cp - pos
            local dist = delta.Magnitude
            if dist > 1 then
                -- в пути: короткие прыжки раз в 0.1 с, суммарная скорость не выше State.TpSpeed (иначе кик за скорость)
                TpPhase, TpUntil, FarmPitch = "away", nil, math.pi / 2
                if t >= TpNextFire then
                    TpNextFire = t + 0.1
                    pos = pos + delta.Unit * math.min(State.TpSpeed * 0.1, dist)
                end
            else
                TpPhase, FarmPitch, ReachedTarget = "grab", math.pi / 2, target
                pos = cp
                TpUntil = TpUntil or (t + TP_TIMEOUT)
                if t >= TpNextFire then
                    TpNextFire = t + 0.04
                    pcall(function() -- только если есть в эксплоите
                        if firetouchinterest then
                            firetouchinterest(hrp, target, 0)
                            firetouchinterest(hrp, target, 1)
                        end
                    end)
                end
                if t >= TpUntil then -- не засчиталась за TP_TIMEOUT: пропускаем на 4 с
                    CoinSkip[target] = t + 4
                    FarmTarget, TpTarget = nil, nil
                end
            end
            pitchTarget = FarmPitch
        elseif FarmMode == "collect" and target and target:IsDescendantOf(workspace) and State.FarmMethod ~= "teleport" then
            if target ~= PhaseTarget then PhaseTarget, FarmPhase, TouchSince, Fired = target, "cruise", nil, false end
            local cp = target.Position
            local flat = Vector3.new(cp.X - pos.X, 0, cp.Z - pos.Z)
            local cruiseY = math.min(HideY or pos.Y, cp.Y - FARM_CLEARANCE)

            if FarmPhase == "cruise" then
                if flat.Magnitude > 0.3 then FarmHeading = flat.Unit end
                goal = Vector3.new(cp.X, cruiseY, cp.Z)
                if flat.Magnitude < 1 and math.abs(pos.Y - cruiseY) < 1.5 then FarmPhase = "reach" end
            end
            if FarmPhase == "reach" then
                pitchTarget = math.pi / 2
                local t = os.clock()
                -- 1) голова в монете; 2) если за 0.2 с не подобрали — корпус (HumanoidRootPart) прямо на монету
                local grab = TouchSince ~= nil and t - TouchSince > 0.2
                goal = grab and cp or Vector3.new(cp.X, cp.Y - HeadOffset, cp.Z)
                local head = char:FindFirstChild("Head")
                local hp = head and head.Position or (pos + hrp.CFrame.UpVector * HeadOffset)
                if (hp - cp).Magnitude < 1.6 or (pos - cp).Magnitude < 1.6 then
                    TouchSince = TouchSince or t
                    ReachedTarget = target
                    if not Fired then
                        Fired = true
                        pcall(function() -- только если есть в эксплоите
                            if firetouchinterest then
                                firetouchinterest(hrp, target, 0)
                                firetouchinterest(hrp, target, 1)
                            end
                        end)
                    end
                    if t - TouchSince > 0.7 then -- коснулись, а монета не исчезла: пропускаем
                        CoinSkip[target] = t + 4
                        FarmTarget = nil
                    end
                else
                    TouchSince = nil
                end
            end
        else
            PhaseTarget, FarmPhase, TouchSince = nil, "cruise", nil
            if HideY then
                local down = Vector3.new(pos.X, HideY, pos.Z)
                if State.FarmMethod == "teleport" then
                    pos, FarmPitch, TpPhase = down, 0, "away" -- Teleport: уходим под пол мгновенно, без полёта
                    pitchTarget = 0
                else
                    goal = down -- Touch: только вниз, лёжа
                end
            end
        end

        FarmPitch += math.clamp(pitchTarget - FarmPitch, -FARM_PITCH_RATE * dt, FARM_PITCH_RATE * dt)
        if goal then
            local delta = goal - pos
            local dist = delta.Magnitude
            if dist > 0.02 then pos += delta.Unit * math.min(speed * dt, dist) end
        end
        hrp.CFrame = BodyCF(pos, FarmHeading, FarmPitch)
        LastSet = pos
    else
        RestoreCollisions()
    end
end)

-- Авто-подбор пистолета: когда шериф умирает, игра кладёт в workspace «GunDrop».
-- Работает ТОЛЬКО в раунде: есть монеты раунда, и мы на карте (или идёт фарм), и пистолет лежит в зоне карты.
-- В лобби не срабатывает.
-- Телепортируем персонажа на пистолет, ждём GUN_DWELL (серверу нужно время засчитать касание), возвращаем на то же место.
-- Имя «GunDrop» и признак раунда — ЭВРИСТИКИ по памяти об MM2, в игре не проверены.
local GunDrops = setmetatable({}, { __mode = "k" })
local GunTries = setmetatable({}, { __mode = "k" })
local GUN_DWELL = 0.12

local function GunPartOf(v)
    if not v.Name:lower():find("gundrop", 1, true) then return nil end
    if v:IsA("BasePart") then return v end
    if v:IsA("Model") then return v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart") end
    return nil
end
local function RegisterGun(v)
    local part = GunPartOf(v)
    if part and not IsPlayerStuff(part) then GunDrops[part] = true end
end
for _, v in ipairs(workspace:GetDescendants()) do RegisterGun(v) end
Connect(workspace.DescendantAdded, RegisterGun)
Connect(workspace.DescendantRemoving, function(v) GunDrops[v] = nil end)

task.spawn(function()
    local cooldownUntil = 0
    while Alive do
        task.wait(0.05)
        if State.AutoGun and not GunBusy and os.clock() >= cooldownUntil then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and GetRole(LP) == "Innocent" then -- убийце и обладателю пистолета не нужно
                local gun
                for part in pairs(GunDrops) do
                    if part.Parent and part:IsDescendantOf(workspace) and (GunTries[part] or 0) < 4 then gun = part; break end
                end
                if gun then -- в лобби не берём: нужны монеты раунда, мы на карте (или фармим) и пистолет в зоне карты
                    local _, _, coinsTotal, zlo, zhi = ScanCoins(hrp)
                    local inRound = coinsTotal > 0
                        and (FarmMode == "warmup" or FarmMode == "collect" or OnMap(char, hrp, zlo, zhi))
                    if not (inRound and InZone(gun.Position, zlo, zhi)) then gun = nil end
                end
                if gun then
                    GunTries[gun] = (GunTries[gun] or 0) + 1
                    GunBusy = true
                    local back = hrp.CFrame
                    pcall(function()
                        hrp.CFrame = CFrame.new(gun.Position)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        if firetouchinterest then
                            firetouchinterest(hrp, gun, 0)
                            firetouchinterest(hrp, gun, 1)
                        end
                        task.wait(GUN_DWELL)
                    end)
                    pcall(function()
                        if hrp.Parent then
                            hrp.CFrame = back
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                    end)
                    GunBusy = false
                    cooldownUntil = os.clock() + 1.0
                    Notify("Авто-подбор", L("Пистолет: попытка ") .. GunTries[gun])
                end
            end
        end
    end
end)

-- Анти-АФК: Roblox кикает за ~20 мин бездействия; на событие Idled шлём фиктивный клик
local VUok, VirtualUser = pcall(function() return game:GetService("VirtualUser") end)
local function AntiAfkPulse()
    if not VUok or not VirtualUser then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
Connect(LP.Idled, function() if State.AntiAFK then AntiAfkPulse() end end)
task.spawn(function() -- запасной вариант: раз в 5 минут
    while Alive do
        task.wait(300)
        if State.AntiAFK then AntiAfkPulse() end
    end
end)

-- Fly: направление камеры (W/S/A/D) + Space вверх + LeftShift вниз; на мобильных работает джойстик.
-- Не активен, пока включён Auto-Farm: он сам управляет персонажем.
local FlyHum = nil
RestoreFly = function()
    if FlyHum then
        if FlyHum.Parent then FlyHum.PlatformStand = false end
        FlyHum = nil
    end
end

Connect(RunService.Stepped, function()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if State.Fly and not State.AutoFarm and hrp and hum and hum.Health > 0 then
        FlyHum = hum
        hum.PlatformStand = true

        local dir = Vector3.zero
        if not UserInputService:GetFocusedTextBox() then
            local cam = workspace.CurrentCamera
            local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += look end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= look end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        end
        if dir.Magnitude == 0 then dir = hum.MoveDirection end -- джойстик / геймпад

        hrp.AssemblyLinearVelocity = dir.Magnitude > 0 and dir.Unit * State.FlySpeed or Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    elseif not State.AutoFarm then
        RestoreFly()
    end
end)

-- Speed + ESP
Connect(RunService.RenderStepped, function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")

    if State.Speed and hum then hum.WalkSpeed = State.SpeedValue end
    if not State.Speed and hum and hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end

    if State.ESP then
        local now = os.clock()
        local refresh = now >= ESPNext -- роли пересчитываем ~4 раза в секунду, а не каждый кадр
        if refresh then
            ESPNext = now + 0.25
            if CoinsOnMap() then
                lastCoinSeen = now
            elseif now - lastCoinSeen > 5 then
                for k in pairs(RoleMemo) do RoleMemo[k] = nil end -- раунд закончился: роли сбрасываем
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            local pchar = p ~= LP and p.Character
            if pchar then
                local hl = pchar:FindFirstChild("ProESP")
                if hl and not hl:IsA("Highlight") then hl:Destroy(); hl = nil end
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ProESP"
                    hl.Adornee = pchar
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.45
                    hl.OutlineTransparency = 0
                    hl.Parent = pchar
                    refresh = true
                end
                -- ник над головой
                local phrp = pchar:FindFirstChild("HumanoidRootPart")
                local nb = phrp and phrp:FindFirstChild("ProESPName")
                if phrp and not nb then
                    nb = Instance.new("BillboardGui")
                    nb.Name = "ProESPName"
                    nb.Size = UDim2.new(0, 120, 0, 18)
                    nb.StudsOffset = Vector3.new(0, 3.2, 0)
                    nb.AlwaysOnTop = true
                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "Label"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = p.Name
                    lbl.TextSize = 13
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextStrokeTransparency = 0
                    lbl.Parent = nb
                    nb.Parent = phrp
                    refresh = true
                end
                if refresh then
                    local role = RoleOf(p)
                    local color = Color3.fromRGB(0, 255, 0)
                    if role == "Murderer" then color = Color3.fromRGB(255, 0, 0) end
                    if role == "Sheriff" then color = Color3.fromRGB(0, 100, 255) end
                    hl.FillColor, hl.OutlineColor = color, color
                    local lbl = nb and nb:FindFirstChild("Label")
                    if lbl then lbl.TextColor3 = color end
                end
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do ClearESP(p) end
    end
end)


-- ═══════════════ УБИЙЦА: телепорт к игроку, удар, возврат ═══════════════
-- Работает, только если ты убийца (нож в руках/рюкзаке). Тебя переносит за спину цели, достаёт нож и бьёт,
-- как только цель мертва (или истекло KillDwell) возвращает на прежнее место. На это время фарм/подбор пистолета на паузе.
-- ЭВРИСТИКА, в MM2 не проверена: удар = Tool:Activate() + RemoteEvent'ы ножа с «stab/slash» в имени + касание рукоятью.
-- Если игра проверяет удар иначе, увидишь «не засчитано».
local KillBusy = false

local function FindKnife()
    local function scan(c)
        if not c then return nil end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") or n:find("dagger") then return t end
            end
        end
        return nil
    end
    return scan(LP.Character) or scan(LP:FindFirstChildOfClass("Backpack"))
end

local function StabAt(knife, tchar)
    pcall(function() knife:Activate() end)
    for _, d in ipairs(knife:GetDescendants()) do
        if d:IsA("RemoteEvent") then
            local n = d.Name:lower()
            if n:find("stab") or n:find("slash") then pcall(function() d:FireServer("Slash") end) end
        end
    end
    local handle = knife:FindFirstChild("Handle")
    if handle and firetouchinterest then
        local function touch(part)
            if part then
                pcall(function()
                    firetouchinterest(handle, part, 0)
                    firetouchinterest(handle, part, 1)
                end)
            end
        end
        touch(tchar:FindFirstChild("HumanoidRootPart"))
        touch(tchar:FindFirstChild("Head"))
    end
end

KillTarget = function(plr)
    if KillBusy or GunBusy then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then Notify("Убийца", "Ты мёртв"); return end
    if GetRole(LP) ~= "Murderer" then Notify("Убийца", "Ты не убийца"); return end
    local tchar = plr.Character
    local thrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
    local thum = tchar and tchar:FindFirstChildOfClass("Humanoid")
    if not (thrp and thum and thum.Health > 0) then Notify("Убийца", plr.Name .. L(": недоступен")); return end
    local knife = FindKnife()
    if not knife then Notify("Убийца", "Нож не найден"); return end

    KillBusy, GunBusy = true, true
    local back = hrp.CFrame
    pcall(function()
        if knife.Parent ~= char then hum:EquipTool(knife) end
        local t0 = os.clock()
        repeat
            if not (thrp.Parent and hrp.Parent) then break end
            hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 2.5)
            hrp.AssemblyLinearVelocity = Vector3.zero
            StabAt(knife, tchar)
            task.wait(0.05)
        until thum.Health <= 0 or os.clock() - t0 >= KillDwell
    end)
    pcall(function()
        if hrp.Parent then
            hrp.CFrame = back
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    KillBusy, GunBusy = false, false
    Notify("Убийца", plr.Name .. (thum.Health <= 0 and L(": убит") or L(": не засчитано")))
end

local function InitVoting()
    local PageVote = Tabs["Голосование"].Page
    -- ═══════════════ ГОЛОСОВАНИЕ ЗА КАРТУ ═══════════════
    -- Ожидаемая структура (по твоему описанию, в игре НЕ проверена):
    --   workspace.Lobby.VotePads.VotePad1 .. VotePadN   (Model, одинаковые по структуре)
    --     MapInfoGui  (SurfaceGui) -> MapIcon (ImageLabel): иконка карты
    --     VoteInfoGui (SurfaceGui) -> Container -> MapName: название карты;  Votes: счётчик голосов
    --     Pad (Part): площадка, на которую телепортируемся
    -- Отдельная панель на экране появляется сама, когда игрок в лобби и началось голосование (окно Vote.Window секунд,
    -- по умолчанию 12). Клик по карте СРАЗУ запускает голосование: телепорт на Pad -> ресет -> респавн -> повтор
    -- Vote.Count раз (количество выбирается в панели). Когда окно закончилось, серия останавливается.
    -- Признаки «игрок в лобби» и «голосование идёт» — ЭВРИСТИКИ (карты на падах заполнены и SurfaceGui включены;
    -- игрок внутри габаритов Lobby или рядом с падами). Если не сработают: вкладка «Голосование» -> «Показать панель сейчас».
    -- Засчитал ли голос сервер, скрипт не знает: он смотрит, вырос ли счётчик Votes (Vote.Seen).
    local VoteHold = 0.25 -- максимум секунд на Pad; уходим на ресет раньше, как только счётчик Votes вырос

    local function ChildCI(parent, name)
        if not parent then return nil end
        local c = parent:FindFirstChild(name)
        if c then return c end
        local low = name:lower()
        for _, ch in ipairs(parent:GetChildren()) do
            if ch.Name:lower() == low then return ch end
        end
        return nil
    end

    local function Prop(o, p) -- читает свойство, если оно у объекта есть (иначе nil)
        local ok, v = pcall(function() return o[p] end)
        if ok then return v end
        return nil
    end

    local function ReadVotes(obj) -- число из Votes: TextLabel.Text или NumberValue/IntValue.Value
        if not obj then return nil end
        local v = Prop(obj, "Text")
        if v == nil then v = Prop(obj, "Value") end
        if v == nil then return nil end
        return tonumber(tostring(v):match("%d+"))
    end

    local function GetVotePads()
        local root = ChildCI(ChildCI(workspace, "Lobby"), "VotePads")
        local list = {}
        if root then
            for _, m in ipairs(root:GetChildren()) do
                if m:IsA("Model") then list[#list + 1] = m end
            end
            table.sort(list, function(a, b)
                local x, y = tonumber(a.Name:match("%d+")) or 0, tonumber(b.Name:match("%d+")) or 0
                if x ~= y then return x < y end
                return a.Name < b.Name
            end)
        end
        return list, root ~= nil
    end

    local function FindPadPart(m)
        local p = m:FindFirstChild("Pad", true)
        if p and p:IsA("BasePart") then return p end
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("BasePart") and d.Name:lower():find("pad") then return d end
        end
        return nil
    end

    local function ReadPad(m)
        local info = { name = m.Name, pad = FindPadPart(m) }
        local mapGui = m:FindFirstChild("MapInfoGui", true)
        local icon = mapGui and mapGui:FindFirstChild("MapIcon", true)
        if icon then
            info.icon = Prop(icon, "Image")
            info.iconOff, info.iconSize = Prop(icon, "ImageRectOffset"), Prop(icon, "ImageRectSize")
        end
        local voteGui = m:FindFirstChild("VoteInfoGui", true)
        local cont = voteGui and (voteGui:FindFirstChild("Container") or voteGui)
        local nameObj = cont and cont:FindFirstChild("MapName", true)
        if nameObj then
            local t = Prop(nameObj, "Text")
            if type(t) == "string" and t ~= "" then info.mapName = t end
            info.nameImage = Prop(nameObj, "Image") -- если MapName оказался ImageLabel
        end
        info.votesObj = voteGui and voteGui:FindFirstChild("Votes", true)
        info.votes = ReadVotes(info.votesObj)
        info.shown = Prop(mapGui, "Enabled") ~= false and Prop(voteGui, "Enabled") ~= false
        info.hasMap = info.mapName ~= nil
            or (type(info.icon) == "string" and info.icon ~= "")
            or (type(info.nameImage) == "string" and info.nameImage ~= "")
        return info
    end

    -- игрок в лобби: внутри габаритов модели Lobby (с запасом) или рядом с одним из падов
    local LobbyBox = { cf = nil, size = nil, at = -1e9 }
    local function InLobby(infos)
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local lobby = ChildCI(workspace, "Lobby")
        if lobby and lobby:IsA("Model") then
            if os.clock() - LobbyBox.at > 3 then -- габариты считаем не чаще раза в 3 с
                LobbyBox.at = os.clock()
                local ok, cf, size = pcall(function() return lobby:GetBoundingBox() end)
                if ok then LobbyBox.cf, LobbyBox.size = cf, size else LobbyBox.cf = nil end
            end
            if LobbyBox.cf then
                local p = LobbyBox.cf:PointToObjectSpace(hrp.Position)
                local h = LobbyBox.size / 2 + Vector3.new(30, 50, 30)
                if math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z then return true end
            end
        end
        for _, inf in ipairs(infos) do
            if inf.pad and (inf.pad.Position - hrp.Position).Magnitude < 120 then return true end
        end
        return false
    end

    local function WaitAlive(timeout)
        local t0 = os.clock()
        while Alive and Vote.Running and os.clock() - t0 < timeout do
            local c = LP.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then return c, h, r end
            task.wait()
        end
        return nil
    end

    local function ResolvePad(name)
        for _, m in ipairs((GetVotePads())) do
            if m.Name == name then return m end
        end
        return nil
    end

    local Panel = { Open = false, Mode = "manual", Deadline = nil, Infos = {}, Found = false, Sig = "" }
    local VotePanelSync -- задаётся в блоке панели ниже

    local function StartVote(selName)
        if Vote.Running then Notify("Голосование", "Уже идёт"); return end
        if KillBusy or GunBusy then Notify("Голосование", "Занято другой функцией"); return end
        Vote.Sel = selName
        local total, deadline = Vote.Count, Panel.Deadline
        Vote.Running, Vote.Done, Vote.Seen, Vote.Total = true, 0, 0, total
        if VotePanelSync then VotePanelSync() end
        Notify("Голосование", string.format(L("Голосую за %s, раз: %d"), selName, total))

        task.spawn(function()
            local reason
            for i = 1, total do
                if not (Alive and Vote.Running) then reason = "Остановлено"; break end
                local char, hum, hrp = WaitAlive(15)
                if not hrp then reason = Vote.Running and "Персонаж не появился" or "Остановлено"; break end
                if deadline and os.clock() >= deadline then reason = "Время голосования вышло"; break end
                local model = ResolvePad(selName)
                if not model then reason = "VotePads не найдены"; break end
                local info = ReadPad(model)
                local pad = info.pad
                if not pad then reason = "Pad не найден в VotePad"; break end
                local before = info.votes

                -- телепорт на Pad; держим, пока счётчик Votes не вырос (или не вышло VoteHold)
                local t0, fired, rose = os.clock(), false, false
                repeat
                    if not (hrp.Parent and hum.Health > 0) then break end
                    hrp.CFrame = pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 3, 0)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    if not fired and firetouchinterest then -- один раз «касаемся» Pad на случай, если игра ждёт Touched
                        fired = true
                        pcall(function() firetouchinterest(hrp, pad, 0); firetouchinterest(hrp, pad, 1) end)
                    end
                    task.wait()
                    if before then
                        local now = ReadVotes(info.votesObj)
                        if now and now > before then rose = true end
                    end
                until rose or os.clock() - t0 >= VoteHold or not (Alive and Vote.Running)
                if rose then Vote.Seen += 1 end
                Vote.Done = i
                if VotePanelSync then VotePanelSync() end

                -- ресет сразу; на последнем голосе респавн не ждём
                local newChar
                local conn = LP.CharacterAdded:Connect(function(c) newChar = c end)
                if hum.Parent and hum.Health > 0 then
                    pcall(function() hum.Health = 0 end)
                    pcall(function() char:BreakJoints() end)
                end
                if i < total then
                    local t1 = os.clock()
                    while Alive and Vote.Running and not newChar and os.clock() - t1 < 15
                        and not (deadline and os.clock() >= deadline) do
                        task.wait()
                    end
                    if not newChar then
                        if not Vote.Running then reason = "Остановлено"
                        elseif deadline and os.clock() >= deadline then reason = "Время голосования вышло"
                        else reason = "Ресет не сработал" end
                    end
                end
                conn:Disconnect()
                if reason then break end
            end
            Vote.Running = false
            if VotePanelSync then VotePanelSync() end
            if Alive then
                if reason then Notify("Голосование", reason) end
                Notify("Голосование", string.format(L("Итог: циклов %d/%d, Votes вырос раз: %d"), Vote.Done, total, Vote.Seen))
            end
        end)
    end

    -- ───────── Панель на экране ─────────
    local function PanelBase() -- масштаб под узкие экраны
        local w = SG.AbsoluteSize.X
        if w < 1 then return 1 end
        return math.clamp(w / 420, 0.6, 1) * 0.74 -- панель голосования меньше
    end

    local VP = New("Frame", {
        Name = "VotePanel", Size = UDim2.new(0, 372, 0, 258), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 70), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
        Visible = false, ZIndex = 8, Parent = SG,
    })
    Corner(VP, 12)
    Stroke(VP, Theme.StrokeHi, 1)
    local VPScale = New("UIScale", { Scale = PanelBase(), Parent = VP })

    local VPHead = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = VP })
    New("TextLabel", {
        Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1,
        Text = "Голосование за карту", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = VPHead,
    })
    local TimerLbl = New("TextLabel", {
        Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -100, 0, 0), BackgroundTransparency = 1,
        Text = "—", TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = VPHead,
    })
    local VPClose = New("TextButton", {
        Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0, 6), BackgroundColor3 = Theme.CardHov,
        BorderSizePixel = 0, AutoButtonColor = false, Text = "×", TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamBold, TextSize = 14, Parent = VPHead,
    })
    Corner(VPClose, 7)
    local BarTrack = New("Frame", {
        Size = UDim2.new(1, -28, 0, 3), Position = UDim2.new(0, 14, 0, 36), BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0, Parent = VP,
    })
    Corner(BarTrack, 2)
    local BarFill = New("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = BarTrack })
    Corner(BarFill, 2)

    -- выбор количества голосов
    New("TextLabel", {
        Size = UDim2.new(0, 88, 0, 28), Position = UDim2.new(0, 14, 0, 48), BackgroundTransparency = 1,
        Text = "Голосов:", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = VP,
    })
    local function PBtn(text, x, w)
        local b = New("TextButton", {
            Size = UDim2.new(0, w, 0, 28), Position = UDim2.new(0, x, 0, 48), BackgroundColor3 = Theme.CardHov,
            BorderSizePixel = 0, AutoButtonColor = false, Text = text, TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold, TextSize = 13, Parent = VP,
        })
        Corner(b, 7)
        return b
    end
    local MinusBtn = PBtn("−", 102, 28)
    local CountLbl = New("TextLabel", {
        Size = UDim2.new(0, 34, 0, 28), Position = UDim2.new(0, 132, 0, 48), BackgroundTransparency = 1,
        Text = tostring(Vote.Count), TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 14, Parent = VP,
    })
    local PlusBtn = PBtn("+", 168, 28)
    local Chips = {}
    for k, v in ipairs({ 1, 3, 5, 10 }) do
        local b = PBtn(tostring(v), 210 + (k - 1) * 38, 32)
        b.TextSize = 12
        Chips[v] = b
        Connect(b.MouseButton1Click, function() Vote.Count = v; if VotePanelSync then VotePanelSync() end end)
    end
    Connect(MinusBtn.MouseButton1Click, function() Vote.Count = math.clamp(Vote.Count - 1, 1, 50); VotePanelSync() end)
    Connect(PlusBtn.MouseButton1Click, function() Vote.Count = math.clamp(Vote.Count + 1, 1, 50); VotePanelSync() end)

    -- карты (горизонтально)
    local CardsRow = New("Frame", {
        Size = UDim2.new(1, -20, 0, 128), Position = UDim2.new(0, 10, 0, 86), BackgroundTransparency = 1, Parent = VP,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = CardsRow,
    })

    local FooterLbl = New("TextLabel", {
        Size = UDim2.new(1, -112, 0, 28), Position = UDim2.new(0, 14, 0, 222), BackgroundTransparency = 1,
        Text = "", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = VP,
    })
    local StopBtn = New("TextButton", {
        Size = UDim2.new(0, 80, 0, 28), Position = UDim2.new(1, -92, 0, 222), BackgroundColor3 = Theme.Danger,
        BorderSizePixel = 0, AutoButtonColor = false, Text = "Остановить", TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold, TextSize = 11, Visible = false, Parent = VP,
    })
    Corner(StopBtn, 7)
    Connect(StopBtn.MouseButton1Click, function() Vote.Running = false end)

    local Cards = {}

    local function RefreshSel()
        for name, c in pairs(Cards) do
            local on = (name == Vote.Sel)
            c.st.Color = on and Theme.Accent or Theme.Stroke
            c.st.Thickness = on and 2 or 1
        end
    end

    local function BuildCards(infos)
        for _, c in pairs(Cards) do c.btn:Destroy() end
        Cards = {}
        local n = #infos
        for i, inf in ipairs(infos) do
            local name = inf.name
            local btn = New("TextButton", {
                Name = name, Size = UDim2.new(1 / n, -(8 * (n - 1)) / n, 1, 0), BackgroundColor3 = Theme.Bg,
                BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = i, Parent = CardsRow,
            })
            Corner(btn, 10)
            local st = Stroke(btn)
            local icon = New("ImageLabel", {
                Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(0.5, -32, 0, 8), BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, Image = "", Parent = btn,
            })
            Corner(icon, 8)
            local nameLbl = New("TextLabel", {
                Size = UDim2.new(1, -8, 0, 16), Position = UDim2.new(0, 4, 0, 78), BackgroundTransparency = 1,
                Text = "…", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 11,
                TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
            })
            local nameImg = New("ImageLabel", {
                Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0, 4, 0, 77), BackgroundTransparency = 1,
                ScaleType = Enum.ScaleType.Fit, Image = "", Visible = false, Parent = btn,
            })
            local votes = New("TextLabel", {
                Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0, 4, 0, 100), BackgroundTransparency = 1,
                Text = "?", TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 12, Parent = btn,
            })
            Connect(btn.MouseEnter, function() Tween(btn, 0.15, { BackgroundColor3 = Theme.CardHov }) end)
            Connect(btn.MouseLeave, function() Tween(btn, 0.15, { BackgroundColor3 = Theme.Bg }) end)
            Connect(btn.MouseButton1Click, function() StartVote(name) end) -- клик = выбор карты и сразу голосование
            Cards[name] = { btn = btn, st = st, icon = icon, name = nameLbl, nameImg = nameImg, votes = votes }
        end
        RefreshSel()
    end

    local function UpdateCard(c, info)
        if info.mapName then
            c.name.Visible, c.nameImg.Visible = true, false
            c.name.Text = info.mapName
        elseif type(info.nameImage) == "string" and info.nameImage ~= "" then
            c.name.Visible, c.nameImg.Visible = false, true
            c.nameImg.Image = info.nameImage
        else
            c.name.Visible, c.nameImg.Visible = true, false
            c.name.Text = info.name .. (info.pad and "" or ("  ·  " .. L("Pad не найден")))
        end
        c.icon.Image = (type(info.icon) == "string") and info.icon or ""
        if typeof(info.iconOff) == "Vector2" then c.icon.ImageRectOffset = info.iconOff end
        if typeof(info.iconSize) == "Vector2" then c.icon.ImageRectSize = info.iconSize end
        c.votes.Text = L("Голоса") .. ": " .. (info.votes and tostring(info.votes) or "?")
    end

    local function RefreshPanel()
        local infos = Panel.Infos
        local names = {}
        for _, inf in ipairs(infos) do names[#names + 1] = inf.name end
        local sig = table.concat(names, "|")
        if sig ~= Panel.Sig then Panel.Sig = sig; BuildCards(infos) end
        for _, inf in ipairs(infos) do
            local c = Cards[inf.name]
            if c then UpdateCard(c, inf) end
        end
        RefreshSel()
        CountLbl.Text = tostring(Vote.Count)
        for v, b in pairs(Chips) do
            local on = (v == Vote.Count)
            b.BackgroundColor3 = on and Theme.Accent or Theme.CardHov
            b.TextColor3 = on and Color3.new(1, 1, 1) or Theme.Text
        end
        StopBtn.Visible = Vote.Running
        if Vote.Running then
            FooterLbl.Text = string.format(L("Голосую: %d/%d  ·  Votes вырос раз: %d"), Vote.Done, Vote.Total, Vote.Seen)
        elseif not Panel.Found then
            FooterLbl.Text = L("Lobby/VotePads не найдены в workspace")
        else
            FooterLbl.Text = L("Нажми на карту: голосование начнётся сразу")
        end
    end
    VotePanelSync = RefreshPanel

    local function ShowPanel(mode)
        Panel.Mode = mode
        Panel.Deadline = (mode == "auto") and (os.clock() + Vote.Window) or nil
        if not Panel.Open then
            Panel.Open = true
            VPScale.Scale = PanelBase() * 0.92
            VP.Visible = true
            Tween(VPScale, 0.2, { Scale = PanelBase() }, Enum.EasingStyle.Quint)
        end
        RefreshPanel()
    end

    local function HidePanel()
        Panel.Open, Panel.Deadline = false, nil
        VP.Visible = false
    end
    Connect(VPClose.MouseButton1Click, HidePanel)

    -- таймер окна голосования
    Connect(RunService.RenderStepped, function()
        if not Panel.Open then return end
        if Panel.Deadline then
            local rem = Panel.Deadline - os.clock()
            if rem <= 0 then HidePanel(); return end
            TimerLbl.Text = math.ceil(rem) .. L(" с")
            BarFill.Size = UDim2.new(math.clamp(rem / Vote.Window, 0, 1), 0, 1, 0)
        else
            TimerLbl.Text = "—"
            BarFill.Size = UDim2.new(1, 0, 1, 0)
        end
    end)

    -- панель можно перетаскивать за шапку
    do
        local dragging, dragStart, startPos = false, nil, nil
        Connect(VPHead.InputBegan, function(i)
            if IsPress(i) then dragging, dragStart, startPos = true, i.Position, VP.Position end
        end)
        Connect(UserInputService.InputChanged, function(i)
            if dragging and IsMove(i) then
                local d = (i.Position - dragStart) / VPScale.Scale
                VP.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        Connect(UserInputService.InputEnded, function(i)
            if IsPress(i) then dragging = false end
        end)
    end

    -- ───────── Вкладка «Голосование» (настройки и диагностика) ─────────
    AddSection(PageVote, "Панель голосования")
    AddToggle(PageVote, "Автопоказ панели", "Сама появляется, когда в лобби идёт голосование за карту", true, function(s) Vote.Auto = s end)
    AddSlider(PageVote, "Окно голосования, с", 5, 30, Vote.Window, function(v) Vote.Window = v end)
    AddSlider(PageVote, "Макс. удержание на Pad, мс", 50, 1000, math.floor(VoteHold * 1000), function(v) VoteHold = v / 1000 end)
    AddButton(PageVote, "Показать панель сейчас", Theme.Accent, function() ShowPanel("manual") end)
    AddButton(PageVote, "Остановить голосование", Theme.Danger, function() Vote.Running = false end)
    AddSection(PageVote, "Диагностика")
    local VoteStatus = AddInfo(PageVote, "Поиск Lobby / VotePads…", 46)

    -- ───────── Слежение за лобби и голосованием ─────────
    -- Панель открывается, когда: игрок в лобби + на падах есть карты (SurfaceGui включены) + это «новое» голосование
    -- (раньше карты не были показаны, или набор карт/иконок сменился, или счётчики Votes упали).
    -- Авто-панель закрывается по окончании окна или когда карты на падах пропали (2 проверки подряд).
    task.spawn(function()
        local handled, lastSum, idle = nil, nil, 0
        local function yn(b) return b and L("да") or L("нет") end
        while Alive do
            task.wait(0.25)
            local pads, found = GetVotePads()
            local infos, parts, active, sum = {}, {}, false, 0
            for _, m in ipairs(pads) do
                local inf = ReadPad(m)
                infos[#infos + 1] = inf
                if inf.hasMap and inf.shown then active = true end
                parts[#parts + 1] = m.Name .. "=" .. (inf.mapName or "") .. "@" .. tostring(inf.icon or "")
                sum += inf.votes or 0
            end
            local sig = table.concat(parts, "|")
            local inLobby = found and InLobby(infos) or false
            Panel.Infos, Panel.Found = infos, found

            if not active then handled = nil end
            if lastSum and sum < lastSum then handled = nil end -- счётчики сбросились: новое голосование
            lastSum = sum
            if Vote.Auto and IntroDone and not Vote.Running and active and inLobby and handled ~= sig then
                handled = sig
                ShowPanel("auto")
            end

            if Panel.Open and Panel.Mode == "auto" then
                idle = active and 0 or idle + 1
                if idle >= 2 then
                    if Vote.Running then Vote.Running = false end
                    HidePanel()
                    idle = 0
                end
            else
                idle = 0
            end

            if Panel.Open then RefreshPanel() end
            if not found then
                VoteStatus.Text = L("Lobby/VotePads не найдены в workspace")
            else
                VoteStatus.Text = string.format(L("Лобби: %s  ·  Голосование: %s  ·  Карт: %d"), yn(inLobby), yn(active), #infos)
            end
        end
    end)
end
InitVoting()

-- ═══════════════ СТАРТ ═══════════════
SelectTab("Основное")
task.spawn(function() -- интро само раскроет окно; если в нём что-то упадёт — окно всё равно откроется
    local ok, err = pcall(RunIntro)
    if not ok and Alive then
        warn("[MM2 PRO HUB] ошибка интро: " .. tostring(err))
        local i = SG:FindFirstChild("Intro")
        if i then i:Destroy() end
        Main.Visible = true
        MainScale.Scale = BaseScale
        IntroDone = true
        Notify("MM2 PRO HUB", "Загружен (интро пропущено из-за ошибки)")
    end
end)
