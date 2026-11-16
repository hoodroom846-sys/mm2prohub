--[[
    MM2 PRO HUB  |  v4.0  "Matte"
    v4.0: плоский матовый интерфейс без неона (боковая панель вкладок, спокойная палитра, один акцент,
          без градиентов, свечения и частиц) + новое интро: сетка точек, логотип, буквы «выезжают» из-под маски,
          тонкий прогресс с этапами и раскрытие «шторками» (две половины экрана разъезжаются).
          Логика Auto-Farm / ESP / Speed / Fly / Авто-подбор пистолета не менялась.
    v4.1: переключатель языка (Настройки -> Язык: English по умолчанию / Русский) и вкладка «Голосование»
          (отдельная панель: карты из workspace.Lobby.VotePads, клик = телепорт на Pad -> ресет -> повтор N раз). Остальная логика не менялась.
    v4.2: темы (Настройки -> Тема): Matte (как было) и Snow Leopard (фото на фоне окна, вшито в base64; нужен writefile + getcustomasset). Выбранная тема сохраняется.
    v4.3: вкладка «Эфир» — глобальные сообщения от heh666145 всем, у кого запущен скрипт (баннер сверху экрана) + реакции +1 <3 :D !! :O.
    v4.4: тема «New Year» (Настройки -> Тема): ночная палитра, красный акцент, падающий снег и мигающая гирлянда. ESP: у игроков, подсвеченных серым (мертвы / в лобби), ник скрыт.
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
    TpWait = 1, -- Teleport: минимальная пауза между телепортами к монетам, секунд
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
    ["Пауза между телепортами, с"] = "Pause between teleports, s",
    ["Пауза перед телепортом: %.1f с"] = "Pause before teleport: %.1f s",
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
    ["Массово"] = "Bulk",
    ["Убить всех"] = "Kill all",
    ["Шериф"] = "Sheriff",
    ["Шот мардера"] = "Murderer shot",
    ["Быстрое"] = "Quick",
    ["Невидимость, шот, убить всех, фарм"] = "Invisibility, shot, kill all, farm",
    ["Ты не шериф"] = "You are not the sheriff",
    ["Пистолет не найден"] = "Gun not found",
    ["Убийца не найден"] = "Murderer not found",
    ["Невидимость"] = "Invisibility",
    ["Другие не видят, где ты. Для тебя тело полупрозрачное. Фарм и Fly на это время выключи"] = "Others can't see where you are. Your own body is semi-transparent. Turn Farm and Fly off meanwhile",
    ["Невидимость включена"] = "Invisibility on",
    ["Невидимость выключена"] = "Invisibility off",
    ["Не удалось включить: нет персонажа"] = "Could not enable: no character",
    ["Персонаж сменился: невидимость выключена"] = "Character changed: invisibility off",
    ["Убито: %d из %d"] = "Killed: %d of %d",
    ["Нет живых целей"] = "No living targets",
    ["Эта сессия"] = "This session",
    ["Монет собрано"] = "Coins collected",
    ["Раундов в фарме"] = "Rounds farmed",
    ["Ресетов"] = "Resets",
    ["Время сессии"] = "Session time",
    ["Интерфейс"] = "Interface",
    ["Масштаб окна, %"] = "Window scale, %",
    ["Тема"] = "Theme",
    ["Нужны writefile и getcustomasset в эксплоите"] = "writefile and getcustomasset are required",
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
    ["Эфир"] = "Broadcast",
    ["Сообщения от heh666145 и реакции"] = "Messages from heh666145 and reactions",
    ["Связь"] = "Connection",
    ["Отправить всем"] = "Send to everyone",
    ["Сообщения"] = "Messages",
    ["Подключение…"] = "Connecting…",
    ["Баннеры сообщений"] = "Message banners",
    ["Новые сообщения показываются сверху экрана"] = "New messages are shown at the top of the screen",
    ["Время показа"] = "Display time",
    ["8 с"] = "8 s",
    ["15 с"] = "15 s",
    ["30 с"] = "30 s",
    ["Введи текст сообщения"] = "Enter the message text",
    ["Слишком длинное сообщение"] = "Message is too long",
    ["В эксплоите нет http-запросов"] = "Your executor has no http requests",
    ["Не отправлено: "] = "Not sent: ",
    ["Отправлено всем"] = "Sent to everyone",
    ["Реакция не отправилась"] = "Reaction was not sent",
    ["Нет связи: в эксплоите нет http-запросов"] = "Offline: executor has no http requests",
    ["Онлайн  ·  сообщений: %d"] = "Online  ·  messages: %d",
    ["Нет связи"] = "Offline",
    ["Глобальное сообщение"] = "Global message",
    ["Текст сообщения для всех…"] = "Message for everyone…",
    ["Пока сообщений нет"] = "No messages yet",
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
local LOGO_B64 = "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"

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

-- Состояние игрока для ESP и списков: "dead" (мёртв или нет персонажа), "lobby" (внутри габаритов модели Lobby + запас,
-- та же проверка, что у голосования) или nil (жив и на карте). Если модели Lobby нет — «лобби» не определяется, остаётся только «мёртв».
local PState = { cf = nil, size = nil, at = -1e9 }
function PState.lobbyBox()
    local now = os.clock()
    if now - PState.at > 3 then -- габариты считаем не чаще раза в 3 с
        PState.at = now
        PState.cf, PState.size = nil, nil
        local lobby
        for _, c in ipairs(workspace:GetChildren()) do
            if c:IsA("Model") and c.Name:lower() == "lobby" then lobby = c; break end
        end
        if lobby then
            local ok, cf, size = pcall(function() return lobby:GetBoundingBox() end)
            if ok then PState.cf, PState.size = cf, size end
        end
    end
    return PState.cf, PState.size
end
function PState.get(p)
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return "dead" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local cf, size = PState.lobbyBox()
        if cf then
            local q = cf:PointToObjectSpace(hrp.Position)
            local h = size / 2 + Vector3.new(30, 50, 30)
            if math.abs(q.X) <= h.X and math.abs(q.Y) <= h.Y and math.abs(q.Z) <= h.Z then return "lobby" end
        end
    end
    return nil
end
PState.gray = Color3.fromRGB(150, 150, 156)

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

do -- ТЕМЫ: 1 = Matte (как было), 2 = Snow Leopard (фото на фоне окна). Theme.Apply(i) вызывает переключатель в настройках.
    local BG_B64 = "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"
    local bgImg, shade
    local function LoadBG()
        local ok, asset = pcall(function()
            local write = writefile
            local get = getcustomasset or getsynasset
            if not (write and get) then error("no file api") end
            local name = "mm2prohub_bg_snowleopard_v1.jpg"
            write(name, B64Decode(BG_B64))
            return get(name)
        end)
        if ok and asset and asset ~= "" then return asset end
        return nil
    end
    Theme.CardAlpha = 0
    Theme.Cards = setmetatable({}, { __mode = "k" }) -- все карточки (Card() регистрирует себя здесь)

    -- ── Новый год: перекраска палитры + снег + мигающая гирлянда ──
    local KEYS = { "Bg", "Sidebar", "Card", "CardHov", "Accent", "AccentHi", "Text", "TextDim", "Stroke", "StrokeHi" }
    local PAL_MATTE = {}
    for _, k in ipairs(KEYS) do PAL_MATTE[k] = Theme[k] end
    local PAL_NY = {
        Bg       = Color3.fromRGB(13, 24, 33),
        Sidebar  = Color3.fromRGB(9, 18, 26),
        Card     = Color3.fromRGB(21, 38, 50),
        CardHov  = Color3.fromRGB(29, 50, 64),
        Accent   = Color3.fromRGB(198, 46, 60),
        AccentHi = Color3.fromRGB(255, 154, 150),
        Text     = Color3.fromRGB(238, 246, 250),
        TextDim  = Color3.fromRGB(142, 172, 184),
        Stroke   = Color3.fromRGB(38, 64, 78),
        StrokeHi = Color3.fromRGB(62, 94, 110),
    }
    local function CKey(c) return math.floor(c.R * 255 + 0.5) .. "," .. math.floor(c.G * 255 + 0.5) .. "," .. math.floor(c.B * 255 + 0.5) end
    local curPal = PAL_MATTE
    local function Recolor(target)
        if target == curPal then return end
        local map = {}
        for _, k in ipairs(KEYS) do map[CKey(curPal[k])] = target[k] end
        local function fix(inst, prop)
            local t = map[CKey(inst[prop])]
            if t then inst[prop] = t end
        end
        for _, d in ipairs(Main:GetDescendants()) do
            if d:IsA("GuiObject") then
                fix(d, "BackgroundColor3")
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then fix(d, "TextColor3") end
                if d:IsA("ImageLabel") or d:IsA("ImageButton") then fix(d, "ImageColor3") end
                if d:IsA("ScrollingFrame") then fix(d, "ScrollBarImageColor3") end
            elseif d:IsA("UIStroke") then
                fix(d, "Color")
            end
        end
        fix(Main, "BackgroundColor3")
        for _, k in ipairs(KEYS) do Theme[k] = target[k] end -- элементы, созданные позже, берут новые цвета
        curPal = target
    end

    local snowLayer, snowConn
    local function SnowOff()
        if snowConn then snowConn:Disconnect(); snowConn = nil end
        if snowLayer then snowLayer:Destroy(); snowLayer = nil end
    end
    local function SnowOn()
        if snowLayer then return end
        local layer = New("Frame", {
            Name = "ThemeSnow", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = false,
            ClipsDescendants = true, ZIndex = 100, Parent = Main,
        })
        snowLayer = layer
        local flakes = {}
        for i = 1, 34 do
            local sz = math.random(2, 4)
            local f = New("Frame", {
                Size = UDim2.new(0, sz, 0, sz), BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.2 + math.random() * 0.4, BorderSizePixel = 0, Active = false,
                ZIndex = 100, Parent = layer,
            })
            Corner(f, 4)
            flakes[i] = { f = f, x = math.random(), y = math.random(), v = 0.04 + math.random() * 0.06, ph = math.random() * 6.28, sw = 0.004 + math.random() * 0.01 }
        end
        local garland = {}
        local cols = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 210, 90), Color3.fromRGB(110, 220, 140), Color3.fromRGB(110, 170, 255) }
        for i = 1, 26 do
            local d = New("Frame", {
                Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new((i - 0.5) / 26, -3, 0, 2 + (i % 2) * 3),
                BackgroundColor3 = cols[(i - 1) % 4 + 1], BorderSizePixel = 0, Active = false, ZIndex = 101, Parent = layer,
            })
            Corner(d, 3)
            garland[i] = d
        end
        local t = 0
        snowConn = RunService.Heartbeat:Connect(function(dt)
            if not layer:IsDescendantOf(game) then SnowOff(); return end
            if not Main.Visible then return end
            t += dt
            for _, s in ipairs(flakes) do
                s.y += s.v * dt
                if s.y > 1.02 then s.y = -0.02; s.x = math.random() end
                s.f.Position = UDim2.new(s.x + math.sin(t * 0.9 + s.ph) * s.sw, 0, s.y, 0)
            end
            local phase = math.floor(t * 2) % 2
            for i, d in ipairs(garland) do
                d.BackgroundTransparency = ((i + phase) % 2 == 0) and 0 or 0.55
            end
        end)
    end

    Theme.Apply = function(idx)
        local on = false
        local ny = idx == 3
        Recolor(ny and PAL_NY or PAL_MATTE)
        if ny then SnowOn() else SnowOff() end
        if idx == 2 then
            if not bgImg then
                local asset = LoadBG()
                if asset then
                    bgImg = New("ImageLabel", {
                        Name = "ThemeBG", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = asset,
                        ScaleType = Enum.ScaleType.Crop, ZIndex = 0, Parent = Main,
                    })
                    Corner(bgImg, 12)
                    shade = New("Frame", { -- затемнение, чтобы текст читался
                        Name = "ThemeShade", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
                        BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 0, Parent = Main,
                    })
                    Corner(shade, 12)
                else
                    Notify("Тема", "Нужны writefile и getcustomasset в эксплоите")
                end
            end
            on = bgImg ~= nil
        end
        if bgImg then bgImg.Visible = on; shade.Visible = on end
        Theme.CardAlpha = on and 0.3 or (ny and 0.1 or 0)
        for f in pairs(Theme.Cards) do f.BackgroundTransparency = Theme.CardAlpha end
        Sidebar.BackgroundTransparency = on and 0.3 or 0
    end
end

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

local TAB_H, TAB_STEP = 35, 38
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
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Card, BackgroundTransparency = Theme.CardAlpha or 0,
        BorderSizePixel = 0, Parent = page,
    })
    if Theme.Cards then Theme.Cards[f] = true end
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

-- Сохранение настроек (нужны readfile / writefile / isfile в эксплоите; иначе просто не сохраняется).
-- Ключ = «вкладка/название». Сохранённое значение сразу рисуется в элементе, а его callback выполняется после запуска.
local Persist = { data = {}, pending = {}, file = "MM2ProHub_settings.json", queued = false }
pcall(function()
    if isfile and readfile and isfile(Persist.file) then
        local t = game:GetService("HttpService"):JSONDecode(readfile(Persist.file))
        if type(t) == "table" then Persist.data = t end
    end
end)
Persist.linked = { ghost = {}, farm = {} } -- переключатели одной функции на разных вкладках
function Persist.link(group, v)
    for _, h in ipairs(Persist.linked[group]) do h.Set(v) end
end
function Persist.key(page, title)
    for n, t in pairs(Tabs) do
        if t.Page == page then return n .. "/" .. title end
    end
    return title
end
function Persist.restore(key, default, apply)
    local v = Persist.data[key]
    if v == nil or type(v) ~= type(default) then return default end
    if v ~= default and apply then Persist.pending[#Persist.pending + 1] = function() apply(v) end end
    return v
end
function Persist.apply() -- применить сохранённые настройки (вызывается после построения интерфейса)
    for _, f in ipairs(Persist.pending) do pcall(f) end
end
function Persist.flush()
    pcall(function()
        if writefile then writefile(Persist.file, game:GetService("HttpService"):JSONEncode(Persist.data)) end
    end)
end
function Persist.set(key, v)
    Persist.data[key] = v
    if not Persist.queued then
        Persist.queued = true
        task.delay(1, function() Persist.queued = false; Persist.flush() end)
    end
end

local function AddToggle(page, title, desc, default, callback, noApply)
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

    local key = Persist.key(page, title)
    local state = Persist.restore(key, default, (not noApply) and callback or nil)
    local function render()
        Tween(track, 0.18, { BackgroundColor3 = state and Theme.Accent or Theme.StrokeHi })
        Tween(knob, 0.2, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, Enum.EasingStyle.Quint)
    end
    render()

    Hover(hit, card, st)
    Connect(hit.MouseButton1Click, function()
        state = not state
        render()
        Persist.set(key, state)
        if callback then callback(state) end
        Notify(title, state and "Включено" or "Выключено")
    end)
    return { -- внешняя синхронизация вида и сохранённого значения (callback не вызывает)
        Set = function(v)
            if state == v then return end
            state = v
            render()
            Persist.set(key, v)
        end,
    }
end

local function AddSlider(page, title, min, max, default, callback)
    local key = Persist.key(page, title)
    default = math.clamp(Persist.restore(key, default, callback), min, max)
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
        Persist.set(key, v)
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
    local key = Persist.key(page, title)
    default = Persist.restore(key, default, function(v) callback(v, options[v]) end)
    if default < 1 or default > #options then default = 1 end
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
            Persist.set(key, i)
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
local PageMain     = AddTab("Основное", ">", 1, "Движение и бой")
local PageVisual   = AddTab("Визуал", "o", 2, "Подсветка игроков")
local PageFarm     = AddTab("Фарм", "$", 3, "Автосбор монет и конфет")
local PageKill     = AddTab("Убийца", "x", 4, "Телепорт к игроку и удар")
AddTab("Быстрое", "!", 4, "Невидимость, шот, убить всех, фарм") -- содержимое собирается ниже, после «Убийца» (нужны ShotMurderer / KillAll)
AddTab("Голосование", "v", 4, "Панель голосования за карту") -- страница берётся из Tabs внутри InitVoting
AddTab("Эфир", "@", 4, "Сообщения от heh666145 и реакции") -- страница берётся из Tabs внутри InitBroadcast
local PageStats    = AddTab("Статистика", "#", 4, "Итоги этой сессии")
local PageSettings = AddTab("Настройки", "=", 5, "Интерфейс и сессия")

local GhostSet -- невидимость, задаётся в блоке «Шот мардера / Невидимость» ниже
AddBanner(PageMain)
AddSection(PageMain, "Движение")
AddToggle(PageMain, "Speed Hack", "Переопределяет WalkSpeed", false, function(s) State.Speed = s end)
AddSlider(PageMain, "Скорость", 16, 100, State.SpeedValue, function(v) State.SpeedValue = v end)
AddToggle(PageMain, "Fly (Полёт)", "WASD + Space вверх / Shift вниз", false, function(s) State.Fly = s end)
AddSlider(PageMain, "Скорость Fly", 10, 100, State.FlySpeed, function(v) State.FlySpeed = v end)
AddSection(PageMain, "Бой")
AddToggle(PageMain, "Авто-подбор пистолета", "Шериф умер: на миг телепорт к пистолету и обратно (только в раунде)", false, function(s) State.AutoGun = s end)
AddToggle(PageMain, "Aimbot", "Пока без логики, как в исходнике", false, function(s) State.Aimbot = s end)
AddSection(PageMain, "Невидимость")
table.insert(Persist.linked.ghost, AddToggle(PageMain, "Невидимость", "Другие не видят, где ты. Для тебя тело полупрозрачное. Фарм и Fly на это время выключи", false, function(s) if GhostSet then GhostSet(s) end; Persist.link("ghost", s) end))

AddSection(PageVisual, "Игроки")
AddToggle(PageVisual, "ESP Игроков (Роли)", "Murderer / Sheriff / Innocent", false, function(s) State.ESP = s end)

AddSection(PageFarm, "Автоматизация")
table.insert(Persist.linked.farm, AddToggle(PageFarm, "Auto-Farm", "Под картой, монеты находит сам. Лобби и смерть — выкл.", false, function(s) State.AutoFarm = s; Persist.link("farm", s) end))
AddSegmented(PageFarm, "Режим фарма", { "Touch", "Teleport" }, 1, function(i)
    State.FarmMethod = (i == 1) and "touch" or "teleport"
end)
AddToggle(PageFarm, "Ресет после 40 монет", "Собрал 40 — ресет и ждём следующий раунд. Выкл: собирает без лимита", true, function(s) State.FarmReset = s end)
AddSlider(PageFarm, "Скорость полёта", 5, 24, State.FarmFlySpeed, function(v) State.FarmFlySpeed = v end)
AddSlider(PageFarm, "Пауза между телепортами, с", 1, 10, State.TpWait, function(v) State.TpWait = v end)
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
    Persist.flush()
    Vote.Running = false
    State.ESP, State.Speed, State.AutoFarm, State.Fly, State.Aimbot = false, false, false, false, false
    State.AutoGun = false
    if GhostSet then GhostSet(false) end
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
local KillAll               -- то же: «убить всех», задаётся ниже
local ShotMurderer          -- то же: шериф убивает убийцу, задаётся ниже
local KillDwell = 0.15      -- максимум секунд у цели (выходим раньше, как только цель мертва)

local function AddPlayerList(page, onPick)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page,
    })
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.Name, Parent = holder })
    local rows = {}
    local function refresh()
        for _, c in ipairs(holder:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        rows = {}
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
                local kl = New("TextLabel", {
                    Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -84, 0, 0), BackgroundTransparency = 1,
                    Text = "УБИТЬ", TextColor3 = Theme.Danger, Font = Enum.Font.GothamBold, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right, Parent = b,
                })
                rows[#rows + 1] = { p = p, b = b, kl = kl }
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
    task.spawn(function() -- мёртвые и игроки в лобби — серым
        while Alive do
            task.wait(0.5)
            for _, r in ipairs(rows) do
                if r.b.Parent then
                    local gray = PState.get(r.p) ~= nil
                    r.b.TextColor3 = gray and Theme.TextDim or Theme.Text
                    r.kl.TextColor3 = gray and Theme.TextDim or Theme.Danger
                end
            end
        end
    end)
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
AddSection(PageKill, "Шериф")
AddButton(PageKill, "Шот мардера", Theme.Danger, function() if ShotMurderer then ShotMurderer() end end)
AddSection(PageKill, "Массово")
AddButton(PageKill, "Убить всех", Theme.Danger, function() if KillAll then KillAll() end end)
AddSection(PageKill, "Игроки (нажми, чтобы убить)")
AddPlayerList(PageKill, function(p) if KillTarget then KillTarget(p) end end)

-- ═══════════════ ВКЛАДКА «БЫСТРОЕ»: те же функции, что на «Основное» / «Убийца» / «Фарм» ═══════════════
-- Переключатели синхронизированы с исходными (Persist.link); кнопки вызывают те же ShotMurderer / KillAll.
do
    local PQ = Tabs["Быстрое"].Page
    AddSection(PQ, "Невидимость")
    table.insert(Persist.linked.ghost, AddToggle(PQ, "Невидимость", "Другие не видят, где ты. Для тебя тело полупрозрачное. Фарм и Fly на это время выключи", false,
        function(s) if GhostSet then GhostSet(s) end; Persist.link("ghost", s) end, true))
    AddSection(PQ, "Фарм")
    table.insert(Persist.linked.farm, AddToggle(PQ, "Auto-Farm", "Под картой, монеты находит сам. Лобби и смерть — выкл.", false,
        function(s) State.AutoFarm = s; Persist.link("farm", s) end, true))
    AddSection(PQ, "Шериф")
    AddButton(PQ, "Шот мардера", Theme.Danger, function() if ShotMurderer then ShotMurderer() end end)
    AddSection(PQ, "Массово")
    AddButton(PQ, "Убить всех", Theme.Danger, function() if KillAll then KillAll() end end)
end

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
AddSegmented(PageSettings, "Тема", { "Matte", "Snow Leopard", "New Year" }, 1, function(i) Theme.Apply(i) end)
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
local TP_TIMEOUT = 1.5 -- сколько секунд ждём, что монету засчитают, прежде чем её пропустить
local TpNextFire = 0      -- время, раньше которого следующий телепорт к монете не делаем

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
                            elseif now - progressAt > (State.FarmMethod == "teleport" and State.TpWait * 1.4 + 3 or 2.5) then
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
                    State.FarmMethod == "teleport" and (TpPhase == "grab" and L("Телепорт к монете")
                        or (now < TpNextFire and string.format(L("Пауза перед телепортом: %.1f с"), TpNextFire - now) or L("За картой")))
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
            if FarmTarget and State.FarmMethod == "teleport" and TpPhase == "away" and now < TpNextFire then
                short = "Пауза " .. math.ceil(TpNextFire - now) .. " с"
            elseif FarmTarget then short = "Собираю монеты"
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
            -- Teleport: мгновенный прыжок к монете, ждём State.TpWait секунд, затем так же прыгаем к следующей.
            -- За картой (под полом) сидим только когда монет нет.
            local t = os.clock()
            local cp = target.Position
            if target ~= TpTarget then
                if t >= TpNextFire then
                    -- мгновенный прыжок; следующий разрешён не раньше чем через State.TpWait секунд
                    local delta = cp - pos
                    TpNextFire = t + State.TpWait * (0.8 + math.random() * 0.6) -- пауза с разбросом, чтобы темп не был «машинным»
                    if delta.Magnitude > 25 then
                        -- далеко: за раз не дальше 25 стадов (дальние мгновенные телепорты сервер считает «Invalid position»)
                        pos, FarmPitch, TpPhase = pos + delta.Unit * 25, math.pi / 2, "away"
                    else
                        TpTarget, TpUntil = target, t + TP_TIMEOUT
                        TpPhase, FarmPitch, ReachedTarget = "grab", math.pi / 2, target
                        pos = cp
                        pcall(function() -- только если есть в эксплоите
                            if firetouchinterest then
                                firetouchinterest(hrp, target, 0)
                                firetouchinterest(hrp, target, 1)
                            end
                        end)
                    end
                else
                    TpPhase = "away" -- пауза между телепортами: стоим на месте
                end
            else
                TpPhase, FarmPitch, ReachedTarget = "grab", math.pi / 2, target
                pos = cp
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
                if State.FarmMethod == "teleport" then TpPhase, TpTarget = "away", nil end
                goal = down -- уходим под пол плавно (мгновенный телепорт под карту = кик «Invalid position»)
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
                    local fillT, textT = 0.45, 0
                    if PState.get(p) then -- мёртв или в лобби: серый цвет и подсветка потише
                        color, fillT, textT = PState.gray, 0.75, 0.25
                    end
                    hl.FillColor, hl.OutlineColor, hl.FillTransparency = color, color, fillT
                    local lbl = nb and nb:FindFirstChild("Label")
                    if lbl then lbl.TextColor3, lbl.TextTransparency = color, textT end
                    if nb then nb.Enabled = not PState.get(p) end -- серый (мёртв / в лобби): ник не показываем
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

-- «Убить всех»: один заход — запоминаем место, по очереди бьём каждого живого игрока на карте (серых — мёртвых и из лобби — пропускаем),
-- в конце возвращаемся. Условия те же, что у KillTarget: ты убийца, жив, нож найден. Один итоговый Notify.
KillAll = function()
    if KillBusy or GunBusy then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then Notify("Убийца", "Ты мёртв"); return end
    if GetRole(LP) ~= "Murderer" then Notify("Убийца", "Ты не убийца"); return end
    local knife = FindKnife()
    if not knife then Notify("Убийца", "Нож не найден"); return end

    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and PState.get(p) == nil then targets[#targets + 1] = p end
    end
    if #targets == 0 then Notify("Убийца", "Нет живых целей"); return end

    KillBusy, GunBusy = true, true
    local back = hrp.CFrame
    local killed = 0
    pcall(function()
        if knife.Parent ~= char then hum:EquipTool(knife) end
        for _, plr in ipairs(targets) do
            if not Alive or hum.Health <= 0 or not hrp.Parent then break end
            local tchar = plr.Character
            local thrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
            local thum = tchar and tchar:FindFirstChildOfClass("Humanoid")
            if thrp and thum and thum.Health > 0 then
                local t0 = os.clock()
                repeat
                    if not (thrp.Parent and hrp.Parent) then break end
                    hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 2.5)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    StabAt(knife, tchar)
                    task.wait(0.05)
                until thum.Health <= 0 or os.clock() - t0 >= KillDwell
                if thum.Health <= 0 then killed += 1 end
            end
        end
    end)
    pcall(function()
        if hrp.Parent then
            hrp.CFrame = back
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    KillBusy, GunBusy = false, false
    Notify("Убийца", string.format(L("Убито: %d из %d"), killed, #targets))
end

-- ═══════════════ ШОТ МАРДЕРА (ты шериф) ═══════════════
-- На долю секунды телепорт за спину убийце, выстрел, возврат на прежнее место. Пистолет ищется среди Tool с «gun/pistol/sheriff».
-- ЭВРИСТИКА, в MM2 не проверена: выстрел = Tool:Activate() + RemoteEvent/RemoteFunction пистолета с «shoot/fire/beam» в имени
-- (аргумент — позиция головы цели). Если игра ждёт другие аргументы, увидишь «не засчитано»: тогда нужно посмотреть реальный вызов.
local function FindGun()
    local function scan(c)
        if not c then return nil end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("gun") or n:find("pistol") or n:find("sheriff") then return t end
            end
        end
        return nil
    end
    return scan(LP.Character) or scan(LP:FindFirstChildOfClass("Backpack"))
end

local function ShootAt(gun, tchar)
    local aim = tchar:FindFirstChild("Head") or tchar:FindFirstChild("HumanoidRootPart")
    if not aim then return end
    local pos = aim.Position
    pcall(function() gun:Activate() end)
    for _, d in ipairs(gun:GetDescendants()) do
        local n = d.Name:lower()
        if n:find("shoot") or n:find("fire") or n:find("beam") then
            if d:IsA("RemoteEvent") then
                pcall(function() d:FireServer(pos) end)
            elseif d:IsA("RemoteFunction") then
                task.spawn(function() pcall(function() d:InvokeServer(1, pos) end) end)
            end
        end
    end
end

ShotMurderer = function()
    if KillBusy or GunBusy then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then Notify("Шериф", "Ты мёртв"); return end
    if GetRole(LP) ~= "Sheriff" then Notify("Шериф", "Ты не шериф"); return end
    local gun = FindGun()
    if not gun then Notify("Шериф", "Пистолет не найден"); return end
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and PState.get(p) == nil and RoleOf(p) == "Murderer" then target = p; break end
    end
    local tchar = target and target.Character
    local thrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
    local thum = tchar and tchar:FindFirstChildOfClass("Humanoid")
    if not (thrp and thum and thum.Health > 0) then Notify("Шериф", "Убийца не найден"); return end

    KillBusy, GunBusy = true, true
    local back = hrp.CFrame -- при включённой невидимости это место «тела» для других; вернёмся туда же
    pcall(function()
        if gun.Parent ~= char then hum:EquipTool(gun) end
        local t0 = os.clock()
        repeat
            if not (thrp.Parent and hrp.Parent) then break end
            hrp.CFrame = CFrame.lookAt(thrp.Position - thrp.CFrame.LookVector * 6, thrp.Position)
            hrp.AssemblyLinearVelocity = Vector3.zero
            ShootAt(gun, tchar)
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
    Notify("Шериф", target.Name .. (thum.Health <= 0 and L(": убит") or L(": не засчитано")))
end

-- ═══════════════ НЕВИДИМОСТЬ ═══════════════
-- Настоящее тело якорится высоко в небе (HIDE_CF): его реплицирует сервер, другие игроки не видят тебя на карте.
-- Ходишь ты за локальную полупрозрачную копию (видна только тебе): камера привязана к ней, управление берётся из твоего WASD/прыжка.
-- Анимации копии — стандартные ролики Roblox (R15/R6) по assetId из памяти, НЕ проверены: если не загрузятся, копия просто скользит.
-- Пока включено, настоящий персонаж не на карте: собирать монеты (Фарм) и Fly не будут работать; ножом/пистолетом (Убийца, Шот мардера)
-- можно пользоваться: они сами телепортируют настоящее тело к цели и обратно в небо. Невидимость для других НЕ проверена.
local HIDE_CF = CFrame.new(0, 4000, 0)
local GHOST_ALPHA = 0.65
local GHOST_ANIMS = {
    R15 = { idle = "rbxassetid://507766666", walk = "rbxassetid://507777826", fall = "rbxassetid://507767968" },
    R6  = { idle = "rbxassetid://180435571", walk = "rbxassetid://180426354", fall = "rbxassetid://180436148" },
}
local Ghost = { on = false, want = false, conns = {} }

local function GhostStop()
    if not Ghost.on then return end
    Ghost.on = false
    for _, c in ipairs(Ghost.conns) do pcall(function() c:Disconnect() end) end
    Ghost.conns = {}
    local dest = Ghost.chrp and Ghost.chrp.Parent and Ghost.chrp.CFrame
    pcall(function()
        if Ghost.hrp and Ghost.hrp.Parent then
            Ghost.hrp.Anchored = false
            if dest then
                Ghost.hrp.CFrame = dest
                Ghost.hrp.AssemblyLinearVelocity = Vector3.zero
                Ghost.hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
    pcall(function()
        local cam = workspace.CurrentCamera
        local rh = Ghost.real and Ghost.real:FindFirstChildOfClass("Humanoid")
        if cam and rh then cam.CameraSubject = rh end
    end)
    pcall(function() Ghost.clone:Destroy() end)
    Ghost.clone, Ghost.chum, Ghost.chrp, Ghost.real, Ghost.hrp, Ghost.rhum, Ghost.tracks, Ghost.cur = nil, nil, nil, nil, nil, nil, nil, nil
end

local function GhostStart()
    if Ghost.on then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then Notify("Невидимость", "Не удалось включить: нет персонажа"); return end
    char.Archivable = true
    local clone = char:Clone()
    if not clone then Notify("Невидимость", "Не удалось включить: нет персонажа"); return end
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Tool") or d.Name == "ProESP" or d.Name == "ProESPName" then d:Destroy() end
    end
    local chum = clone:FindFirstChildOfClass("Humanoid")
    local chrp = clone:FindFirstChild("HumanoidRootPart")
    if not (chum and chrp) then clone:Destroy(); Notify("Невидимость", "Не удалось включить: нет персонажа"); return end
    for _, d in ipairs(clone:GetDescendants()) do
        if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then
            if d.Transparency < GHOST_ALPHA then d.Transparency = GHOST_ALPHA end
        end
    end
    clone.Name = "ProGhost"
    chum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    chrp.CFrame = hrp.CFrame
    clone.Parent = workspace

    local tracks = {}
    pcall(function()
        local animator = chum:FindFirstChildOfClass("Animator") or Instance.new("Animator", chum)
        local set = GHOST_ANIMS[chum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"]
        for k, id in pairs(set) do
            pcall(function()
                local a = Instance.new("Animation")
                a.AnimationId = id
                local tr = animator:LoadAnimation(a)
                tr.Looped = true
                tr.Priority = Enum.AnimationPriority.Core
                tracks[k] = tr
            end)
        end
    end)

    Ghost.on, Ghost.clone, Ghost.chum, Ghost.chrp, Ghost.real, Ghost.hrp, Ghost.rhum, Ghost.tracks, Ghost.cur =
        true, clone, chum, chrp, char, hrp, hum, tracks, nil
    hrp.Anchored = true
    hrp.CFrame = HIDE_CF
    local cam = workspace.CurrentCamera
    if cam then cam.CameraSubject = chum end

    Ghost.conns[1] = Connect(UserInputService.JumpRequest, function()
        if Ghost.on and Ghost.chum then Ghost.chum.Jump = true end
    end)
    Ghost.conns[2] = Connect(RunService.RenderStepped, function()
        if not Ghost.on then return end
        if LP.Character ~= Ghost.real or not Ghost.real.Parent or not Ghost.clone.Parent
            or Ghost.chum.Health <= 0 or Ghost.rhum.Health <= 0 then
            GhostStop()
            if Ghost.want then Notify("Невидимость", "Персонаж сменился: невидимость выключена") end
            return
        end
        local c = workspace.CurrentCamera
        if c and c.CameraSubject ~= Ghost.chum then c.CameraSubject = Ghost.chum end
        Ghost.chum.WalkSpeed = State.Speed and State.SpeedValue or 16
        Ghost.chum:Move(Ghost.rhum.MoveDirection, false)
        if not (KillBusy or GunBusy) then
            Ghost.hrp.Anchored = true
            Ghost.hrp.CFrame = HIDE_CF
        end
        local v = Ghost.chrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
        local st = Ghost.chum:GetState()
        local name = (st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping) and "fall"
            or (v.Magnitude > 1 and "walk" or "idle")
        if name ~= Ghost.cur then
            if Ghost.cur and Ghost.tracks[Ghost.cur] then Ghost.tracks[Ghost.cur]:Stop(0.15) end
            if Ghost.tracks[name] then Ghost.tracks[name]:Play(0.15) end
            Ghost.cur = name
        end
        if name == "walk" and Ghost.tracks.walk then Ghost.tracks.walk:AdjustSpeed(math.clamp(v.Magnitude / 16, 0.4, 3)) end
    end)
    Notify("Невидимость", "Невидимость включена")
end

GhostSet = function(on)
    Ghost.want = on and true or false
    if on then
        if Ghost.on then return end
        if not IntroDone then -- сохранённое «включено» применяется при старте: ждём, пока интро закончится
            task.spawn(function()
                while Alive and not IntroDone do task.wait(0.2) end
                if Alive and Ghost.want then GhostStart() end
            end)
            return
        end
        GhostStart()
    else
        local was = Ghost.on
        GhostStop()
        if was then Notify("Невидимость", "Невидимость выключена") end
    end
end

Connect(LP.CharacterAdded, function() -- после респауна невидимость включается снова, если переключатель остался включён
    if Ghost.want and not Ghost.on and Alive then
        task.wait(1)
        if Ghost.want and not Ghost.on and Alive then GhostStart() end
    end
end)

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

                -- телепорт в центр Pad; держим, пока счётчик Votes не вырос (или не вышло VoteHold)
                local t0, fired, rose = os.clock(), false, false
                repeat
                    if not (hrp.Parent and hum.Health > 0) then break end
                    hrp.CFrame = CFrame.new(pad.Position) -- ровно в центр парта Pad (прямо, без поворота Pad)
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
    local MinusBtn = PBtn("-", 102, 28)
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

-- ═══════════════ ЭФИР: глобальные сообщения от heh666145 + реакции ═══════════════
do -- в do-блоке, чтобы не занимать локальные переменные верхнего уровня (лимит Luau — 200)
-- Клиенты Roblox не могут слать данные друг другу напрямую, поэтому нужен общий канал. Здесь это публичный pub/sub ntfy.sh,
-- к которому скрипт обращается http-запросом эксплоита (syn.request / request / http_request / fluxus.request):
--   * топик CFG.tMsg   — сообщения, пишет админ (heh666145), читают все, у кого запущен скрипт;
--   * топик CFG.tReact — реакции, пишут и читают все.
-- Получение: опрос раз в CFG.poll секунд (один запрос на оба топика, since=<время последнего события>, дубликаты отсекаются по id).
-- Сообщения хранятся на сервере ntfy ~12 часов, поэтому после входа подтягивается история.
-- ВАЖНО: пока топики открыты, любой, кто прочитал скрипт, может писать в них от имени админа. Защита — не в скрипте, а на
-- сервере ntfy: сделать топик CFG.tMsg «запись только для админа» (ACL) и положить токен админа в файл
-- MM2ProHub_admin_token.txt (его читает только копия админа и шлёт как Bearer). Токен в скрипт не вшивается.
local function InitBroadcast(page)
    local HttpService = game:GetService("HttpService")
    local CFG = {
        admin  = "heh666145",
        base   = "https://ntfy.sh",
        tMsg   = "mm2prohub-cast-9c41e7d2a6b0f3",
        tReact = "mm2prohub-react-5e83b1f07d2c9a",
        poll   = 5,    -- секунд между опросами (у ntfy.sh есть лимит запросов на IP)
        maxLen = 200,  -- символов в сообщении
        keep   = 30,   -- сколько последних сообщений держим в списке
    }
    local REACTIONS = {
        { k = "like", e = "+1" }, { k = "heart", e = "<3" }, { k = "laugh", e = ":D" },
        { k = "fire", e = "!!" }, { k = "wow", e = ":O" },
    }
    local ReactSet = {}
    for _, r in ipairs(REACTIONS) do ReactSet[r.k] = true end

    local isAdmin = LP.Name:lower() == CFG.admin
    local adminId = nil -- UserId админа (если удалось узнать); тогда чужие u отбрасываются
    task.spawn(function()
        local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(CFG.admin) end)
        if ok and type(id) == "number" then adminId = id end
    end)

    local token = nil
    if isAdmin then
        pcall(function()
            if isfile and readfile and isfile("MM2ProHub_admin_token.txt") then
                token = readfile("MM2ProHub_admin_token.txt"):gsub("%s+", "")
                if token == "" then token = nil end
            end
        end)
    end

    local httpReq = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    local function Http(method, url, body, headers)
        if not httpReq then return nil, "no http" end
        local ok, res = pcall(httpReq, { Url = url, Method = method, Headers = headers, Body = body })
        if not ok then return nil, tostring(res) end
        if type(res) ~= "table" then return nil, "bad response" end
        return res
    end
    local function CodeOf(res) return res.StatusCode or res.status_code end
    local function BodyOf(res) return tostring(res.Body or res.body or "") end

    local function Post(topic, tbl, auth)
        local headers = { ["Content-Type"] = "text/plain; charset=utf-8" }
        if auth and token then headers.Authorization = "Bearer " .. token end
        local res, err = Http("POST", CFG.base .. "/" .. topic, HttpService:JSONEncode(tbl), headers)
        if not res then return nil, err end
        local code = CodeOf(res)
        if code ~= 200 then return nil, "HTTP " .. tostring(code) end
        local ok, d = pcall(HttpService.JSONDecode, HttpService, BodyOf(res))
        if ok and type(d) == "table" and d.id then return d end
        return nil, "bad response"
    end

    local function Raw(o, s) -- текст из сети не должен переводиться таблицей I18N
        I18N.reg[o] = nil
        o.Text = s
        return o
    end

    local function Clean(s)
        s = s:gsub("%c", function(c) return (c == "\n") and "\n" or "" end)
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        local n = utf8.len(s)
        if not n then
            s = s:sub(1, CFG.maxLen)
        elseif n > CFG.maxLen then
            s = s:sub(1, utf8.offset(s, CFG.maxLen + 1) - 1)
        end
        return s
    end

    -- ── данные ──
    local Msgs, Order, Seen, Pending, Views = {}, {}, {}, {}, {}
    local seq = 0
    local cursor, primed = "all", false
    local lastOk, lastErr = false, nil
    local bannerOn = true
    local lastClick = 0
    local statusLabel
    local OnLive, AddRow, DropRow -- задаются ниже

    local function Count(m, key)
        local n = 0
        for _ in pairs(m.r[key] or {}) do n += 1 end
        return n
    end

    local function Refresh(mid)
        local vs = Views[mid]
        if not vs then return end
        for i = #vs, 1, -1 do
            if not vs[i]() then table.remove(vs, i) end
        end
    end

    local function ApplyReaction(m, key, uid, on)
        m.r[key] = m.r[key] or {}
        m.r[key][uid] = on and true or nil
    end

    local function SetStatus()
        if not statusLabel then return end
        if not httpReq then
            statusLabel.Text = L("Нет связи: в эксплоите нет http-запросов")
        elseif lastOk then
            statusLabel.Text = string.format(L("Онлайн  ·  сообщений: %d"), #Order)
        else
            statusLabel.Text = L("Нет связи") .. (lastErr and (" (" .. tostring(lastErr) .. ")") or "")
        end
    end

    -- ── приём события ntfy ──
    local function Ingest(ev)
        if Seen[ev.id] then return end
        Seen[ev.id] = true
        local ok, d = pcall(HttpService.JSONDecode, HttpService, tostring(ev.message))
        if not ok or type(d) ~= "table" or d.v ~= 1 then return end

        if ev.topic == CFG.tMsg and d.t == "m" then
            local name, uid = tostring(d.n or ""), tonumber(d.u)
            if name:lower() ~= CFG.admin then return end
            if adminId and uid ~= adminId then return end
            local text = Clean(tostring(d.x or ""))
            if text == "" then return end
            seq += 1
            local m = {
                id = ev.id, name = name, uid = uid or 0, text = text, seq = seq,
                dur = math.clamp(tonumber(d.d) or 12, 4, 60), time = tonumber(ev.time) or os.time(), r = {},
            }
            Msgs[ev.id] = m
            Order[#Order + 1] = ev.id
            for _, p in ipairs(Pending[ev.id] or {}) do ApplyReaction(m, p.k, p.u, p.o) end
            Pending[ev.id] = nil
            AddRow(m)
            while #Order > CFG.keep do
                local old = table.remove(Order, 1)
                DropRow(old)
                Msgs[old], Views[old] = nil, nil
            end
            if primed or (os.time() - m.time) < 30 then OnLive(m) end

        elseif ev.topic == CFG.tReact and d.t == "r" then
            local mid, key, uid = tostring(d.m or ""), tostring(d.e or ""), tonumber(d.u)
            if not uid or not ReactSet[key] then return end
            local on = (d.o == 1)
            local m = Msgs[mid]
            if m then
                ApplyReaction(m, key, uid, on)
                Refresh(mid)
            else
                local list = Pending[mid]
                if not list then list = {}; Pending[mid] = list end
                if #list < 300 then list[#list + 1] = { k = key, u = uid, o = on } end
            end
        end
    end

    -- ── кнопки реакций (используются и в баннере, и в списке) ──
    local function React(m, key)
        if os.clock() - lastClick < 0.35 then return end
        lastClick = os.clock()
        m.r[key] = m.r[key] or {}
        local on = not m.r[key][LP.UserId]
        m.r[key][LP.UserId] = on and true or nil
        Refresh(m.id)
        task.spawn(function()
            local d = Post(CFG.tReact, { v = 1, t = "r", m = m.id, e = key, u = LP.UserId, n = LP.Name, o = on and 1 or 0 })
            if d then Seen[d.id] = true else Notify("Эфир", "Реакция не отправилась") end
        end)
    end

    local MINE_BG = Theme.Accent:Lerp(Theme.Bg, 0.72)
    local function BuildReactions(parent, m)
        local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = parent })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar,
        })
        local btns = {}
        for i, r in ipairs(REACTIONS) do
            local b = New("TextButton", {
                Size = UDim2.new(0, 58, 1, 0), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, AutoButtonColor = false,
                Text = r.e, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, LayoutOrder = i, Parent = bar,
            })
            Corner(b, 8)
            btns[i] = { b = b, st = Stroke(b, Theme.Stroke), r = r }
            b.MouseButton1Click:Connect(function() React(m, r.k) end)
        end
        local function refresh()
            if not bar.Parent then return false end
            for _, x in ipairs(btns) do
                local n = Count(m, x.r.k)
                local mine = m.r[x.r.k] and m.r[x.r.k][LP.UserId]
                x.b.Text = n > 0 and (x.r.e .. " " .. n) or x.r.e
                x.b.BackgroundColor3 = mine and MINE_BG or Theme.Bg
                x.st.Color = mine and Theme.Accent or Theme.Stroke
            end
            return true
        end
        Views[m.id] = Views[m.id] or {}
        table.insert(Views[m.id], refresh)
        refresh()
        return bar
    end

    -- ── баннер сверху экрана (по одному, остальные в очереди) ──
    local Banner = { queue = {}, active = false }
    local function Pump()
        if Banner.active or not Alive then return end
        local m = table.remove(Banner.queue, 1)
        if not m then return end
        Banner.active = true

        local w = math.clamp(SG.AbsoluteSize.X - 24, 260, 520)
        local ok, sz = pcall(function()
            return TextService:GetTextSize(m.text, 13, Enum.Font.Gotham, Vector2.new(w - 28, 10000))
        end)
        local textH = ok and sz.Y or 34
        local h = 50 + textH + 8 + 26 + 14

        local root = New("Frame", {
            Size = UDim2.new(0, w, 0, h), AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, -h - 20), BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0, ZIndex = 60, Parent = SG,
        })
        Corner(root, 12)
        Stroke(root, Theme.StrokeHi, 1)
        New("Frame", {
            Size = UDim2.new(0, 3, 1, -20), Position = UDim2.new(0, 8, 0, 10),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = root,
        })
        local av = New("ImageLabel", {
            Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 20, 0, 10), BackgroundColor3 = Theme.Bg,
            BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. m.uid .. "&w=150&h=150", Parent = root,
        })
        Corner(av, 15)
        Raw(New("TextLabel", {
            Size = UDim2.new(0, w - 120, 0, 16), Position = UDim2.new(0, 58, 0, 9), BackgroundTransparency = 1,
            Text = m.name, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = root,
        }), m.name)
        local okn, nsz = pcall(function()
            return TextService:GetTextSize(m.name, 13, Enum.Font.GothamBold, Vector2.new(400, 20))
        end)
        local pill = New("TextLabel", {
            Size = UDim2.new(0, 42, 0, 14), Position = UDim2.new(0, 58 + math.min(okn and nsz.X or 70, w - 170) + 8, 0, 10),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Text = "ADMIN", TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold, TextSize = 9, Parent = root,
        })
        Corner(pill, 4)
        New("TextLabel", {
            Size = UDim2.new(0, w - 120, 0, 12), Position = UDim2.new(0, 58, 0, 27), BackgroundTransparency = 1,
            Text = L("Глобальное сообщение"), TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = root,
        })
        local closeBtn = New("TextButton", {
            Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -36, 0, 9), BackgroundColor3 = Theme.Bg,
            BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = root,
        })
        Corner(closeBtn, 8)
        local crossBars = {}
        for _, rot in ipairs({ 45, -45 }) do
            local bar = New("Frame", {
                Size = UDim2.new(0, 12, 0, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
                Rotation = rot, BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0, Parent = closeBtn,
            })
            Corner(bar, 1)
            crossBars[#crossBars + 1] = bar
        end
        closeBtn.MouseEnter:Connect(function()
            Tween(closeBtn, 0.12, { BackgroundColor3 = Theme.Danger })
            for _, b in ipairs(crossBars) do Tween(b, 0.12, { BackgroundColor3 = Color3.new(1, 1, 1) }) end
        end)
        closeBtn.MouseLeave:Connect(function()
            Tween(closeBtn, 0.12, { BackgroundColor3 = Theme.Bg })
            for _, b in ipairs(crossBars) do Tween(b, 0.12, { BackgroundColor3 = Theme.TextDim }) end
        end)
        Raw(New("TextLabel", {
            Size = UDim2.new(0, w - 28, 0, textH), Position = UDim2.new(0, 14, 0, 50), BackgroundTransparency = 1,
            Text = m.text, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = root,
        }), m.text)
        local rx = BuildReactions(root, m)
        rx.Position = UDim2.new(0, 14, 0, 50 + textH + 8)
        rx.Size = UDim2.new(1, -28, 0, 26)
        local prog = New("Frame", {
            Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0, Parent = root,
        })

        Tween(root, 0.35, { Position = UDim2.new(0.5, 0, 0, 14) }, Enum.EasingStyle.Quint)

        local closing, hovering = false, false
        local function close()
            if closing then return end
            closing = true
            Tween(root, 0.3, { Position = UDim2.new(0.5, 0, 0, -h - 20) })
            task.delay(0.32, function()
                root:Destroy()
                Banner.active = false
                Pump()
            end)
        end
        root.MouseEnter:Connect(function() hovering = true end)
        root.MouseLeave:Connect(function() hovering = false end)
        closeBtn.MouseButton1Click:Connect(close)
        task.spawn(function()
            local t = 0
            while Alive and not closing and t < m.dur do
                task.wait(0.1)
                if not hovering then t += 0.1 end
                prog.Size = UDim2.new(math.max(0, 1 - t / m.dur), 0, 0, 2)
            end
            if Alive then close() end
        end)
    end

    OnLive = function(m)
        if not bannerOn then
            Notify("Эфир", m.name .. ": " .. m.text)
            return
        end
        table.insert(Banner.queue, m)
        Pump()
    end

    -- ── вкладка ──
    AddSection(page, "Связь")
    statusLabel = AddInfo(page, "Подключение…", 46)
    AddToggle(page, "Баннеры сообщений", "Новые сообщения показываются сверху экрана", true, function(s) bannerOn = s end)

    if isAdmin then
        AddSection(page, "Отправить всем")
        local card = Card(page, 124)
        local box = New("TextBox", {
            Size = UDim2.new(1, -36, 0, 70), Position = UDim2.new(0, 18, 0, 12), BackgroundColor3 = Theme.Bg,
            BorderSizePixel = 0, Text = "", PlaceholderText = L("Текст сообщения для всех…"), PlaceholderColor3 = Theme.TextDim,
            TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            MultiLine = true, ClearTextOnFocus = false, Parent = card,
        })
        Corner(box, 8)
        Stroke(box)
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = box,
        })
        local counter = New("TextLabel", {
            Size = UDim2.new(1, -36, 0, 18), Position = UDim2.new(0, 18, 0, 92), BackgroundTransparency = 1,
            Text = "0 / " .. CFG.maxLen, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
        })
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local n = utf8.len(box.Text) or #box.Text
            counter.Text = n .. " / " .. CFG.maxLen
            counter.TextColor3 = n > CFG.maxLen and Theme.Danger or Theme.TextDim
        end)
        OnLang(function() box.PlaceholderText = L("Текст сообщения для всех…") end)

        local dur = 15
        AddSegmented(page, "Время показа", { "8 с", "15 с", "30 с" }, 2, function(i) dur = ({ 8, 15, 30 })[i] end)

        local sending, lastSend = false, 0
        AddButton(page, "Отправить всем", Theme.Accent, function()
            if sending or os.clock() - lastSend < 2 then return end
            local raw = box.Text
            if (utf8.len(raw) or #raw) > CFG.maxLen then Notify("Эфир", "Слишком длинное сообщение"); return end
            local text = Clean(raw)
            if text == "" then Notify("Эфир", "Введи текст сообщения"); return end
            if not httpReq then Notify("Эфир", "В эксплоите нет http-запросов"); return end
            sending = true
            task.spawn(function()
                local payload = { v = 1, t = "m", n = LP.Name, u = LP.UserId, x = text, d = dur }
                local d, err = Post(CFG.tMsg, payload, true)
                sending = false
                if not d then
                    Notify("Эфир", L("Не отправлено: ") .. tostring(err))
                    return
                end
                lastSend = os.clock()
                box.Text = ""
                Ingest({ id = d.id, topic = CFG.tMsg, time = d.time, message = HttpService:JSONEncode(payload) })
                Notify("Эфир", "Отправлено всем")
            end)
        end)
    end

    AddSection(page, "Сообщения")
    local Holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page,
    })
    New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Holder })
    local Empty = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "Пока сообщений нет", TextColor3 = Theme.TextDim,
        Font = Enum.Font.Gotham, TextSize = 12, LayoutOrder = 1000000, Parent = Holder,
    })
    local Rows = {}

    AddRow = function(m)
        local row = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0, LayoutOrder = -m.seq, Parent = Holder,
        })
        if Theme.Cards then Theme.Cards[row] = true end
        Corner(row, 10)
        Stroke(row, Theme.Stroke)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = row,
        })
        New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

        local head = New("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 1, Parent = row })
        local av = New("ImageLabel", {
            Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. m.uid .. "&w=150&h=150", Parent = head,
        })
        Corner(av, 12)
        Raw(New("TextLabel", {
            Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 32, 0, 0), BackgroundTransparency = 1,
            Text = m.name, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
        }), m.name)
        New("TextLabel", {
            Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -80, 0, 0), BackgroundTransparency = 1,
            Text = os.date("%H:%M", m.time), TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right, Parent = head,
        })
        Raw(New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            Text = m.text, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Parent = row,
        }), m.text)
        BuildReactions(row, m).LayoutOrder = 3
        Rows[m.id] = row
        Empty.Visible = false
    end

    DropRow = function(mid)
        local row = Rows[mid]
        if row then row:Destroy() end
        Rows[mid] = nil
        Empty.Visible = next(Rows) == nil
    end

    OnLang(SetStatus)
    SetStatus()

    -- ── опрос ──
    local function PollOnce()
        local url = string.format("%s/%s,%s/json?poll=1&since=%s", CFG.base, CFG.tMsg, CFG.tReact, tostring(cursor))
        local res, err = Http("GET", url, nil, { Accept = "application/x-ndjson" })
        if not res then return false, err end
        local code = CodeOf(res)
        if code ~= 200 then
            if cursor == "all" and (code == 400 or code == 429) then cursor = "1h" end
            return false, "HTTP " .. tostring(code), code
        end
        local maxT = 0
        local evs = {}
        for line in BodyOf(res):gmatch("[^\r\n]+") do
            local ok, ev = pcall(HttpService.JSONDecode, HttpService, line)
            if ok and type(ev) == "table" and ev.event == "message" and ev.id then
                evs[#evs + 1] = ev
                local t = tonumber(ev.time) or 0
                if t > maxT then maxT = t end
            end
        end
        for _, ev in ipairs(evs) do pcall(Ingest, ev) end
        if maxT > 0 then cursor = maxT end
        primed = true
        return true
    end

    task.spawn(function()
        local backoff = 0
        while Alive do
            local ok, err, code = PollOnce()
            if ok then
                lastOk, lastErr, backoff = true, nil, 0
            else
                lastOk, lastErr = false, err
                backoff = (code == 429) and 20 or math.min(backoff + 5, 30)
            end
            pcall(SetStatus)
            local waited = 0
            while Alive and waited < CFG.poll + backoff do
                task.wait(0.5)
                waited += 0.5
            end
        end
    end)
end
InitBroadcast(Tabs["Эфир"].Page)
end

-- ═══════════════ СТАРТ ═══════════════
SelectTab("Основное")
Persist.apply() -- применяем сохранённые настройки
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
