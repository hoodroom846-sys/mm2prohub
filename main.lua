--[[
    MM2 PRO HUB v4.2  |  один файл: проверка ключа + скрипт
    Ключ проверяется прямо в скрипте: его последние 6 символов должны быть в списке KEY_ENDINGS.
    Готовый файл со списком окончаний выдаёт бот командой /script; ключи создаёт бот командой /genkey.
    v4.9: Teleport — быстрые прыжки вместо одного скачка на всю карту: длина прыжка ограничена скоростью (слайдер «Скорость Teleport», по умолчанию
          400 стад/с: 100 стад ≈ 0,25 с; 1500 кикало, 60 было «ездой»). Тумблер «Мгновенно» возвращает поведение v4.8 (без ограничения).
          На монете встаём, когда долетели. В журнал киков и диагностику добавлена скорость Teleport.
    v4.8: Teleport — касание КАЖДЫЙ кадр, пока стоим на монете (как в подборе пистолета); предохранитель 0.8 с вместо 2 с;
          если все найденные монеты временно пропущены — пропуски снимаются (не «ищет вечно»); откат сервера внутри карты не считается «унесло»;
          в диагностике фарма — фаза/попытки Teleport и есть ли firetouchinterest. ESP — роли с сервера (GetPlayerData), видны сразу при выдаче.
    v4.7: фикс Teleport: после первой собранной монеты флаг фазы оставался «на монете» и блокировал выбор следующей (писало «свободных монет нет», хотя монеты найдены).
    v4.6: Teleport — настоящий телепорт сразу на монету (без ограничения длины прыжка, без пауз); Touch — скорость всегда 24 (слайдера нет).
    v4.5: Auto-Farm — Teleport без пауз и таймеров (прямой телепорт к монете, прыжок ≤ State.TpHop за кадр, стоим на монете до её исчезновения);
          безопасные значения по умолчанию (скорость Touch 16, прыжок 25); журнал киков mm2prohub_kicklog.txt.
    v4.4: поиск по функциям (строка в шапке страницы), ★ избранное у тумблеров, закрепление любого тумблера экранной кнопкой;
          Auto-Farm берёт число монет из GUI игры (счётчик находится сам по калибровке), лимит — из «n/m» либо 40.
    RightShift — скрыть/показать окно хаба (v4.3: экранные кнопки в Настройках) (свёрнутый хаб — док у левого края, его можно тянуть). Язык: по умолчанию English, переключатель в Настройках. Fly: WASD + Space / LeftShift. Клик/клавиша в интро — пропустить.
]]

local BOT_LINK   = "https://t.me/BYSHEB_bot" -- всегда бот BYSHEB_bot (ссылка «Получить ключ»)

-- Announce: рассылка объявлений всем, кто запустил скрипт (прошёл проверку ключа), и реакции на них (👍 ❤️ 🔥 😂).
-- Свой сервер не нужен: канал — публичный топик ntfy.sh (бесплатный pub/sub). Владелец публикует событие в топик, все клиенты раз в ANNOUNCE_POLL с
-- читают его. Реакции — тоже события в этом топике. Принимается ТОЛЬКО текст (никакой код не выполняется).
-- Токена нет. Топик указан прямо в скрипте, поэтому писать в него технически может любой, кто его откроет: ANNOUNCE_TOPIC держите длинным и случайным.
-- Реакции считаются по userId, который присылает клиент, поэтому подделать их можно; для рассылки в игре это допустимо.
local ANNOUNCE_OWNER  = "heh666145"
local ANNOUNCE_HOST   = "https://ntfy.sh"
local ANNOUNCE_TOPIC  = "mm2prohub-ann-x7k2q9f4m1c8"
local ANNOUNCE_POLL   = 10   -- как часто клиент проверяет объявления, секунд (не меньше 5)
local ANNOUNCE_MAXLEN = 400
local KEY_FILE   = "mm2prohub_key.txt" -- сюда запоминается введённый ключ (если эксплоит умеет writefile)

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

local Theme = {
    Bg = Color3.fromRGB(18, 18, 20), Surface = Color3.fromRGB(26, 26, 29), Surface2 = Color3.fromRGB(34, 34, 38),
    Border = Color3.fromRGB(46, 46, 52), Accent = Color3.fromRGB(226, 118, 48), Text = Color3.fromRGB(235, 233, 228),
    TextDim = Color3.fromRGB(140, 138, 134), Danger = Color3.fromRGB(208, 72, 72), Good = Color3.fromRGB(96, 192, 124),
}

-- ═══════════════ ЯЗЫК (по умолчанию английский) ═══════════════
-- Тексты в коде написаны по-русски и служат ключами. Lang = "en" -> L() отдаёт перевод из LangEN (нет перевода — исходный текст), "ru" -> как есть.
-- Выбор языка запоминается в файле LANG_FILE (если эксплоит умеет writefile/readfile), иначе при каждом запуске снова английский.
local LANG_FILE = "mm2prohub_lang.txt"
local Lang = "en"
pcall(function()
    if isfile and readfile and isfile(LANG_FILE) then
        local v = readfile(LANG_FILE)
        if v:find("ru", 1, true) then Lang = "ru" end
    end
end)
local LangEN = {
    ["Фарм выкл"] = "Farm off",
    ["Привет, "] = "Hi, ",
    ["RightShift — скрыть / показать окно"] = "RightShift — hide / show window",
    ["Включено"] = "Enabled",
    ["Выключено"] = "Disabled",
    ["Основное"] = "Main",
    ["Движение и бой"] = "Movement and combat",
    ["Визуал"] = "Visuals",
    ["Подсветка игроков"] = "Player highlights",
    ["Фарм"] = "Farm",
    ["Автосбор монет и конфет"] = "Auto-collect coins and candy",
    ["Статистика"] = "Stats",
    ["Итоги этой сессии"] = "This session's results",
    ["Настройки"] = "Settings",
    ["Интерфейс и сессия"] = "Interface and session",
    ["Движение"] = "Movement",
    ["Переопределяет WalkSpeed"] = "Overrides WalkSpeed",
    ["Скорость"] = "Speed",
    ["Fly (Полёт)"] = "Fly",
    ["WASD + Space вверх / Shift вниз"] = "WASD + Space up / Shift down",
    ["Скорость Fly"] = "Fly speed",
    ["Бой"] = "Combat",
    ["Авто-подбор пистолета"] = "Auto gun pickup",
    ["Невидимка"] = "Invisibility",
    ["Тело далеко за картой, ты управляешь полупрозрачной копией. Выкл: тело встанет на место копии"] = "Your body is far behind the map; you control a semi-transparent copy. Off: body moves to the copy's place",
    ["Нет живого персонажа"] = "No living character",
    ["Копию создать не удалось"] = "Could not create the copy",
    ["Шериф умер: на миг телепорт к пистолету и обратно (только в раунде). Зажми G — турбо"] = "Sheriff died: briefly teleports to the gun and back (round only). Hold G for turbo",
    ["Пока без логики, как в исходнике"] = "No logic yet, same as the original",
    ["Игроки"] = "Players",
    ["ESP Игроков (Роли)"] = "Player ESP (Roles)",
    ["Автоматизация"] = "Automation",
    ["Под картой, монеты находит сам. Лобби и смерть — выкл."] = "Under the map, finds coins by itself. Lobby and death: off.",
    ["Режим фарма"] = "Farm mode",
    ["Скорость Teleport, стад/с"] = "Teleport speed, studs/s",
    ["Teleport: мгновенно"] = "Teleport: instant",
    ["Скорость Teleport снижена до %d (кик по позиции)"] = "Teleport speed lowered to %d (position kick)",
    ["Скорость Teleport на минимуме: причина кика, видимо, не в длине прыжка"] = "Teleport speed is already at the minimum: the kick is probably not about jump length",
    ["Прыжок на всю карту за кадр, как в v4.8 (в этом режиме кикало)"] = "Whole-map jump in one frame, as in v4.8 (this got kicked)",
    ["Ресет после 40 монет"] = "Reset after 40 coins",
    ["Собрал 40 — ресет и ждём следующий раунд. Выкл: собирает без лимита"] = "Collected 40: reset and wait for the next round. Off: collects with no limit",
    ["Скорость полёта"] = "Flight speed",
    ["Teleport: длина прыжка, стадов"] = "Teleport: jump length, studs",
    ["Teleport: пауза между монетами, мс"] = "Teleport: pause between coins, ms",
    ["Старт отсчёта"] = "Countdown start",
    ["Выдача роли"] = "Role handout",
    ["Появление монет"] = "Coins appear",
    ["Ожидание перед фармом"] = "Wait before farming",
    ["0 с"] = "0 s",
    ["6 с"] = "6 s",
    ["12 с"] = "12 s",
    ["18 с"] = "18 s",
    ["Анти-АФК"] = "Anti-AFK",
    ["Не выкидывает с сервера за бездействие"] = "Prevents idle kick from the server",
    ["Диагностика"] = "Diagnostics",
    ["Статус: выключено"] = "Status: off",
    ["Монеты: ищем объекты с именем Coin / Candy (учитывается Collected)"] = "Coins: looking for objects named Coin / Candy (Collected is respected)",
    ["Монеты в раунде"] = "Coins this round",
    ["Фарм: пауза"] = "Farm: paused",
    ["Фарм "] = "Farm ",
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
    ["интерфейс"] = "interface",
    ["карта и монеты"] = "map and coins",
    ["роли и ESP"] = "roles and ESP",
    ["автофарм"] = "autofarm",
    ["Загружен. RightShift: скрыть/показать"] = "Loaded. RightShift: hide/show",
    ["удалена"] = "removed",
    ["прозрачность"] = "transparency",
    ["сдвинута"] = "moved",
    ["стоимость"] = "cost",
    ["Монеты кончились: жду"] = "Out of coins: waiting",
    ["Унесло с карты: жду следующий раунд"] = "Fell off the map: waiting for the next round",
    ["40 монет: ресет"] = "40 coins: reset",
    [" (дубль)"] = " (duplicate)",
    [" (не наша)"] = " (not ours)",
    ["%s   |   монета: %.0f, %.0f, %.0f   |   до неё: %.0f"] = "%s   |   coin: %.0f, %.0f, %.0f   |   to it: %.0f",
    ["Телепорт к монете"] = "Teleport to coin",
    ["За картой"] = "Behind the map",
    ["Голова вверх"] = "Head up",
    ["Лёжа под картой"] = "Lying under the map",
    ["Старт раунда: ждём %.0f с (лёжа под полом)"] = "Round start: waiting %.0f s (lying under the floor)",
    ["Раунд идёт, свободных монет нет"] = "Round in progress, no free coins",
    ["Не в раунде (умер / в лобби): ждём следующий"] = "Not in round (dead / lobby): waiting for the next one",
    ["Монеты есть, но ты не на карте (лобби): не фармим"] = "Coins exist but you are not on the map (lobby): not farming",
    ["Лобби: ждём выдачу ролей"] = "Lobby: waiting for role handout",
    ["Лобби: ждём появление монет"] = "Lobby: waiting for coins to appear",
    ["Монет найдено: %d   ·   Собрано: %d/%d   ·   Признак раунда: %s   ·   Ты на карте: %s   ·   Зачёт: %s"] = "Coins found: %d   ·   Collected: %d/%d   ·   Round signal: %s   ·   On map: %s   ·   Counted: %s",
    ["да"] = "yes",
    ["нет"] = "no",
    ["   ·   Похожие объекты: "] = "   ·   Similar objects: ",
    ["Собираю монеты"] = "Collecting coins",
    ["Старт раунда…"] = "Round starting…",
    ["Монет нет"] = "No coins",
    ["Ждём новый раунд"] = "Waiting for a new round",
    ["Не на карте"] = "Not on map",
    ["Ждём раунд"] = "Waiting for round",
    ["Мёртв / нет персонажа: фарм отключён"] = "Dead / no character: farm disabled",
    ["Мёртв / нет персонажа"] = "Dead / no character",
    ["Авто-подбор"] = "Auto pickup",
    ["Пистолет: попытка "] = "Gun: attempt ",
    ["Неверный формат ключа"] = "Invalid key format",
    ["Ключ недействителен"] = "Key is not valid",
    ["Ключ принят"] = "Key accepted",
    ["PRO HUB  ·  Активация"] = "PRO HUB  ·  Activation",
    ["КЛЮЧ ДОСТУПА"] = "ACCESS KEY",
    ["Вставь ключ из Telegram-бота"] = "Paste the key from the Telegram bot",
    ["Активировать"] = "Activate",
    ["Получить ключ (ссылка на бота)"] = "Get a key (bot link)",
    ["Ссылка скопирована: "] = "Link copied: ",
    ["Введи ключ"] = "Enter a key",
    ["В скрипте нет окончаний ключей: возьми готовый файл у бота (команда /script)"] = "This script has no key endings: get the ready-made file from the bot (/script command)",
    ["Проверка…"] = "Checking…",
    ["Ошибка проверки: "] = "Check error: ",
    ["Проверяю сохранённый ключ…"] = "Checking the saved key…",
    ["Нажми, чтобы открыть"] = "Tap to open",
    ["Рассылка"] = "Announce",
    ["Клиенты проверяют канал раз в %d с"] = "Clients check the channel every %d s",
    ["Сообщение для всех, кто запустил скрипт"] = "A message for everyone running this script",
    ["Объявление"] = "Announcement",
    ["Сообщение"] = "Message",
    ["Текст объявления…"] = "Announcement text…",
    ["Предпросмотр"] = "Preview",
    ["Отправить всем"] = "Send to everyone",
    ["Введи текст"] = "Enter a message",
    ["Сервер не настроен"] = "Server is not configured",
    ["Подожди несколько секунд"] = "Wait a few seconds",
    ["Отправлено"] = "Sent",
    ["Не отправлено: "] = "Not sent: ",
    ["Клиенты проверяют сервер раз в %d с"] = "Clients check the server every %d s",
    ["Реакции последнего объявления: "] = "Reactions on the latest announcement: ",
    ["Реакция"] = "Reaction",
    ["Экранные кнопки"] = "On-screen buttons",
    ["Показать кнопку на экране"] = "Show a button on screen",
    ["Инвиз"] = "Invis",
    ["Полёт"] = "Flight",
    ["Избранное"] = "Favorites",
    ["Последний кик: "] = "Last kick: ",
    ["не записано"] = "none recorded",
    ["Последний кик"] = "Last kick",
    ["Закрепить"] = "Pin",
    ["Закреплено"] = "Pinned",
    ["Открыть"] = "Open",
    ["Ничего не найдено"] = "Nothing found",
    ["Нажми ☆ у любого тумблера, чтобы добавить его в избранное. Здесь его можно закрепить кнопкой на экране."] = "Tap ☆ on any toggle to add it to favorites. You can pin it here as an on-screen button.",
    ["Счётчик монет в GUI: "] = "Coin counter in GUI: ",
    ["калибруется: нужно 3 собранные монеты"] = "calibrating: needs 3 collected coins",
    ["монет: ресет"] = "coins: reset",
    ["Счётчик монет в GUI найден"] = "Coin counter found in GUI",
}
local function L(s)
    if Lang == "ru" then return s end
    return LangEN[s] or s
end
-- обратные таблицы для смены языка «на лету»: любой показанный текст (RU / EN / EN заглавными) -> русский ключ
local LangReverse, LangPrefixes = {}, {}
for ru, en in pairs(LangEN) do
    LangReverse[ru] = ru
    LangReverse[en] = ru
    LangReverse[en:upper()] = ru
    if ru:sub(-1) == " " and #ru >= 3 and ru:sub(1, 1) ~= " " then LangPrefixes[#LangPrefixes + 1] = { ru = ru, en = en } end
end
table.sort(LangPrefixes, function(a, b) return #a.ru > #b.ru end)

local function New(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end
    if props.Parent then o.Parent = props.Parent end
    return o
end
local function Corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = p }) end
local function Stroke(p, c, t)
    return New("UIStroke", { Color = c or Theme.Border, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
end
local function Tween(o, t, props, style)
    TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- ═══════════════ ИКОНКА (PNG через writefile, иначе блоками) ═══════════════
local LOGO_B64 = "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"

local PIXEL_LOGO = { n = 56, pal = {{0,0,0}, {52,52,54}, {150,150,156}, {128,40,224}, {178,72,200}, {232,118,48}, {214,170,72}, {235,235,240}}, rows = {
    "",
    "",
    "",
    "",
    "1:25:5",
    "1:25:5",
    "1:25:4",
    "1:26:3",
    "1:26:4",
    "1:25:5",
    "3:25:4,1:29:1",
    "1:23:1,3:24:6,1:30:1",
    "1:22:1,3:23:9,1:32:1",
    "1:21:1,3:22:12,1:34:1",
    "1:19:1,3:20:9,1:29:2,3:31:4,1:35:1",
    "1:18:1,3:19:9,1:28:2,1:31:1,3:32:5,1:37:1",
    "1:17:1,3:18:9,1:27:3,3:32:6,1:38:1",
    "1:16:1,3:17:9,1:26:4,1:32:1,3:33:6,1:39:1",
    "3:17:8,1:25:8,3:33:6,1:39:1",
    "1:17:1,3:18:5,1:23:3,2:26:2,1:28:2,2:30:1,6:31:1,2:32:1,3:33:6,1:39:1",
    "1:18:1,3:19:3,1:22:1,1:24:9,3:33:6,1:39:1",
    "1:20:1,1:25:6,1:32:1,3:33:6",
    "1:25:6,1:32:1,3:33:6",
    "1:24:8,3:32:6,1:38:1",
    "1:24:6,2:30:2,3:32:6,1:38:1",
    "1:24:6,2:30:2,4:32:5,1:37:1",
    "1:24:6,2:30:2,4:32:5,1:37:1",
    "1:24:6,2:30:2,4:32:4,1:36:1",
    "1:24:7,2:31:1,4:32:3,1:35:1",
    "1:24:7,2:31:1,4:32:2,1:34:1",
    "1:24:7,2:31:1,4:32:1,1:33:1",
    "1:24:7,2:31:1",
    "1:24:8",
    "1:23:9",
    "1:22:1,5:23:1,1:24:9",
    "1:21:1,5:22:2,1:24:9",
    "1:20:1,5:21:2,1:23:10",
    "1:19:1,5:20:2,1:22:1,1:24:9",
    "1:18:1,5:19:2,1:21:1,1:24:2,5:26:9,1:35:2",
    "5:18:3,1:21:1,5:22:16,1:38:2",
    "1:17:1,5:18:21,1:39:1",
    "1:16:1,5:17:21,1:38:1",
    "1:16:1,5:17:20,1:37:1",
    "5:16:6,1:22:7,5:29:8",
    "5:16:1,1:17:2,1:25:4,2:29:3,1:33:1,5:34:2",
    "1:25:3,2:28:3",
    "1:25:2,2:27:1,7:28:2,1:30:1",
    "1:25:1,2:26:2,7:28:1,2:29:1",
    "1:24:1,2:25:4",
    "1:24:1,2:25:3",
    "1:24:1,2:25:1,1:26:1",
    "1:24:2",
    "",
    "",
    "",
    ""
} }

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
local LogoAsset
do
    local ok, asset = pcall(function()
        local get = getcustomasset or getsynasset
        if not (writefile and get) then error("no file api") end
        writefile("mm2prohub_logo_v4.png", B64Decode(LOGO_B64))
        return get("mm2prohub_logo_v4.png")
    end)
    if ok and asset and asset ~= "" then LogoAsset = asset end
end
local function BuildLogo(parent, radius)
    parent.BackgroundColor3 = Color3.new(0, 0, 0)
    parent.BackgroundTransparency = 0
    parent.ClipsDescendants = true
    if LogoAsset then
        local img = New("ImageLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = LogoAsset,
            ScaleType = Enum.ScaleType.Fit, Parent = parent,
        })
        if radius then Corner(img, radius) end
    else
        local n = PIXEL_LOGO.n
        for y, row in ipairs(PIXEL_LOGO.rows) do
            if row ~= "" then
                for c, x, l in row:gmatch("(%d+):(%d+):(%d+)") do
                    local p = PIXEL_LOGO.pal[tonumber(c) + 1]
                    New("Frame", {
                        Size = UDim2.new(tonumber(l) / n + 0.002, 0, 1 / n + 0.002, 0),
                        Position = UDim2.new(tonumber(x) / n, 0, (y - 1) / n, 0),
                        BackgroundColor3 = Color3.fromRGB(p[1], p[2], p[3]), BorderSizePixel = 0, Parent = parent,
                    })
                end
            end
        end
    end
end

-- ═══════════════ PRO HUB (запускается только после принятия ключа) ═══════════════
local function RunHub()
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

-- ═══════════════ ТЕМА (матовая, плоская) ═══════════════
local Theme = {
    Bg       = Color3.fromRGB(18, 18, 20),
    Sidebar  = Color3.fromRGB(14, 14, 16),
    Surface  = Color3.fromRGB(26, 26, 29),
    Surface2 = Color3.fromRGB(34, 34, 38),
    Border   = Color3.fromRGB(46, 46, 52),
    Accent   = Color3.fromRGB(226, 118, 48),
    AccentHi = Color3.fromRGB(242, 160, 100),
    Text     = Color3.fromRGB(235, 233, 228),
    TextDim  = Color3.fromRGB(140, 138, 134),
    Danger   = Color3.fromRGB(208, 72, 72),
    Good     = Color3.fromRGB(96, 192, 124),
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
    FarmFlySpeed = 24,     -- Touch: скорость полёта, всегда 24 (слайдера нет)
    TpSpeed = 400,         -- Teleport: максимум стад/с при прыжках к монете и под пол (слайдер на вкладке «Фарм»)
    TpInstant = false,     -- Teleport: true = без ограничения длины прыжка (как v4.8)
    FarmHideDepth = 3,   -- на сколько стадов ниже пола лежим
    FarmStartDelay = 0,  -- сколько секунд после старта раунда ждём, прежде чем лететь за монетами
    FarmTrigger = "coins", -- что считать стартом раунда: "role" (выдача ролей) или "coins" (появление монет)
    FlySpeed = 50,
    Aimbot = false,
}

-- Авто-подбор скорости Teleport: скрипт сам читает свой журнал киков (mm2prohub_kicklog.txt). Если последний кик новый и в нём
-- есть «position» или «teleport», скорость Teleport делится пополам (минимум 100) и запоминается в mm2prohub_tpspeed.txt.
-- Нужны isfile/readfile/writefile (те же, что для журнала киков); без них скорость задаётся только слайдером.
do
    local SPEED_FILE, LOG_FILE = "mm2prohub_tpspeed2.txt", "mm2prohub_kicklog.txt"
    State.SaveTp = function()
        pcall(function()
            if writefile then writefile(SPEED_FILE, tostring(State.TpSpeed) .. "\n" .. (State.TpDoneLine or "")) end
        end)
    end
    pcall(function()
        if not (isfile and readfile) then return end
        if isfile(SPEED_FILE) then
            local t = readfile(SPEED_FILE)
            local saved = tonumber(t:match("^%s*(%d+)"))
            if saved then State.TpSpeed = math.clamp(saved, 100, 5000) end
            State.TpDoneLine = t:match("\n([^\n]+)")
        end
        if not isfile(LOG_FILE) then return end
        local last
        for ln in readfile(LOG_FILE):gmatch("[^\n]+") do last = ln end
        if not last or last == State.TpDoneLine then return end
        State.TpDoneLine = last
        -- проверяем только текст сообщения игры (до « | autofarm=»), иначе слово teleport найдётся в method=teleport при любом кике
        local msg = last:match("^%[[^%]]*%]%s*(.-)%s*|%s*autofarm=") or (last:gsub("method=%w+", ""))
        local low = msg:lower()
        local sp = tonumber(last:match("tpSpeed=(%d+)"))
        if sp and (low:find("position", 1, true) or low:find("teleport", 1, true)) then
            local lowered = math.max(100, math.min(State.TpSpeed, math.floor(sp / 2)))
            if lowered < State.TpSpeed then
                State.TpSpeed = lowered
                State.TpAutoNote = "lowered"
                State.SaveTp()
            elseif sp <= 200 then
                State.TpAutoNote = "min"
                State.SaveTp()
            end
        end
    end)
end

local Stats = { coins = 0, rounds = 0, resets = 0, t0 = os.clock() } -- статистика сессии

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
    if props.Parent then o.Parent = props.Parent end
    return o
end

local function Corner(p, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = p })
end

local function Stroke(p, color, t)
    return New("UIStroke", {
        Color = color or Theme.Border,
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

-- иконка (LogoAsset / BuildLogo) берётся из начала файла

-- ═══════════════ ОПРЕДЕЛЕНИЕ РОЛЕЙ (ESP) ═══════════════
-- Источник ролей с сервера: RemoteFunction «GetPlayerData» (если она есть в игре). Даёт роли сразу при выдаче, не дожидаясь,
-- пока нож/пистолет окажется в руках. ВАЖНО: формат ответа взят из твоего прошлого файла и здесь НЕ проверен;
-- всё под pcall: если RemoteFunction нет или формат другой, остаётся прежний способ (оружие в руках / рюкзаке).
local ServerRoles, ServerIn, ServerNext, ServerBusy = {}, {}, 0, false -- ServerIn[имя] = игрок участвует в раунде
local function RefreshServerRoles()
    if ServerBusy or os.clock() < ServerNext then return end
    ServerNext = os.clock() + 1
    ServerBusy = true
    task.spawn(function()
        pcall(function()
            local rf = game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true)
            if not (rf and rf:IsA("RemoteFunction")) then return end
            local data = rf:InvokeServer()
            if type(data) ~= "table" then return end
            local out, inn = {}, {}
            for name, info in pairs(data) do
                if type(name) == "string" and type(info) == "table" and type(info.Role) == "string" then
                    local r = info.Role:lower()
                    if r == "murderer" then out[name] = "Murderer"; inn[name] = true
                    elseif r == "sheriff" or r == "hero" then out[name] = "Sheriff"; inn[name] = true
                    elseif r == "innocent" then inn[name] = true end
                end
            end
            ServerRoles, ServerIn = out, inn
        end)
        ServerBusy = false
    end)
end

local function GetRole(p)
    RefreshServerRoles()
    if not p then return "Innocent" end
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
local Invis = { on = false } -- невидимка: функции объявлены ниже, в разделе «НЕВИДИМКА»
local ESPZone = { lo = nil, hi = nil, m = 25 } -- рамка монет раунда: кто внутри неё — «в раунде», остальные — «в лобби»
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

-- ═══════════════ УВЕДОМЛЕНИЯ ═══════════════
local ToastHolder = New("Frame", {
    Size = UDim2.new(0, 290, 1, -24), Position = UDim2.new(1, -302, 0, 12),
    BackgroundTransparency = 1, ZIndex = 50, Parent = SG,
})
New("UIListLayout", {
    Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder, Parent = ToastHolder,
})
local ToastN = 0

local function Notify(title, text)
    ToastN += 1
    local slot = New("Frame", {
        Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = ToastN, ZIndex = 50, Parent = ToastHolder,
    })
    local t = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1, 40, 0, 0), BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0, ZIndex = 50, Parent = slot,
    })
    Corner(t, 6)
    Stroke(t, Theme.Border)
    New("Frame", {
        Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 6, 0, 6), BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0, ZIndex = 51, Parent = t,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -30, 0, 18), Position = UDim2.new(0, 20, 0, 8), BackgroundTransparency = 1,
        Text = title, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 51, Parent = t,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -30, 0, 16), Position = UDim2.new(0, 20, 0, 28), BackgroundTransparency = 1,
        Text = text, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 51, Parent = t,
    })
    Tween(t, 0.3, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
    task.delay(2.5, function()
        if not t.Parent then return end
        Tween(t, 0.25, { Position = UDim2.new(1, 40, 0, 0) })
        task.wait(0.27)
        slot:Destroy()
    end)
end

-- ═══════════════ HUD АВТОФАРМА (виден, пока Auto-Farm включён, даже если окно скрыто) ═══════════════
local H = {}
local HUD = New("Frame", {
    Name = "HUD", Size = UDim2.new(0, 300, 0, 50), AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 12), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
    Visible = false, ZIndex = 5, Parent = SG,
})
Corner(HUD, 8)
Stroke(HUD, Theme.Border)
H.Dot = New("Frame", {
    Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Theme.AccentHi,
    BorderSizePixel = 0, ZIndex = 6, Parent = HUD,
})
Corner(H.Dot, 4)
H.Title = New("TextLabel", {
    Size = UDim2.new(1, -100, 0, 16), Position = UDim2.new(0, 30, 0, 10), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = HUD,
})
H.Count = New("TextLabel", {
    Size = UDim2.new(0, 56, 0, 16), Position = UDim2.new(1, -70, 0, 10), BackgroundTransparency = 1, Text = "0/40",
    TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 6, Parent = HUD,
})
H.Track = New("Frame", {
    Size = UDim2.new(1, -28, 0, 4), Position = UDim2.new(0, 14, 1, -14), BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0, ZIndex = 6, Parent = HUD,
})
Corner(H.Track, 2)
H.Fill = New("Frame", {
    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 7, Parent = H.Track,
})
Corner(H.Fill, 2)

-- ═══════════════ ГЛАВНОЕ ОКНО ═══════════════
local function FitScale()
    local vp = SG.AbsoluteSize
    if vp.X < 1 or vp.Y < 1 then return 1 end
    return math.clamp(math.min(vp.X / 820, vp.Y / 580), 0.5, 1)
end
local BaseScale = FitScale()

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 760, 0, 520),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    Visible = false, -- покажет интро
    Parent = SG,
})
Corner(Main, 8)
Stroke(Main, Theme.Border)
local MainScale = New("UIScale", { Scale = BaseScale * 0.96, Parent = Main })

New("ImageLabel", { -- мягкая тень
    Size = UDim2.new(1, 50, 1, 50), Position = UDim2.new(0, -25, 0, -25),
    BackgroundTransparency = 1, Image = "rbxassetid://6014261993",
    ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
    ZIndex = 0, Parent = Main,
})

-- ═══════════════ ЗАГОЛОВОК ОКНА ═══════════════
local TitleBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = Main,
})
Corner(TitleBar, 8)
New("Frame", { -- прячет нижние скругления заголовка
    Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0, Parent = TitleBar,
})
New("Frame", { -- линия под заголовком
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0, Parent = TitleBar,
})
do
    local icon = New("Frame", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 12, 0, 7), BorderSizePixel = 0, Parent = TitleBar })
    Corner(icon, 6)
    BuildLogo(icon, 6)
    New("TextLabel", {
        Size = UDim2.new(0, 220, 0, 16), Position = UDim2.new(0, 50, 0, 6), BackgroundTransparency = 1,
        Text = "MURDER MYSTERY 2", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBar,
    })
    New("TextLabel", {
        Size = UDim2.new(0, 320, 0, 12), Position = UDim2.new(0, 50, 0, 23), BackgroundTransparency = 1,
        Text = "PRO HUB  ·  v4.2  ·  by shebx436", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBar,
    })
end

local function WindowButton(text, xOffset, hoverColor)
    local b = New("TextButton", {
        Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, xOffset, 0.5, -12),
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false,
        Text = text, TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 14, Parent = TitleBar,
    })
    Corner(b, 5)
    Connect(b.MouseEnter, function() Tween(b, 0.12, { BackgroundColor3 = hoverColor, TextColor3 = Theme.Text }) end)
    Connect(b.MouseLeave, function() Tween(b, 0.12, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextDim }) end)
    return b
end
local MinBtn   = WindowButton("–", -70, Theme.Surface2)
local CloseBtn = WindowButton("×", -38, Theme.Danger)

-- Перетаскивание окна (за заголовок)
do
    local dragging, dragStart, startPos = false, nil, nil
    Connect(TitleBar.InputBegan, function(i)
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

-- ═══════════════ ВЕРХНЯЯ ПАНЕЛЬ ВКЛАДОК ═══════════════
local TAB_BAR_Y, TAB_BAR_H, FOOT_H = 43, 40, 34
local TabBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, TAB_BAR_H), Position = UDim2.new(0, 0, 0, TAB_BAR_Y),
    BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = Main,
})
New("Frame", { -- нижняя линия панели
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0, ZIndex = 2, Parent = TabBar,
})
local TabList = New("Frame", { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Parent = TabBar })
New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabList })

-- ═══════════════ НИЖНЯЯ СТАТУС-ПАНЕЛЬ ═══════════════
local ChipText, ChipDot, FpsLabel
do
    local foot = New("Frame", {
        Size = UDim2.new(1, 0, 0, FOOT_H), Position = UDim2.new(0, 0, 1, -FOOT_H), BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0, Parent = Main,
    })
    Corner(foot, 8)
    New("Frame", { -- прячет верхние скругления панели
        Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = foot,
    })
    New("Frame", { -- верхняя линия
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = foot,
    })
    ChipDot = New("Frame", { -- статус фарма
        Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 16, 0.5, -4), BackgroundColor3 = Theme.TextDim,
        BorderSizePixel = 0, Parent = foot,
    })
    Corner(ChipDot, 4)
    ChipText = New("TextLabel", {
        Size = UDim2.new(0, 190, 1, 0), Position = UDim2.new(0, 32, 0, 0), BackgroundTransparency = 1,
        Text = L("Фарм выкл"), TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = foot,
    })
    local prof = New("Frame", { -- профиль: аватар, ник, @логин
        Size = UDim2.new(0, 300, 1, 0), Position = UDim2.new(0, 240, 0, 0), BackgroundTransparency = 1, Parent = foot,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = prof,
    })
    local av = New("ImageLabel", {
        Size = UDim2.new(0, 22, 0, 22), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, LayoutOrder = 1,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150", Parent = prof,
    })
    Corner(av, 11)
    New("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = 2,
        Text = LP.DisplayName, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12, Parent = prof,
    })
    New("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = 3,
        Text = "@" .. LP.Name, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, Parent = prof,
    })
    FpsLabel = New("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(1, -216, 0, 0), BackgroundTransparency = 1,
        Text = "", TextColor3 = Theme.TextDim, Font = Enum.Font.Code, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = foot,
    })
end

-- ═══════════════ КОНТЕНТ ═══════════════
local CONTENT_Y = TAB_BAR_Y + TAB_BAR_H
local Content = New("Frame", {
    Size = UDim2.new(1, 0, 1, -(CONTENT_Y + FOOT_H)), Position = UDim2.new(0, 0, 0, CONTENT_Y), BackgroundTransparency = 1, Parent = Main,
})
local PageTitle = New("TextLabel", {
    Size = UDim2.new(1, -330, 0, 22), Position = UDim2.new(0, 24, 0, 12), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Content,
})
local PageSub = New("TextLabel", {
    Size = UDim2.new(1, -330, 0, 14), Position = UDim2.new(0, 24, 0, 34), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, Parent = Content,
})
New("TextLabel", { -- подсказка справа в шапке страницы
    Size = UDim2.new(0, 290, 0, 14), Position = UDim2.new(1, -314, 0, 34), BackgroundTransparency = 1,
    Text = L("RightShift — скрыть / показать окно"), TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right, Parent = Content,
})
local PagesHolder = New("Frame", {
    Size = UDim2.new(1, 0, 1, -58), Position = UDim2.new(0, 0, 0, 58), BackgroundTransparency = 1,
    ClipsDescendants = true, Parent = Content,
})

local Tabs, CurrentTab, TabCount = {}, nil, 0

local function SelectTab(name)
    for n, t in pairs(Tabs) do
        local on = (n == name)
        local was = t.Page.Visible
        t.Page.Visible = on
        if on and not was then -- страница слегка выезжает снизу
            t.Page.Position = UDim2.new(0, 0, 0, 10)
            Tween(t.Page, 0.2, { Position = UDim2.new(0, 0, 0, 0) })
        end
        Tween(t.Label, 0.15, { TextColor3 = on and Theme.Text or Theme.TextDim })
        Tween(t.Marker, 0.18, { Size = UDim2.new(1, -20, 0, on and 2 or 0) })
        if on then PageTitle.Text, PageSub.Text = L(n), L(t.Sub) end
    end
    CurrentTab = name
end

local function AddTab(name, glyph, order, sub)
    TabCount += 1
    local idx = TabCount
    local btn = New("TextButton", {
        Size = UDim2.new(0, 100, 1, 0), LayoutOrder = idx,
        BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = TabList,
    })
    local lbl = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = L(name), TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 13, Parent = btn,
    })
    local function fitWidth() -- ширина вкладки = текст + отступы (пересчитывается при смене языка)
        local w = game:GetService("TextService"):GetTextSize(lbl.Text, 13, Enum.Font.GothamMedium, Vector2.new(400, 40)).X
        btn.Size = UDim2.new(0, math.ceil(w) + 44, 1, 0)
    end
    fitWidth()
    Connect(lbl:GetPropertyChangedSignal("Text"), fitWidth)
    local marker = New("Frame", { -- линия под активной вкладкой
        Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 1, -2), BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0, ZIndex = 3, Parent = btn,
    })
    Corner(marker, 1)
    local dot = New("Frame", { -- «функция работает»
        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(1, -14, 0.5, -3), BackgroundColor3 = Theme.Good,
        BorderSizePixel = 0, Visible = false, Parent = btn,
    })
    Corner(dot, 3)

    local page = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        Visible = false, Parent = PagesHolder,
    })
    New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24), Parent = page,
    })

    Tabs[name] = { Btn = btn, Label = lbl, Marker = marker, Page = page, Sub = sub or "", Dot = dot, Index = idx }
    Connect(btn.MouseEnter, function()
        if CurrentTab ~= name then Tween(lbl, 0.12, { TextColor3 = Theme.AccentHi }) end
    end)
    Connect(btn.MouseLeave, function()
        if CurrentTab ~= name then Tween(lbl, 0.12, { TextColor3 = Theme.TextDim }) end
    end)
    Connect(btn.MouseButton1Click, function() SelectTab(name) end)
    return page
end

-- ═══════════════ РЕЕСТР ФУНКЦИЙ · ИЗБРАННОЕ · ЗАКРЕПЫ ═══════════════
-- Каждый тумблер / слайдер / переключатель / кнопка регистрируется здесь (для поиска). У тумблеров есть ★: избранное хранится в файле
-- (если эксплоит умеет writefile). Любой тумблер из избранного/поиска можно «закрепить» — на экране появится перетаскиваемая кнопка.
local Fav = { set = {}, pins = {}, list = {}, byKey = {}, entries = {}, savedPins = {}, FILE = "mm2prohub_favs.json" }
Fav.Http = game:GetService("HttpService")

function Fav.Save()
    pcall(function()
        if not writefile then return end
        local f, p = {}, {}
        for k in pairs(Fav.set) do f[#f + 1] = k end
        for k in pairs(Fav.pins) do p[#p + 1] = k end
        writefile(Fav.FILE, Fav.Http:JSONEncode({ fav = f, pin = p }))
    end)
end
pcall(function()
    if isfile and readfile and isfile(Fav.FILE) then
        local d = Fav.Http:JSONDecode(readfile(Fav.FILE))
        for _, k in ipairs(d.fav or {}) do Fav.set[k] = true end
        Fav.savedPins = d.pin or {}
    end
end)

function Fav.Reg(page, kind, title, desc, card, ctl)
    local tab
    for n, t in pairs(Tabs) do if t.Page == page then tab = n end end
    local e = { kind = kind, title = title, desc = desc or "", card = card, ctl = ctl, page = page, tab = tab or "" }
    Fav.entries[#Fav.entries + 1] = e
    return e
end

function Fav.Lower(s) -- нижний регистр с кириллицей (string.lower её не трогает)
    local ok, res = pcall(function()
        local out = {}
        for _, cp in utf8.codes(tostring(s)) do
            if cp >= 65 and cp <= 90 then cp += 32
            elseif cp >= 0x410 and cp <= 0x42F then cp += 32
            elseif cp == 0x401 then cp = 0x451 end
            out[#out + 1] = utf8.char(cp)
        end
        return table.concat(out)
    end)
    return ok and res or tostring(s):lower()
end

function Fav.Match(e, q)
    if not e.hay then -- ищем по обоим языкам сразу
        local ru = LangReverse[e.title] or e.title
        e.hay = Fav.Lower(e.title .. " " .. e.desc .. " " .. e.tab .. " " .. ru .. " " .. (LangEN[ru] or "") .. " " .. (LangEN[e.tab] or ""))
    end
    return e.hay:find(q, 1, true) ~= nil
end

function Fav.ToggleFav(key)
    if Fav.set[key] then Fav.set[key] = nil else Fav.set[key] = true end
    for _, c in ipairs(Fav.list) do c.PaintStar() end
    Fav.Save()
    if Fav.Refresh then Fav.Refresh() end
end

function Fav.Attach(card, ctl, title, desc, page) -- ★ на карточке тумблера + регистрация
    ctl.Key = LangReverse[title] or title
    Fav.byKey[ctl.Key] = ctl
    local star = New("TextButton", {
        Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -84, 0.5, -11), BackgroundTransparency = 1, Text = "☆",
        TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 16, ZIndex = 3, Parent = card,
    })
    function ctl.PaintStar()
        local on = Fav.set[ctl.Key]
        star.Text = on and "★" or "☆"
        star.TextColor3 = on and Theme.AccentHi or Theme.TextDim
    end
    ctl.PaintStar()
    Fav.list[#Fav.list + 1] = ctl
    Connect(star.MouseButton1Click, function() Fav.ToggleFav(ctl.Key) end)
    Fav.Reg(page, "toggle", title, desc, card, ctl)
end

function Fav.Pin(key) -- экранная кнопка для тумблера
    local ctl = Fav.byKey[key]
    if not ctl or Fav.pins[key] then return end
    local n = 0
    for _ in pairs(Fav.pins) do n += 1 end
    local b = New("TextButton", {
        Name = "PinBtn", Size = UDim2.new(0, 104, 0, 38), Position = UDim2.new(1, -230, 0, 130 + n * 46),
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = L(key),
        TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 30, Parent = SG,
    })
    Corner(b, 8)
    local st = Stroke(b, Theme.Border, 1.5)
    local dragging, moved, dragStart, startAbs = false, false, nil, nil
    Connect(b.InputBegan, function(inp)
        if IsPress(inp) then dragging, moved, dragStart, startAbs = true, false, inp.Position, b.AbsolutePosition end
    end)
    Connect(UserInputService.InputChanged, function(inp)
        if dragging and IsMove(inp) then
            local dl = inp.Position - dragStart
            if dl.Magnitude > 6 then moved = true end
            if moved then
                local vp = SG.AbsoluteSize
                b.Position = UDim2.new(0, math.clamp(startAbs.X + dl.X, 4, vp.X - b.AbsoluteSize.X - 4),
                    0, math.clamp(startAbs.Y + dl.Y, 4, vp.Y - b.AbsoluteSize.Y - 4))
            end
        end
    end)
    Connect(UserInputService.InputEnded, function(inp)
        if dragging and IsPress(inp) then
            dragging = false
            if not moved then ctl.Toggle() end
        end
    end)
    Fav.pins[key] = { btn = b, st = st, ctl = ctl }
    Fav.Save()
end

function Fav.Unpin(key)
    local p = Fav.pins[key]
    if p then p.btn:Destroy(); Fav.pins[key] = nil; Fav.Save() end
end

function Fav.RestorePins() -- после того как весь интерфейс построен
    for _, k in ipairs(Fav.savedPins or {}) do Fav.Pin(k) end
end

task.spawn(function() -- вид закреплённых кнопок = состояние тумблера
    while Alive do
        task.wait(0.15)
        for key, p in pairs(Fav.pins) do
            local on = p.ctl.Get() and true or false
            p.btn.BackgroundColor3 = on and Theme.Accent or Theme.Surface
            p.btn.TextColor3 = on and Color3.new(1, 1, 1) or Theme.TextDim
            p.st.Color = on and Theme.Accent or Theme.Border
        end
    end
end)

-- ═══════════════ КОМПОНЕНТЫ ═══════════════
local function Card(page, height)
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = page,
    })
    Corner(f, 6)
    local st = Stroke(f, Theme.Border)
    return f, st
end

local function Hover(hit, card, st)
    Connect(hit.MouseEnter, function()
        Tween(card, 0.12, { BackgroundColor3 = Theme.Surface2 })
        Tween(st, 0.12, { Color = Color3.fromRGB(70, 70, 78) })
    end)
    Connect(hit.MouseLeave, function()
        Tween(card, 0.12, { BackgroundColor3 = Theme.Surface })
        Tween(st, 0.12, { Color = Theme.Border })
    end)
end

local function AddSection(page, text)
    local f = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = page })
    local lbl = New("TextLabel", {
        Size = UDim2.new(0, 220, 1, 0), BackgroundTransparency = 1, Text = text:upper(), TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })
    lbl:SetAttribute("Sec", true) -- подпись секции: при смене языка пишется ЗАГЛАВНЫМИ
    local line = New("Frame", {
        Size = UDim2.new(1, -60, 0, 1), Position = UDim2.new(0, 60, 0.5, 0),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = f,
    })
    local function layout()
        local w = lbl.TextBounds.X + 10
        line.Position = UDim2.new(0, w, 0.5, 0)
        line.Size = UDim2.new(1, -w, 0, 1)
    end
    layout()
    Connect(lbl:GetPropertyChangedSignal("TextBounds"), layout)
end

local function AddBanner(page)
    local card = Card(page, 80)
    local av = New("ImageLabel", {
        Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150", Parent = card,
    })
    Corner(av, 8)
    New("TextLabel", {
        Size = UDim2.new(1, -170, 0, 22), Position = UDim2.new(0, 80, 0, 16), BackgroundTransparency = 1,
        Text = L("Привет, ") .. LP.DisplayName, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -170, 0, 14), Position = UDim2.new(0, 80, 0, 42), BackgroundTransparency = 1,
        Text = L("RightShift — скрыть / показать окно"), TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })
    local badge = New("Frame", {
        Size = UDim2.new(0, 64, 0, 24), Position = UDim2.new(1, -78, 0.5, -12), BackgroundTransparency = 1,
        BorderSizePixel = 0, Parent = card,
    })
    Corner(badge, 5)
    Stroke(badge, Theme.Accent)
    New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "v4.0", TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold, TextSize = 11, Parent = badge,
    })
end

local function AddToggle(page, title, desc, default, callback)
    local card, st = Card(page, 60)
    local strip = New("Frame", {
        Size = UDim2.new(0, 3, 0, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = card,
    })
    Corner(strip, 2)
    New("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18), Position = UDim2.new(0, 16, 0, 11),
        BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -90, 0, 14), Position = UDim2.new(0, 16, 0, 31),
        BackgroundTransparency = 1, Text = desc, TextColor3 = Theme.TextDim,
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })
    local track = New("Frame", {
        Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -56, 0.5, -10),
        BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Parent = card,
    })
    Corner(track, 4)
    local tst = Stroke(track, Theme.Border)
    local knob = New("Frame", {
        Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0, Parent = track,
    })
    Corner(knob, 3)
    local hit = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = card })

    local state = default
    local function render()
        Tween(track, 0.15, { BackgroundColor3 = state and Theme.Accent or Theme.Surface2 })
        Tween(tst, 0.15, { Color = state and Theme.Accent or Theme.Border })
        Tween(knob, 0.15, {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.TextDim,
        })
        Tween(strip, 0.15, { Size = UDim2.new(0, 3, 0, state and 28 or 0) })
    end
    render()

    Hover(hit, card, st)
    local ctl = {}
    function ctl.Get() return state end
    function ctl.Sync(v) -- привести вид тумблера к реальному состоянию (без callback и без уведомления)
        v = v and true or false
        if v ~= state then state = v; render() end
    end
    function ctl.Toggle()
        state = not state
        render()
        if callback then callback(state) end
        Notify(title, state and L("Включено") or L("Выключено"))
    end
    Connect(hit.MouseButton1Click, ctl.Toggle)
    Fav.Attach(card, ctl, title, desc, page)
    return ctl
end

local function AddSlider(page, title, min, max, default, callback)
    local card = Card(page, 62)
    Fav.Reg(page, "slider", title, "", card)
    New("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18), Position = UDim2.new(0, 16, 0, 10),
        BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    local valLbl = New("TextLabel", {
        Size = UDim2.new(0, 56, 0, 18), Position = UDim2.new(1, -72, 0, 10), BackgroundTransparency = 1,
        Text = tostring(default), TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
    })
    local track = New("Frame", {
        Size = UDim2.new(1, -32, 0, 4), Position = UDim2.new(0, 16, 0, 42),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = card,
    })
    Corner(track, 2)
    local fill = New("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track,
    })
    Corner(fill, 2)
    local knob = New("Frame", {
        Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = fill,
    })
    Corner(knob, 3)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = tostring(v)
        if callback then callback(v) end
    end
    Connect(track.InputBegan, function(i)
        if IsPress(i) then dragging = true; update(i.Position.X) end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then update(i.Position.X) end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if IsPress(i) then dragging = false end
    end)
end

local function AddButton(page, text, color, callback)
    local primary = color ~= nil and color ~= Theme.Surface
    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = primary and color or Theme.Surface,
        BorderSizePixel = 0, AutoButtonColor = false, Text = text, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold, TextSize = 13, Parent = page,
    })
    Fav.Reg(page, "button", text, "", b)
    Corner(b, 6)
    local st = (not primary) and Stroke(b) or nil
    Connect(b.MouseEnter, function()
        if primary then Tween(b, 0.12, { BackgroundTransparency = 0.2 })
        else Tween(b, 0.12, { BackgroundColor3 = Theme.Surface2 }) end
    end)
    Connect(b.MouseLeave, function()
        if primary then Tween(b, 0.12, { BackgroundTransparency = 0 })
        else Tween(b, 0.12, { BackgroundColor3 = Theme.Surface }) end
    end)
    Connect(b.MouseButton1Click, callback)
end

local function AddSegmented(page, title, options, default, callback)
    local card = Card(page, 82)
    Fav.Reg(page, "segmented", title, "", card)
    New("TextLabel", {
        Size = UDim2.new(1, -32, 0, 18), Position = UDim2.new(0, 16, 0, 10),
        BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    local bar = New("Frame", {
        Size = UDim2.new(1, -32, 0, 34), Position = UDim2.new(0, 16, 0, 36),
        BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = card,
    })
    Corner(bar, 6)
    Stroke(bar)
    local n = #options
    local hl = New("Frame", {
        Size = UDim2.new(1 / n, -6, 1, -6), Position = UDim2.new(0, 3, 0, 3),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar,
    })
    Corner(hl, 4)

    local labels = {}
    local function select(i, silent)
        Tween(hl, 0.18, { Position = UDim2.new((i - 1) / n, 3, 0, 3) })
        for k, l in ipairs(labels) do
            Tween(l, 0.15, { TextColor3 = (k == i) and Color3.new(1, 1, 1) or Theme.TextDim })
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
            Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, ZIndex = 2, Parent = bar,
        })
        labels[i] = b
        Connect(b.MouseButton1Click, function() select(i) end)
    end
    select(default, true)
end

local function AddInfo(page, text, height)
    local card = Card(page, height or 46)
    New("Frame", {
        Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0, Parent = card,
    })
    return New("TextLabel", {
        Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextDim,
        Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
end

-- Карточка с полосой прогресса. Возвращает функцию set(доля 0..1, текст)
local function AddProgress(page, title)
    local card = Card(page, 58)
    New("TextLabel", {
        Size = UDim2.new(1, -120, 0, 18), Position = UDim2.new(0, 16, 0, 10), BackgroundTransparency = 1,
        Text = title, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    local val = New("TextLabel", {
        Size = UDim2.new(0, 90, 0, 18), Position = UDim2.new(1, -106, 0, 10), BackgroundTransparency = 1,
        Text = "0 / 40", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = card,
    })
    local track = New("Frame", {
        Size = UDim2.new(1, -32, 0, 6), Position = UDim2.new(0, 16, 0, 38), BackgroundColor3 = Theme.Border,
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
    local cols = math.min(#items, 4)
    local rows = math.ceil(#items / cols)
    local GAP = 8
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, rows * 88 - 8), BackgroundTransparency = 1, Parent = page,
    })
    local vals = {}
    for i, it in ipairs(items) do
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local tile = New("Frame", {
            Size = UDim2.new(1 / cols, -GAP * (cols - 1) / cols, 0, 80), Position = UDim2.new(col / cols, col * GAP / cols, 0, row * 88),
            BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = holder,
        })
        Corner(tile, 6)
        Stroke(tile)
        New("Frame", {
            Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 16, 0, 14), BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0, Parent = tile,
        })
        New("TextLabel", {
            Size = UDim2.new(1, -40, 0, 14), Position = UDim2.new(0, 30, 0, 10), BackgroundTransparency = 1,
            Text = it.title, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = tile,
        })
        vals[it.key] = New("TextLabel", {
            Size = UDim2.new(1, -32, 0, 34), Position = UDim2.new(0, 16, 0, 32), BackgroundTransparency = 1,
            Text = "0", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 26,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = tile,
        })
    end
    return vals
end

-- ═══════════════ ВКЛАДКИ И ФУНКЦИИ ═══════════════
local PageMain     = AddTab("Основное", "", 1, "Движение и бой")
local PageVisual   = AddTab("Визуал", "", 2, "Подсветка игроков")
local PageFarm     = AddTab("Фарм", "", 3, "Автосбор монет и конфет")
local PageStats    = AddTab("Статистика", "", 4, "Итоги этой сессии")
local PageSettings = AddTab("Настройки", "", 5, "Интерфейс и сессия")

local Ctl = {} -- управление тумблерами (для экранных кнопок)
AddBanner(PageMain)
AddSection(PageMain, L("Движение"))
Ctl.Speed = AddToggle(PageMain, "Speed Hack", L("Переопределяет WalkSpeed"), false, function(s) State.Speed = s end)
AddSlider(PageMain, L("Скорость"), 16, 100, State.SpeedValue, function(v) State.SpeedValue = v end)
Ctl.Fly = AddToggle(PageMain, L("Fly (Полёт)"), L("WASD + Space вверх / Shift вниз"), false, function(s) State.Fly = s end)
AddSlider(PageMain, L("Скорость Fly"), 10, 100, State.FlySpeed, function(v) State.FlySpeed = v end)
AddSection(PageMain, L("Бой"))
AddToggle(PageMain, L("Авто-подбор пистолета"), L("Шериф умер: на миг телепорт к пистолету и обратно (только в раунде). Зажми G — турбо"), false, function(s) State.AutoGun = s end)
Ctl.Invis = AddToggle(PageMain, L("Невидимка"), L("Тело далеко за картой, ты управляешь полупрозрачной копией. Выкл: тело встанет на место копии"), false, function(s) Invis.Set(s) end)
AddToggle(PageMain, "Aimbot", L("Пока без логики, как в исходнике"), false, function(s) State.Aimbot = s end)

AddSection(PageVisual, L("Игроки"))
Ctl.ESP = AddToggle(PageVisual, L("ESP Игроков (Роли)"), "Murderer / Sheriff / Innocent", false, function(s) State.ESP = s end)

AddSection(PageFarm, L("Автоматизация"))
Ctl.Farm = AddToggle(PageFarm, "Auto-Farm", L("Под картой, монеты находит сам. Лобби и смерть — выкл."), false, function(s) State.AutoFarm = s end)
AddSegmented(PageFarm, L("Режим фарма"), { "Touch", "Teleport" }, 1, function(i)
    State.FarmMethod = (i == 1) and "touch" or "teleport"
end)
AddSlider(PageFarm, L("Скорость Teleport, стад/с"), 100, 5000, State.TpSpeed, function(v)
    State.TpSpeed = v
    local mark = os.clock() -- пишем в файл не на каждый сдвиг ползунка, а когда он остановился
    State.TpSaveMark = mark
    task.delay(0.6, function() if State.TpSaveMark == mark and State.SaveTp then State.SaveTp() end end)
end)
AddToggle(PageFarm, L("Teleport: мгновенно"), L("Прыжок на всю карту за кадр, как в v4.8 (в этом режиме кикало)"), false, function(s) State.TpInstant = s end)
AddToggle(PageFarm, L("Ресет после 40 монет"), L("Собрал 40 — ресет и ждём следующий раунд. Выкл: собирает без лимита"), true, function(s) State.FarmReset = s end)
AddSegmented(PageFarm, L("Старт отсчёта"), { L("Выдача роли"), L("Появление монет") }, 2, function(i)
    State.FarmTrigger = (i == 1) and "role" or "coins"
end)
AddSegmented(PageFarm, L("Ожидание перед фармом"), { L("0 с"), L("6 с"), L("12 с"), L("18 с") }, 1, function(i)
    State.FarmStartDelay = ({ 0, 6, 12, 18 })[i]
end)
AddToggle(PageFarm, L("Анти-АФК"), L("Не выкидывает с сервера за бездействие"), true, function(s) State.AntiAFK = s end)
AddSection(PageFarm, L("Диагностика"))
local FarmStatus = AddInfo(PageFarm, L("Статус: выключено"), 46)
local FarmDebug  = AddInfo(PageFarm, "—", 46)
local CoinSel    = AddInfo(PageFarm, L("Монеты: ищем объекты с именем Coin / Candy (учитывается Collected)"), 46)
Fav.GuiInfo = AddInfo(PageFarm, L("Счётчик монет в GUI: ") .. L("калибруется: нужно 3 собранные монеты"), 46)
local FarmBar    = AddProgress(PageFarm, L("Монеты в раунде"))
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
    local key = short .. "|" .. count .. "|" .. method .. "|" .. tostring(collecting)
    if key == lastUIKey then return end
    lastUIKey = key
    ChipText.Text = L("Фарм ") .. count .. "/" .. limit
    ChipText.TextColor3 = Theme.Text
    ChipDot.BackgroundColor3 = collecting and Theme.Good or Theme.AccentHi
    H.Title.Text = "Auto-Farm · " .. method .. " · " .. short
    H.Count.Text = count .. "/" .. limit
    local frac = math.clamp(count / limit, 0, 1)
    Tween(H.Fill, 0.2, { Size = UDim2.new(frac, 0, 1, 0) })
    Tween(H.Dot, 0.2, { BackgroundColor3 = collecting and Theme.Good or Theme.AccentHi })
    FarmBar(frac, count .. " / " .. limit)
end

local RestoreCollisions -- задаётся в блоке Auto-Farm ниже
local RestoreFly        -- задаётся в блоке Fly ниже
local ReturnHome        -- задаётся в блоке Auto-Farm ниже

local function Unload()
    Alive = false
    State.ESP, State.Speed, State.AutoFarm, State.Fly, State.Aimbot = false, false, false, false, false
    State.AutoGun = false
    if Invis.on then Invis.Disable(true) end
    if ReturnHome then ReturnHome() end
    if RestoreCollisions then RestoreCollisions() end
    if RestoreFly then RestoreFly() end
    for _, p in pairs(Players:GetPlayers()) do ClearESP(p) end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = 16 end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    SG:Destroy()
end

AddSection(PageStats, L("Эта сессия"))
local StatTiles = AddStats(PageStats, {
    { key = "coins",  title = L("Монет собрано") },
    { key = "rounds", title = L("Раундов в фарме") },
    { key = "resets", title = L("Ресетов") },
    { key = "time",   title = L("Время сессии") },
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

local SetOpenRef -- задаётся ниже, после SetOpen
local function SetLang(code)
    if code ~= "ru" then code = "en" end
    Lang = code
    pcall(function() if writefile then writefile(LANG_FILE, code) end end)
    for _, d in ipairs(SG:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local t = d.Text
            local key, rest = LangReverse[t], ""
            if not key then
                for _, p in ipairs(LangPrefixes) do
                    if t:sub(1, #p.ru) == p.ru then key, rest = p.ru, t:sub(#p.ru + 1); break end
                    if t:sub(1, #p.en) == p.en then key, rest = p.ru, t:sub(#p.en + 1); break end
                end
            end
            if key then
                local nt = L(key) .. rest
                if d:GetAttribute("Sec") then nt = nt:upper() end
                d.Text = nt
            end
        end
    end
    for n, t in pairs(Tabs) do t.Label.Text = L(n) end
    if CurrentTab then SelectTab(CurrentTab) end
end
AddSection(PageSettings, L("Интерфейс"))
AddSegmented(PageSettings, "Language / Язык", { "English", "Русский" }, Lang == "ru" and 2 or 1, function(i) SetLang(i == 2 and "ru" or "en") end)
AddSlider(PageSettings, L("Масштаб окна, %"), 60, 130, 100, function(v)
    BaseScale = FitScale() * (v / 100)
    MainScale.Scale = BaseScale
end)
AddButton(PageSettings, L("Свернуть / показать  (RightShift)"), Theme.Surface, function() if SetOpenRef then SetOpenRef(not Main.Visible) end end)
-- ═══════════════ ЭКРАННЫЕ КНОПКИ: быстрое включение функций прямо на экране ═══════════════
-- В Настройках включаешь нужную кнопку — она появляется на экране (её можно перетащить). Нажатие = включить/выключить функцию.
-- Состояние кнопки и тумблера в меню всегда совпадает с реальным (например, невидимка сама выключается при смерти).
do
    local defs = {
        { key = "Инвиз",    get = function() return Invis.on end,   tgl = function() return Ctl.Invis end },
        { key = "Полёт",    get = function() return State.Fly end,  tgl = function() return Ctl.Fly end },
        { key = "Скорость", get = function() return State.Speed end, tgl = function() return Ctl.Speed end },
        { key = "ESP",      get = function() return State.ESP end,  tgl = function() return Ctl.ESP end },
        { key = "Фарм",     get = function() return State.AutoFarm end, tgl = function() return Ctl.Farm end },
    }
    local btns, strokes = {}, {}
    for i, d in ipairs(defs) do
        local b = New("TextButton", {
            Name = "QuickBtn", Size = UDim2.new(0, 84, 0, 40), Position = UDim2.new(1, -100, 0, 130 + (i - 1) * 50),
            BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = L(d.key),
            TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 12, Visible = false, ZIndex = 30, Parent = SG,
        })
        Corner(b, 8)
        strokes[i] = Stroke(b, Theme.Border, 1.5)
        btns[i] = b
        local dragging, moved, dragStart, startAbs = false, false, nil, nil
        Connect(b.InputBegan, function(inp)
            if IsPress(inp) then dragging, moved, dragStart, startAbs = true, false, inp.Position, b.AbsolutePosition end
        end)
        Connect(UserInputService.InputChanged, function(inp)
            if dragging and IsMove(inp) then
                local dl = inp.Position - dragStart
                if dl.Magnitude > 6 then moved = true end
                if moved then
                    local vp = SG.AbsoluteSize
                    b.Position = UDim2.new(0, math.clamp(startAbs.X + dl.X, 4, vp.X - b.AbsoluteSize.X - 4),
                        0, math.clamp(startAbs.Y + dl.Y, 4, vp.Y - b.AbsoluteSize.Y - 4))
                end
            end
        end)
        Connect(UserInputService.InputEnded, function(inp)
            if dragging and IsPress(inp) then
                dragging = false
                if not moved then
                    local c = d.tgl()
                    if c then c.Toggle() end
                end
            end
        end)
    end

    AddSection(PageSettings, L("Экранные кнопки"))
    for i, d in ipairs(defs) do
        AddToggle(PageSettings, L(d.key), L("Показать кнопку на экране"), false, function(on) btns[i].Visible = on end)
    end

    task.spawn(function()
        while Alive do
            task.wait(0.15)
            for i, d in ipairs(defs) do
                local on = d.get() and true or false
                local c = d.tgl()
                if c then c.Sync(on) end
                local b = btns[i]
                if b.Visible then
                    b.BackgroundColor3 = on and Theme.Accent or Theme.Surface
                    b.TextColor3 = on and Color3.new(1, 1, 1) or Theme.TextDim
                    strokes[i].Color = on and Theme.Accent or Theme.Border
                end
            end
        end
    end)
end

AddSection(PageSettings, L("Сессия"))
AddButton(PageSettings, L("Выгрузить скрипт"), Theme.Danger, Unload)

-- ═══════════════ ПОИСК ПО ФУНКЦИЯМ ═══════════════
-- Строка в шапке страницы. Пустая строка при фокусе = ★ избранное (с кнопкой «Закрепить» → экранная кнопка).
-- Запрос ищется в названии, описании и вкладке, на русском и английском. Тумблеры переключаются прямо из результатов;
-- слайдеры / режимы / кнопки — «Открыть»: переход на вкладку, прокрутка к карточке и подсветка.
do
    local Box = New("TextBox", {
        Name = "Search", Size = UDim2.new(0, 210, 0, 26), Position = UDim2.new(1, -234, 0, 6),
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Text = "", PlaceholderText = "Search · Поиск…",
        PlaceholderColor3 = Theme.TextDim, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 12, Parent = Content,
    })
    Corner(Box, 6)
    Stroke(Box)
    New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 26), Parent = Box })
    local ClearBtn = New("TextButton", {
        Size = UDim2.new(0, 22, 0, 26), Position = UDim2.new(1, -48, 0, 6), BackgroundTransparency = 1, Text = "×",
        TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 16, Visible = false, ZIndex = 13, Parent = Content,
    })

    local SP = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Border, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        Visible = false, ZIndex = 10, Parent = PagesHolder,
    })
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = SP })
    New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24), Parent = SP })

    local rows, closing = {}, false
    local function Shown(e) local ru = LangReverse[e.title]; return ru and L(ru) or e.title end

    local function GoTo(e)
        closing = true -- очистка строки не должна заново открыть панель
        Box.Text = ""
        closing = false
        SP.Visible = false
        ClearBtn.Visible = false
        SelectTab(e.tab)
        task.spawn(function()
            task.wait(0.28) -- дождаться, пока страница доедет
            if not (e.card and e.card.Parent) then return end
            local y = e.card.AbsolutePosition.Y - e.page.AbsolutePosition.Y + e.page.CanvasPosition.Y - 8
            e.page.CanvasPosition = Vector2.new(0, math.max(0, y))
            local st = e.card:FindFirstChildOfClass("UIStroke")
            if st then
                local old = st.Color
                st.Color = Theme.Accent
                task.wait(0.9)
                if st.Parent then Tween(st, 0.4, { Color = old }) end
            end
        end)
    end

    local function AddLabel(text, order, h, color)
        local l = New("TextLabel", {
            Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Text = text, TextColor3 = color or Theme.TextDim,
            Font = Enum.Font.GothamBold, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = order, Parent = SP,
        })
        rows[#rows + 1] = { f = l }
    end

    local function AddRow(e, order)
        local f = New("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, LayoutOrder = order, Parent = SP })
        Corner(f, 6)
        Stroke(f)
        local rw = { f = f }
        New("TextLabel", {
            Size = UDim2.new(1, -176, 0, 18), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1, Text = Shown(e),
            TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = f,
        })
        New("TextLabel", {
            Size = UDim2.new(1, -176, 0, 14), Position = UDim2.new(0, 14, 0, 25), BackgroundTransparency = 1, Text = L(e.tab),
            TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = f,
        })
        if e.ctl then
            local c = e.ctl
            local track = New("Frame", { Size = UDim2.new(0, 38, 0, 18), Position = UDim2.new(1, -52, 0.5, -9), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0, Parent = f })
            Corner(track, 4)
            local knob = New("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0, Parent = track })
            Corner(knob, 3)
            local hit = New("TextButton", { Size = UDim2.new(1, 10, 1, 14), Position = UDim2.new(0, -5, 0, -7), BackgroundTransparency = 1, Text = "", Parent = track })
            Connect(hit.MouseButton1Click, function() c.Toggle() end)
            local star = New("TextButton", {
                Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -84, 0.5, -12), BackgroundTransparency = 1, Text = "",
                Font = Enum.Font.GothamBold, TextSize = 17, Parent = f,
            })
            Connect(star.MouseButton1Click, function() Fav.ToggleFav(c.Key) end)
            local pin = New("TextButton", {
                Size = UDim2.new(0, 70, 0, 22), Position = UDim2.new(1, -160, 0.5, -11), BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0, AutoButtonColor = false, Text = "", Font = Enum.Font.GothamBold, TextSize = 10, Parent = f,
            })
            Corner(pin, 5)
            function rw.paint()
                local on = c.Get() and true or false
                track.BackgroundColor3 = on and Theme.Accent or Theme.Surface2
                knob.Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
                knob.BackgroundColor3 = on and Color3.new(1, 1, 1) or Theme.TextDim
                local fv = Fav.set[c.Key]
                star.Text = fv and "★" or "☆"
                star.TextColor3 = fv and Theme.AccentHi or Theme.TextDim
                local pn = Fav.pins[c.Key] ~= nil
                pin.Text = pn and L("Закреплено") or L("Закрепить")
                pin.TextColor3 = pn and Color3.new(1, 1, 1) or Theme.TextDim
                pin.BackgroundColor3 = pn and Theme.Accent or Theme.Surface2
            end
            Connect(pin.MouseButton1Click, function()
                if Fav.pins[c.Key] then Fav.Unpin(c.Key) else Fav.Pin(c.Key) end
                rw.paint()
            end)
            rw.paint()
        else
            local go = New("TextButton", {
                Size = UDim2.new(0, 76, 0, 24), Position = UDim2.new(1, -92, 0.5, -12), BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0, AutoButtonColor = false, Text = L("Открыть"), TextColor3 = Theme.AccentHi,
                Font = Enum.Font.GothamBold, TextSize = 11, Parent = f,
            })
            Corner(go, 5)
            Connect(go.MouseButton1Click, function() GoTo(e) end)
        end
        rows[#rows + 1] = rw
    end

    local function Render()
        for _, r in ipairs(rows) do r.f:Destroy() end
        rows = {}
        local q = Fav.Lower(Box.Text)
        q = q:gsub("^%s+", "")
        q = q:gsub("%s+$", "")
        local order, shown = 1, 0
        if q == "" then
            AddLabel("★  " .. L("Избранное"), order, 18, Theme.AccentHi)
            for _, e in ipairs(Fav.entries) do
                if e.ctl and Fav.set[e.ctl.Key] then order += 1; shown += 1; AddRow(e, order) end
            end
            if shown == 0 then
                order += 1
                AddLabel(L("Нажми ☆ у любого тумблера, чтобы добавить его в избранное. Здесь его можно закрепить кнопкой на экране."), order, 48)
            end
        else
            for _, e in ipairs(Fav.entries) do
                if shown < 40 and Fav.Match(e, q) then order += 1; shown += 1; AddRow(e, order) end
            end
            if shown == 0 then AddLabel(L("Ничего не найдено"), order, 18) end
        end
    end
    Fav.Refresh = function() if SP.Visible then Render() end end

    local function Close()
        closing = true
        Box.Text = ""
        closing = false
        SP.Visible = false
        ClearBtn.Visible = false
    end

    Connect(Box.Focused, function()
        ClearBtn.Visible = true
        if not SP.Visible then SP.Visible = true; Render() end
    end)
    Connect(Box:GetPropertyChangedSignal("Text"), function()
        if closing then return end
        ClearBtn.Visible = true
        if not SP.Visible then SP.Visible = true end
        Render()
    end)
    Connect(ClearBtn.MouseButton1Click, function() Close(); Box:ReleaseFocus() end)

    task.spawn(function() -- переключатели в результатах повторяют состояние настоящих
        while Alive do
            task.wait(0.2)
            if SP.Visible then
                for _, r in ipairs(rows) do if r.paint then r.paint() end end
            end
        end
    end)

    local baseSelect = SelectTab -- смена вкладки закрывает поиск
    SelectTab = function(name)
        if SP.Visible or Box.Text ~= "" then Close() end
        baseSelect(name)
    end
end

-- ═══════════════ ANNOUNCE: объявления для всех клиентов + реакции (канал: топик ntfy.sh) ═══════════════
-- Каждый клиент раз в ANNOUNCE_POLL секунд читает новые события топика. Событие "ann" — объявление, "react" — реакция на него.
-- Новое объявление показывается один раз баннером; реакции пересчитываются по последнему голосу каждого userId.
local HttpService = game:GetService("HttpService")
local ANN_FILE = "mm2prohub_ann.txt" -- время последнего показанного объявления (если эксплоит умеет writefile)
local ANN_URL = ANNOUNCE_HOST .. "/" .. ANNOUNCE_TOPIC
local REACTIONS = { { id = "like", icon = "👍" }, { id = "heart", icon = "❤️" }, { id = "fire", icon = "🔥" }, { id = "laugh", icon = "😂" } }
local Ann = { lastTime = 0, cursor = nil, seen = {}, pending = nil, cur = { id = nil, time = 0, reactions = {}, mine = nil, votes = {} },
    banner = nil, refresh = nil, ownerStats = nil, lastReact = 0 }
pcall(function() if isfile and readfile and isfile(ANN_FILE) then Ann.lastTime = tonumber(readfile(ANN_FILE)) or 0 end end)

local function HttpRequest(opts)
    local fn = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if not fn then return nil, "no http api" end
    local ok, res = pcall(fn, opts)
    if not ok then return nil, tostring(res) end
    return res
end

local function CleanText(t)
    local c = tostring(t or ""):gsub("%c+", " ")
    return c:sub(1, ANNOUNCE_MAXLEN)
end

local SendReaction -- задаётся ниже

local function ShowAnnouncement(text, preview)
    text = CleanText(text)
    if text == "" then return end
    if Ann.banner then Ann.banner:Destroy() end
    local b = New("Frame", {
        Name = "Announcement", Size = UDim2.new(0, 460, 0, 118), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -130), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ZIndex = 60, Parent = SG,
    })
    Corner(b, 8)
    Stroke(b, Theme.Accent, 1.5)
    New("Frame", { Size = UDim2.new(0, 3, 1, -20), Position = UDim2.new(0, 8, 0, 10), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 61, Parent = b })
    New("TextLabel", {
        Size = UDim2.new(1, -60, 0, 16), Position = UDim2.new(0, 22, 0, 9), BackgroundTransparency = 1,
        Text = L("Объявление") .. "  ·  PRO HUB" .. (preview and ("  ·  " .. L("Предпросмотр")) or ""),
        TextColor3 = Theme.AccentHi, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61, Parent = b,
    })
    local closeBtn = New("TextButton", {
        Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -30, 0, 6), BackgroundTransparency = 1, AutoButtonColor = false,
        Text = "×", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 18, ZIndex = 62, Parent = b,
    })
    Connect(closeBtn.MouseEnter, function() Tween(closeBtn, 0.12, { TextColor3 = Theme.Text }) end)
    Connect(closeBtn.MouseLeave, function() Tween(closeBtn, 0.12, { TextColor3 = Theme.TextDim }) end)
    New("TextLabel", {
        Size = UDim2.new(1, -44, 0, 42), Position = UDim2.new(0, 22, 0, 28), BackgroundTransparency = 1,
        Text = text, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 61, Parent = b,
    })
    local row = New("Frame", { Size = UDim2.new(1, -44, 0, 26), Position = UDim2.new(0, 22, 1, -36), BackgroundTransparency = 1, ZIndex = 61, Parent = b })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
    local btns = {}
    for i, r in ipairs(REACTIONS) do
        local rb = New("TextButton", {
            Size = UDim2.new(0, 64, 1, 0), LayoutOrder = i, BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
            AutoButtonColor = false, Text = r.icon .. " 0", TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12,
            ZIndex = 62, Parent = row,
        })
        Corner(rb, 13)
        btns[i] = { btn = rb, st = Stroke(rb, Theme.Border), id = r.id, icon = r.icon }
        Connect(rb.MouseButton1Click, function() if not preview then SendReaction(r.id) end end)
    end
    Ann.refresh = function() -- счётчики и подсветка своей реакции
        for _, x in ipairs(btns) do
            local n = preview and 0 or (Ann.cur.reactions[x.id] or 0)
            x.btn.Text = x.icon .. " " .. tostring(n)
            local mine = (not preview) and Ann.cur.mine == x.id
            x.st.Color = mine and Theme.Accent or Theme.Border
            x.btn.BackgroundColor3 = mine and Theme.Bg or Theme.Surface2
        end
    end
    Ann.refresh()
    Ann.banner = b
    Tween(b, 0.35, { Position = UDim2.new(0.5, 0, 0, 66) }, Enum.EasingStyle.Quint)
    local function close()
        if Ann.banner ~= b then return end
        Ann.banner, Ann.refresh = nil, nil
        Tween(b, 0.25, { Position = UDim2.new(0.5, 0, 0, -130) })
        task.delay(0.3, function() b:Destroy() end)
    end
    Connect(closeBtn.MouseButton1Click, close)
    task.delay(25, close)
end

local function Recount() -- реакции = последний голос каждого userId
    local r = { like = 0, heart = 0, fire = 0, laugh = 0 }
    for _, v in pairs(Ann.cur.votes) do
        if r[v] then r[v] += 1 end
    end
    Ann.cur.reactions = r
    Ann.cur.mine = Ann.cur.votes[tostring(LP.UserId)]
end

-- одно событие ntfy (поле message — наш JSON). Дубликаты отсекаются по id события.
local function HandleEvent(ev)
    if type(ev) ~= "table" or ev.event ~= "message" or type(ev.id) ~= "string" or Ann.seen[ev.id] then return end
    Ann.seen[ev.id] = true
    if type(ev.time) == "number" and (not Ann.cursor or ev.time > Ann.cursor) then Ann.cursor = ev.time end
    local ok, d = pcall(HttpService.JSONDecode, HttpService, tostring(ev.message))
    if not ok or type(d) ~= "table" then return end
    if d.t == "ann" and type(d.text) == "string" and type(ev.time) == "number" then
        if ev.time >= Ann.cur.time then -- побеждает самое новое объявление
            Ann.cur = { id = ev.id, time = ev.time, reactions = {}, mine = nil, votes = {} }
            if ev.time > Ann.lastTime then
                Ann.lastTime = ev.time
                Ann.pending = d.text
                pcall(function() if writefile then writefile(ANN_FILE, tostring(Ann.lastTime)) end end)
            end
        end
    elseif d.t == "react" and Ann.cur.id and d.a == Ann.cur.id and d.u ~= nil then
        local valid = false
        for _, r in ipairs(REACTIONS) do if r.id == d.r then valid = true end end
        Ann.cur.votes[tostring(d.u)] = valid and d.r or nil -- пустая/неизвестная реакция = снять голос
    end
end

local function HandleEvents(list)
    for _, ev in ipairs(list) do HandleEvent(ev) end
    Recount()
    if Ann.pending then -- при первом запуске в очереди может быть несколько объявлений: показываем только последнее
        local text = Ann.pending
        Ann.pending = nil
        ShowAnnouncement(text)
    end
    if Ann.refresh then Ann.refresh() end
    if Ann.ownerStats then Ann.ownerStats() end
end

local function PostEvent(payload)
    return HttpRequest({
        Url = ANN_URL, Method = "POST", Headers = { ["Content-Type"] = "text/plain; charset=utf-8" },
        Body = HttpService:JSONEncode(payload),
    })
end

SendReaction = function(r)
    if not Ann.cur.id then return end
    if os.clock() - Ann.lastReact < 0.4 then return end
    Ann.lastReact = os.clock()
    local uid, prev = tostring(LP.UserId), Ann.cur.votes[tostring(LP.UserId)]
    local newVote = (prev ~= r) and r or nil -- повторное нажатие снимает реакцию
    Ann.cur.votes[uid] = newVote -- сразу показываем результат
    Recount()
    if Ann.refresh then Ann.refresh() end
    local id = Ann.cur.id
    task.spawn(function()
        local res, err = PostEvent({ t = "react", a = id, u = LP.UserId, r = newVote or "" })
        if res and res.StatusCode == 200 then
            local ok, ev = pcall(HttpService.JSONDecode, HttpService, res.Body)
            if ok then HandleEvents({ ev }) end
        else
            Notify(L("Реакция"), L("Не отправлено: ") .. tostring(res and res.StatusCode or err))
        end
    end)
end

task.spawn(function() -- опрос канала: так объявление доходит до всех клиентов
    while Alive do
        local since = Ann.cursor and tostring(Ann.cursor) or "12h"
        local res = HttpRequest({ Url = ANN_URL .. "/json?poll=1&since=" .. since, Method = "GET" })
        if res and res.StatusCode == 200 then
            local list = {}
            for line in tostring(res.Body):gmatch("[^\r\n]+") do
                local ok, ev = pcall(HttpService.JSONDecode, HttpService, line)
                if ok and type(ev) == "table" then list[#list + 1] = ev end
            end
            HandleEvents(list)
        end
        task.wait(math.max(5, ANNOUNCE_POLL))
    end
end)

-- вкладка отправки: создаётся только для ANNOUNCE_OWNER
if LP.Name:lower() == ANNOUNCE_OWNER:lower() then
    local PageAnn = AddTab("Рассылка", "", 6, "Сообщение для всех, кто запустил скрипт")
    AddInfo(PageAnn, string.format(L("Клиенты проверяют канал раз в %d с"), math.max(5, ANNOUNCE_POLL)), 46)
    local statsLbl = AddInfo(PageAnn, L("Реакции последнего объявления: ") .. "—", 46)
    Ann.ownerStats = function()
        local parts = {}
        for _, r in ipairs(REACTIONS) do parts[#parts + 1] = r.icon .. " " .. tostring(Ann.cur.reactions[r.id] or 0) end
        statsLbl.Text = L("Реакции последнего объявления: ") .. table.concat(parts, "   ")
    end

    AddSection(PageAnn, L("Сообщение"))
    local msgCard = Card(PageAnn, 120)
    local msgBox = New("TextBox", {
        Size = UDim2.new(1, -28, 1, -40), Position = UDim2.new(0, 14, 0, 12), BackgroundTransparency = 1, Text = "",
        PlaceholderText = L("Текст объявления…"), PlaceholderColor3 = Theme.TextDim, TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true, TextWrapped = true, ClearTextOnFocus = false, Parent = msgCard,
    })
    local counter = New("TextLabel", {
        Size = UDim2.new(0, 80, 0, 14), Position = UDim2.new(1, -94, 1, -22), BackgroundTransparency = 1,
        Text = "0/" .. ANNOUNCE_MAXLEN, TextColor3 = Theme.TextDim, Font = Enum.Font.Code, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = msgCard,
    })
    Connect(msgBox:GetPropertyChangedSignal("Text"), function()
        if #msgBox.Text > ANNOUNCE_MAXLEN then msgBox.Text = msgBox.Text:sub(1, ANNOUNCE_MAXLEN) end
        counter.Text = #msgBox.Text .. "/" .. ANNOUNCE_MAXLEN
    end)

    AddButton(PageAnn, L("Предпросмотр"), Theme.Surface, function()
        local text = CleanText(msgBox.Text)
        if text == "" then Notify(L("Рассылка"), L("Введи текст")); return end
        ShowAnnouncement(text, true)
    end)
    local lastSend = -100
    AddButton(PageAnn, L("Отправить всем"), Theme.Accent, function()
        local text = CleanText(msgBox.Text)
        if text == "" then Notify(L("Рассылка"), L("Введи текст")); return end
        if os.clock() - lastSend < 10 then Notify(L("Рассылка"), L("Подожди несколько секунд")); return end
        lastSend = os.clock()
        task.spawn(function()
            local res, err = PostEvent({ t = "ann", text = text, s = LP.Name })
            if res and res.StatusCode >= 200 and res.StatusCode < 300 then
                Notify(L("Рассылка"), L("Отправлено"))
                local ok, ev = pcall(HttpService.JSONDecode, HttpService, res.Body)
                if ok then HandleEvents({ ev }) end -- у отправителя баннер появляется сразу, у остальных — при ближайшем опросе
            else
                Notify(L("Рассылка"), L("Не отправлено: ") .. tostring(res and res.StatusCode or err))
            end
        end)
    end)
end

-- ═══════════════ СВОРАЧИВАНИЕ / ЗАКРЫТИЕ ═══════════════
-- Свёрнутый хаб: компактный док у левого края экрана (по центру по высоте), а не в углу под меню Roblox.
-- Тянется пальцем/мышью, не выходит за экран и не заезжает под верхнюю панель Roblox; нажатие — открыть окно.
local Pill = New("TextButton", {
    Name = "Dock", Size = UDim2.new(0, 158, 0, 40), Position = UDim2.new(0, 14, 0.5, -20),
    BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
    Visible = false, ZIndex = 20, Parent = SG,
})
Corner(Pill, 20)
local PillStroke = Stroke(Pill, Theme.Accent, 1.5)
local PillLogo = New("Frame", { Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 6, 0.5, -14), BorderSizePixel = 0, ZIndex = 21, Parent = Pill })
Corner(PillLogo, 7)
BuildLogo(PillLogo, 7)
New("TextLabel", {
    Size = UDim2.new(1, -78, 0, 16), Position = UDim2.new(0, 42, 0, 5), BackgroundTransparency = 1,
    Text = "PRO HUB", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Parent = Pill,
})
New("TextLabel", {
    Size = UDim2.new(1, -78, 0, 12), Position = UDim2.new(0, 42, 0, 21), BackgroundTransparency = 1,
    Text = L("Нажми, чтобы открыть"), TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 21, Parent = Pill,
})
local PillDot = New("Frame", { -- горит, пока включена любая функция
    Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(1, -20, 0.5, -4), BackgroundColor3 = Theme.Good,
    BorderSizePixel = 0, Visible = false, ZIndex = 21, Parent = Pill,
})
Corner(PillDot, 4)
Connect(Pill.MouseEnter, function() Tween(Pill, 0.12, { BackgroundColor3 = Theme.Surface2 }) end)
Connect(Pill.MouseLeave, function() Tween(Pill, 0.12, { BackgroundColor3 = Theme.Surface }) end)

local function PlaceDock() -- держим док целиком на экране, ниже верхней панели Roblox
    local vp = SG.AbsoluteSize
    local ap, sz = Pill.AbsolutePosition, Pill.AbsoluteSize
    local x = math.clamp(ap.X, 8, math.max(8, vp.X - sz.X - 8))
    local y = math.clamp(ap.Y, 48, math.max(48, vp.Y - sz.Y - 8))
    Pill.Position = UDim2.fromOffset(x, y)
end

local IntroDone = false
local function SetOpen(open)
    if not IntroDone then return end
    if open then
        Main.Visible = true
        Pill.Visible = false
        MainScale.Scale = BaseScale * 0.96
        Tween(MainScale, 0.2, { Scale = BaseScale })
    else
        Tween(MainScale, 0.12, { Scale = BaseScale * 0.96 })
        task.delay(0.12, function()
            if Alive then
                Main.Visible = false
                Pill.Visible = true
                task.defer(PlaceDock)
            end
        end)
    end
end
SetOpenRef = SetOpen

Connect(MinBtn.MouseButton1Click, function() SetOpen(false) end)
do -- перетаскивание дока; короткое нажатие без движения = открыть окно
    local dragging, moved, dragStart, startPos = false, false, nil, nil
    Connect(Pill.InputBegan, function(i)
        if IsPress(i) then
            dragging, moved, dragStart, startPos = true, false, i.Position, Pill.AbsolutePosition
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = i.Position - dragStart
            if d.Magnitude > 5 then moved = true end
            if moved then
                Pill.Position = UDim2.fromOffset(startPos.X + d.X, startPos.Y + d.Y)
                PlaceDock()
            end
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if dragging and IsPress(i) then
            dragging = false
            if not moved then SetOpen(true) end
        end
    end)
    Connect(SG:GetPropertyChangedSignal("AbsoluteSize"), function() if Pill.Visible then PlaceDock() end end)
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

-- FPS и время сессии в левой панели (раз в полсекунды)
do
    local acc, n = 0, 0
    Connect(RunService.RenderStepped, function(dt)
        acc += dt
        n += 1
        if acc >= 0.5 then
            local el = math.floor(os.clock() - Stats.t0)
            FpsLabel.Text = string.format("%d FPS  ·  %d:%02d:%02d", math.floor(n / acc + 0.5),
                math.floor(el / 3600), math.floor(el / 60) % 60, el % 60)
            PillDot.Visible = State.AutoFarm or State.Fly or State.ESP or State.Speed or State.AutoGun
            acc, n = 0, 0
        end
    end)
end
Connect(CloseBtn.MouseButton1Click, Unload)
Connect(UserInputService.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then SetOpen(not Main.Visible) end
end)

-- ═══════════════ ИНТРО «Слэш и занавес» ═══════════════
-- Логотип проявляется -> оранжевая линия «режет» экран -> название печатается -> лог загрузки ->
-- занавес (две половины экрана) разъезжается и открывает окно. Клик / клавиша = пропустить.
local function RunIntro()
    local active, skip = true, false
    local Intro = New("Frame", {
        Name = "Intro", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 100, Active = true, Parent = SG,
    })
    local curtainColor = Color3.fromRGB(10, 10, 11)
    local top = New("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = curtainColor, BorderSizePixel = 0, ZIndex = 100, Parent = Intro,
    })
    local bot = New("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = curtainColor,
        BorderSizePixel = 0, ZIndex = 100, Parent = Intro,
    })
    local vp = SG.AbsoluteSize
    local fit = (vp.X > 1 and vp.Y > 1) and math.clamp(math.min(vp.Y / 520, vp.X / 560), 0.7, 2.6) or 1
    local content = New("CanvasGroup", { -- размер 1/fit + UIScale = fit: содержимое растёт вместе с экраном и занимает его целиком
        Size = UDim2.fromScale(1 / fit, 1 / fit), BackgroundTransparency = 1, ZIndex = 101, Parent = Intro,
    })
    New("UIScale", { Scale = fit, Parent = content })
    Connect(UserInputService.InputBegan, function(i)
        if active and (IsPress(i) or i.UserInputType == Enum.UserInputType.Keyboard) then skip = true end
    end)
    local function W(t) -- ожидание, которое прерывается пропуском
        local e = os.clock() + t
        while Alive and not skip and os.clock() < e do task.wait() end
    end

    -- нижняя тонкая линия прогресса
    local progress = New("Frame", {
        Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0, ZIndex = 102, Parent = content,
    })
    local TOTAL = 4.8
    local t0 = os.clock()
    task.spawn(function()
        while active and Alive and progress.Parent do
            local k = skip and 1 or math.min((os.clock() - t0) / TOTAL, 1)
            progress.Size = UDim2.new(k, 0, 0, 2)
            task.wait()
        end
    end)

    -- логотип
    local logo = New("CanvasGroup", {
        Size = UDim2.new(0, 116, 0, 116), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -84),
        GroupTransparency = 1, BorderSizePixel = 0, ZIndex = 103, Parent = content,
    })
    Corner(logo, 14)
    BuildLogo(logo, 14)
    local logoScale = New("UIScale", { Scale = 0.88, Parent = logo })
    Tween(logo, 0.5, { GroupTransparency = 0 })
    Tween(logoScale, 0.6, { Scale = 1 }, Enum.EasingStyle.Quint)
    W(0.55)
    if not Alive then return end

    -- «слэш»: линия режет экран по диагонали и гаснет
    local slash = New("Frame", {
        Size = UDim2.new(0, 0, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -84),
        Rotation = -14, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 104, Parent = content,
    })
    Tween(slash, 0.28, { Size = UDim2.new(1.3, 0, 0, 3) }, Enum.EasingStyle.Quint)
    W(0.3)
    Tween(slash, 0.35, { BackgroundTransparency = 1, Size = UDim2.new(1.3, 0, 0, 1) })
    Tween(logoScale, 0.25, { Scale = 1.04 })

    -- название печатается
    local title = New("TextLabel", {
        Size = UDim2.new(0, 520, 0, 30), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 6),
        BackgroundTransparency = 1, Text = "", TextColor3 = Theme.Text, Font = Enum.Font.GothamBlack, TextSize = 26,
        ZIndex = 103, Parent = content,
    })
    local full = "MURDER MYSTERY 2"
    for i = 1, #full do
        if skip then break end
        title.Text = full:sub(1, i) .. "▌"
        W(0.045)
    end
    title.Text = full
    -- подпись внизу экрана
    local credit = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16),
        BackgroundTransparency = 1, Text = "By shebx436", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium,
        TextSize = 13, TextTransparency = 1, ZIndex = 103, Parent = content,
    })
    Tween(credit, 0.6, { TextTransparency = 0 })

    -- «PRO HUB»: буквы по одной выезжают снизу (строка обрезает всё, что ниже её нижнего края)
    local word, SLOT, SPACE = "PRO HUB", 34, 18
    local total = 0
    for i = 1, #word do total += (word:sub(i, i) == " ") and SPACE or SLOT end
    local row = New("Frame", {
        Size = UDim2.new(0, total, 0, 50), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 32),
        BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 103, Parent = content,
    })
    local x = 0
    for i = 1, #word do
        local ch = word:sub(i, i)
        local lx = x -- своя копия позиции для каждой буквы
        if ch ~= " " then
            local l = New("TextLabel", {
                Size = UDim2.new(0, SLOT, 0, 46), Position = UDim2.new(0, lx, 1, 4), BackgroundTransparency = 1, Text = ch,
                TextColor3 = (i <= 3) and Theme.Text or Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 40,
                TextTransparency = 1, ZIndex = 104, Parent = row,
            })
            task.delay((i - 1) * 0.09, function()
                if l.Parent then
                    Tween(l, 0.55, { Position = UDim2.new(0, lx, 0, 2), TextTransparency = 0 }, Enum.EasingStyle.Quint)
                end
            end)
        end
        x += (ch == " ") and SPACE or SLOT
    end
    W(0.09 * #word + 0.65)
    if not Alive then return end

    -- лог загрузки
    local lines = {
        L("интерфейс"), L("карта и монеты"), L("роли и ESP"), L("автофарм"),
    }
    for i, name in ipairs(lines) do
        local l = New("TextLabel", {
            Size = UDim2.new(0, 280, 0, 16), AnchorPoint = Vector2.new(0.5, 0), RichText = true,
            Position = UDim2.new(0.5, 0, 0.5, 102 + (i - 1) * 18), BackgroundTransparency = 1,
            Text = string.format('<font color="rgb(140,138,134)">›  %s ...</font>  <font color="rgb(96,192,124)">OK</font>', name),
            TextColor3 = Theme.TextDim, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1, ZIndex = 103, Parent = content,
        })
        Tween(l, 0.2, { TextTransparency = 0 })
        W(0.26)
    end
    W(0.35)
    if not Alive then return end

    -- финал: содержимое гаснет, занавес разъезжается, окно появляется
    active = false
    TweenService:Create(content, TweenInfo.new(0.3), { GroupTransparency = 1 }):Play()
    W(0.25)
    Main.Visible = true
    MainScale.Scale = BaseScale * 0.94
    IntroDone = true
    Tween(MainScale, 0.6, { Scale = BaseScale }, Enum.EasingStyle.Quint)
    Tween(top, 0.7, { Position = UDim2.new(0, 0, -0.5, 0) }, Enum.EasingStyle.Quint)
    Tween(bot, 0.7, { Position = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Quint)
    Notify("MM2 PRO HUB", L("Загружен. RightShift: скрыть/показать"))
    task.wait(0.75)
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

local TpTarget, TpPhase, TpUntil, TpTries, TpNextAt = nil, "slide", 0, 0, 0 -- режим Teleport: фаза "slide" (под картой) / "grab" (на монете)
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
local TP_STUCK = 0.8 -- Teleport: предохранитель. Стоим на монете, пока она не исчезнет (подтверждение от сервера); если за 2 с не исчезла — пропускаем

-- ═══════════════ СЧЁТЧИК МОНЕТ ИЗ GUI ИГРЫ ═══════════════
-- Игра показывает у игрока число собранных за раунд монет. Путь к этой надписи я заранее не знаю (в открытых источниках его нет),
-- поэтому она находится сама, по калибровке: кандидат — любая числовая надпись в PlayerGui ("12" или "12/40");
-- выбирается та, что на каждую монету, собранную фармом, растёт ровно на +1 и не растёт «сама по себе» (таймер отпадает).
-- Найденный путь запоминается в файле (если есть writefile). Дальше FarmCount = значение счётчика минус значение на старте раунда,
-- а лимит ресета берётся из «n/m», если игра так показывает, иначе FARM_COIN_LIMIT.
-- Если фарм насчитал ≥6 монет, а счётчик не двигается — он отбрасывается и ищется заново. Пока он не найден, работает прежний подсчёт.
local GameCoins = {
    cand = setmetatable({}, { __mode = "k" }), events = {}, label = nil, value = nil, limit = nil, base = 0, own = 0,
    nextScan = 0, nextSample = 0, nextEval = 0, path = nil, lastTxt = "", FILE = "mm2prohub_coinpath.txt",
}
pcall(function() if isfile and readfile and isfile(GameCoins.FILE) then GameCoins.path = readfile(GameCoins.FILE) end end)

function GameCoins.Parse(text)
    if type(text) ~= "string" then return nil end
    local a, b = text:match("^%s*(%d+)%s*/%s*(%d+)%s*$")
    if a then return tonumber(a), tonumber(b) end
    local n = text:match("^%s*(%d+)%s*$")
    if n then return tonumber(n), nil end
    return nil
end

function GameCoins.PathOf(inst)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local parts, o = {}, inst
    while o and o ~= pg do table.insert(parts, 1, o.Name); o = o.Parent end
    if o ~= pg then return nil end
    return table.concat(parts, "/")
end

function GameCoins.Resolve(path)
    local o = LP:FindFirstChildOfClass("PlayerGui")
    for name in string.gmatch(path, "[^/]+") do o = o and o:FindFirstChild(name) end
    return (o and o:IsA("TextLabel")) and o or nil
end

function GameCoins.Scan()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local n = 0
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and not d:IsDescendantOf(SG) then
            local v = GameCoins.Parse(d.Text)
            if v then
                n += 1
                if n > 250 then break end
                if not GameCoins.cand[d] then GameCoins.cand[d] = { v = v, incs = {} } end
            end
        end
    end
end

function GameCoins.Evaluate(now) -- кто растёт ровно на +1 около КАЖДОЙ нашей монеты
    local best, bestGood
    for d, c in pairs(GameCoins.cand) do
        if d.Parent then
            local good, bad = 0, 0
            for _, te in ipairs(GameCoins.events) do
                if now - te > 1.6 then
                    local k = 0
                    for _, ti in ipairs(c.incs) do if math.abs(ti - te) <= 1.5 then k += 1 end end
                    if k == 1 then good += 1 else bad += 1 end
                end
            end
            if good >= 3 and bad <= good * 0.34 and (not bestGood or good > bestGood) then best, bestGood = d, good end
        end
    end
    if best then
        GameCoins.label = best
        GameCoins.path = GameCoins.PathOf(best)
        GameCoins.cand = setmetatable({}, { __mode = "k" })
        if GameCoins.path then pcall(function() if writefile then writefile(GameCoins.FILE, GameCoins.path) end end) end
        Notify("Auto-Farm", L("Счётчик монет в GUI найден"))
    end
end

function GameCoins.Tick(now)
    if now >= GameCoins.nextScan then
        GameCoins.nextScan = now + 3
        if GameCoins.label and not GameCoins.label.Parent then GameCoins.label = nil end
        if not GameCoins.label then
            if GameCoins.path then
                local l = GameCoins.Resolve(GameCoins.path)
                if l and GameCoins.Parse(l.Text) then GameCoins.label = l end
            end
            if not GameCoins.label then GameCoins.Scan() end
        end
    end
    if GameCoins.label then
        local v, m = GameCoins.Parse(GameCoins.label.Text)
        if v then
            GameCoins.value = v
            if m and m >= 10 and m <= 200 then GameCoins.limit = m end
        end
        return
    end
    if now >= GameCoins.nextSample then
        GameCoins.nextSample = now + 0.2
        for d, c in pairs(GameCoins.cand) do
            local v = GameCoins.Parse(d.Text)
            if v then
                if v == c.v + 1 then
                    c.incs[#c.incs + 1] = now
                    if #c.incs > 60 then table.remove(c.incs, 1) end
                end
                c.v = v
            end
        end
        if now >= GameCoins.nextEval then
            GameCoins.nextEval = now + 1
            GameCoins.Evaluate(now)
        end
    end
end

function GameCoins.Count() -- сколько монет в раунде по GUI игры (nil — счётчик не найден)
    if not (GameCoins.label and GameCoins.value) then return nil end
    if GameCoins.value < GameCoins.base then GameCoins.base = 0 end -- игра обнулила счётчик на новом раунде
    local c = GameCoins.value - GameCoins.base
    if GameCoins.own >= 6 and c <= 0 then
        GameCoins.label, GameCoins.path, GameCoins.value, GameCoins.own = nil, nil, nil, 0
        return nil
    end
    return c
end

function GameCoins.OnRoundStart() GameCoins.base, GameCoins.own = GameCoins.value or 0, 0 end

function GameCoins.OwnEvent()
    GameCoins.own += 1
    table.insert(GameCoins.events, os.clock())
    if #GameCoins.events > 12 then table.remove(GameCoins.events, 1) end
end

local FARM_CLEARANCE   = 4  -- на сколько стадов ниже монеты плывём
local FARM_ZONE_MARGIN = 60 -- запас вокруг рамки монет (во время фарма)
local FARM_START_MARGIN = 30 -- запас вокруг рамки монет для СТАРТА фарма (тесный, чтобы не стартовать из лобби)
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
    TpTarget, TpPhase = nil, "slide"
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

local COIN_WORDS = { "coin", "candy", "candies", "treat" }  -- обычные монеты в MM2 называются «Coin»; Candy — событийные
local BAD_WORDS  = { "container", "sound", "spawn", "effect", "particle", "collected" }

local function NameHas(n, list)
    for _, w in ipairs(list) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

-- Деталь-монета для объекта v (или nil). Берём детали (и модели) с «монетным» именем: Coin, Coin_Server, Candy...
-- Деталь-«картинка» (CoinVisual) берём только если именно на ней висит TouchInterest.
local function CoinPartOf(v)
    if not (v:IsA("BasePart") or v:IsA("Model")) then return nil end
    local n = v.Name:lower()
    if n:find("visual", 1, true) and not v:FindFirstChild("TouchInterest") then return nil end
    if NameHas(n, BAD_WORDS) then return nil end
    local named = NameHas(n, COIN_WORDS)
    if v:IsA("BasePart") then
        if named then return v end
        -- деталь с другим именем, но внутри Coin/Candy-папки и с TouchInterest
        local p = v.Parent
        if p and p ~= workspace and v:FindFirstChild("TouchInterest") and NameHas(p.Name:lower(), COIN_WORDS) then return v end
        return nil
    end
    if named then return v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart") end
    return nil
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

-- Что игра пометила как собранное: атрибут Collected (на монете или на её CoinVisual) / имя CollectedCoin
local function IsCollected(part)
    if part:GetAttribute("Collected") == true or part.Name:lower():find("collected", 1, true) then return true end
    local vis = part:FindFirstChild("CoinVisual")
    return vis ~= nil and vis:GetAttribute("Collected") == true
end

local function CoinLive(part)
    return part.Parent ~= nil and part:IsDescendantOf(workspace) and part.CanTouch ~= false and not Taken[part]
        and not IsCollected(part)
end

-- Монета «взята», если после выбора цели с ней произошло хотя бы одно из: удалена / Collected / CanTouch выключен /
-- пропал TouchInterest / стала прозрачной / уехала далеко. Возвращает причину (строку) или nil.
-- Игра может не удалять монету, а просто прятать её, поэтому смотрим не только на Parent.
local function CoinTaken(part, snap)
    if not part.Parent or not part:IsDescendantOf(workspace) then return L("удалена") end
    if IsCollected(part) then return "Collected" end
    if part.CanTouch == false and snap.can ~= false then return "CanTouch" end
    if snap.ti and not part:FindFirstChild("TouchInterest") then return "TouchInterest" end
    if part.Transparency >= snap.tr + 0.5 then return L("прозрачность") end
    if (part.Position - snap.pos).Magnitude > 20 then return L("сдвинута") end
    return nil
end

-- Диагностика, если монет нет: какие маленькие объекты с TouchInterest / «монетным» именем реально есть в игре
local function CoinCandidates()
    local groups = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Size.Magnitude <= 12 and not IsPlayerStuff(v) then
            local nm = v.Name:lower()
            if v:FindFirstChild("TouchInterest") or nm:find("coin", 1, true) or nm:find("candy", 1, true) then
                groups[v.Name] = (groups[v.Name] or 0) + 1
            end
        end
    end
    local list = {}
    for name, c in pairs(groups) do list[#list + 1] = { name, c } end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    local out = {}
    for i = 1, math.min(5, #list) do out[i] = list[i][1] .. "×" .. list[i][2] end
    return table.concat(out, ", ")
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
    local q, m = hrp.Position, FARM_START_MARGIN
    return q.X >= lo.X - m and q.X <= hi.X + m and q.Z >= lo.Z - m and q.Z <= hi.Z + m
        and q.Y >= lo.Y - 40 and q.Y <= hi.Y + 40
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
    local candidates = ""
    local lastEndAt = -1e9
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
            GameCoins.Tick(now)
            local gv = GameCoins.Count() -- число монет из GUI игры, если счётчик найден
            if roundStart and gv then FarmCount = gv end
            local best, bestCost, total, lo, hi = ScanCoins(hrp)
            if total > 0 then emptySince = nil else emptySince = emptySince or now end
            if total == 0 and now >= nextDetect then -- монет нет: раз в 4 с смотрим, что похожее есть в игре (для строки диагностики)
                nextDetect = now + 4
                candidates = CoinCandidates()
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
                        GameCoins.OnRoundStart()
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
                    Notify("Auto-Farm", ended and L("Монеты кончились: жду") or L("Унесло с карты: жду следующий раунд"))
                    lastEndAt = now
                    FarmMode, FarmTarget, HideY, roundStart, armed = "idle", nil, nil, nil, false
                elseif State.FarmReset and FarmCount >= (GameCoins.limit or FARM_COIN_LIMIT) then
                    -- набрали лимит: ресет персонажа, до конца раунда не фармим
                    FarmCount, CountedPos = 0, {}
                    GameCoins.OnRoundStart()
                    Stats.resets += 1
                    sitOut, roundStart = true, nil
                    FarmTarget, FarmMode, HideY = nil, "idle", nil
                    Displaced, HomeCF = false, nil
                    Notify("Auto-Farm", (GameCoins.limit or FARM_COIN_LIMIT) .. " " .. L("монет: ресет"))
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
                                    GameCoins.OwnEvent()
                                    CountedPos[#CountedPos + 1] = sp
                                end
                                -- соседние детали той же монеты (в пределах 3 стадов) тоже считаем взятыми
                                for part in pairs(Coins) do
                                    if (part.Position - sp).Magnitude < 3 then Taken[part] = true end
                                end
                                Taken[FarmTarget] = true
                                LastTakenWhy = why .. (dup and L(" (дубль)") or "") .. (ours and "" or L(" (не наша)"))
                                FarmTarget = nil
                            end
                        end
                        if FarmTarget and (not CoinLive(FarmTarget) or (CoinSkip[FarmTarget] or 0) > now) then
                            FarmTarget = nil -- монету подобрали: следующая берётся в этот же кадр, без паузы
                        end
                        if not FarmTarget then FarmPhase = "cruise"; TpTarget, TpPhase = nil, "slide" end -- цели нет: сбрасываем фазу Teleport
                        if not best and total > 0 then -- монеты есть, но все временно пропущены: снимаем пропуски и ищем заново
                            for k in pairs(CoinSkip) do CoinSkip[k] = nil end
                            best, bestCost = ScanCoins(hrp)
                        end
                        if FarmPhase ~= "reach" and (TpPhase ~= "grab" or not FarmTarget) and best then -- пока стоим на монете, цель не меняем; без цели выбор свободен
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
                total, FarmCount, (GameCoins.limit or FARM_COIN_LIMIT), signal and L("да") or L("нет"), (roundStart or onMap) and L("да") or L("нет"), LastTakenWhy)
            if State.FarmMethod == "teleport" then
                local skipped = 0
                for _, u in pairs(CoinSkip) do if u > now then skipped += 1 end end
                dbg = dbg .. string.format("   ·   TP: фаза %s, скорость %s, попыток %d, пропущено %d, firetouchinterest: %s",
                    tostring(TpPhase), State.TpInstant and "inf" or tostring(State.TpSpeed), TpTries, skipped, firetouchinterest and "да" or "НЕТ")
            end
            if total == 0 and candidates ~= "" then dbg = dbg .. L("   ·   Похожие объекты: ") .. candidates end
            if dbg ~= lastDebug then lastDebug = dbg; FarmDebug.Text = dbg end
            local gtxt = L("Счётчик монет в GUI: ") .. (GameCoins.label
                and (tostring(GameCoins.path or "?") .. " = " .. tostring(GameCoins.value or "?") .. (GameCoins.limit and ("/" .. GameCoins.limit) or ""))
                or L("калибруется: нужно 3 собранные монеты"))
            if gtxt ~= GameCoins.lastTxt then GameCoins.lastTxt = gtxt; Fav.GuiInfo.Text = gtxt end

            local short
            if FarmTarget then short = L("Собираю монеты")
            elseif FarmMode == "warmup" and roundStart then short = L("Старт раунда…")
            elseif FarmMode == "collect" then short = L("Монет нет")
            elseif sitOut then short = L("Ждём новый раунд")
            elseif signal and not onMap then short = L("Не на карте")
            else short = L("Ждём раунд") end
            UpdateFarmUI(short, FarmCount, (GameCoins.limit or FARM_COIN_LIMIT), FarmTarget ~= nil)
        else
            if not State.AutoFarm then
                if Displaced then ReturnHome() end -- выключили посреди раунда: возвращаем наверх
                armed, roundStart = true, nil
                FarmStatus.Text = L("Статус: выключено")
            else
                FarmStatus.Text = L("Мёртв / нет персонажа: фарм отключён")
            end
            if lastDebug ~= "—" then lastDebug = "—"; FarmDebug.Text = "—" end
            UpdateFarmUI(State.AutoFarm and L("Мёртв / нет персонажа") or nil, FarmCount, (GameCoins.limit or FARM_COIN_LIMIT), false)
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
        if jump > 12 and not ((jump < 80 or State.FarmMethod == "teleport") and InZone(hrp.Position, ZoneLo, ZoneHi)) then
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
        if FarmMode == "collect" and target and target:IsDescendantOf(workspace)
            and State.FarmMethod == "teleport" and HideY then
            -- Teleport: настоящий телепорт, без пауз и таймеров. Прыжок к монете не длиннее State.TpSpeed*dt (без тумблера «мгновенно»; в v4.8 без ограничения кикало, текст кика я не видел), одно касание,
            -- стоим на ней, пока она не исчезнет (это подтверждение от сервера: ждём событие, а не время), и в тот же кадр берём
            -- следующую. Единственный предохранитель — TP_STUCK: если монета не исчезла за 2 с, пропускаем её.
            local t = os.clock()
            local cp = target.Position
            local flat = Vector3.new(cp.X - pos.X, 0, cp.Z - pos.Z)
            if flat.Magnitude > 0.3 then FarmHeading = flat.Unit end
            if target ~= TpTarget then TpTarget, TpPhase, TpUntil, TpTries = target, "slide", 0, 0 end
            goal, speed = cp, State.TpInstant and math.huge or State.TpSpeed -- прыжок не длиннее TpSpeed*dt (без «мгновенно»)
            if TpPhase ~= "grab" then
                if (pos - cp).Magnitude < 0.75 then -- долетели: встаём на монету, запускаем предохранитель
                    TpPhase, TpUntil, TpTries = "grab", t + TP_STUCK, TpTries + 1
                    ReachedTarget = target
                end
            elseif t >= TpUntil then -- монета не исчезла за TP_STUCK: пропускаем ненадолго, идём к следующей
                CoinSkip[target] = t + 1.5
                FarmTarget, TpTarget, TpPhase = nil, nil, "slide"
            end
            -- пока стоим на монете, касаемся её КАЖДЫЙ кадр (так же «жёстко», как в подборе пистолета)
            if TpPhase == "grab" and firetouchinterest then
                pcall(function()
                    firetouchinterest(hrp, target, 0)
                    firetouchinterest(hrp, target, 1)
                end)
            end
            pitchTarget = math.pi / 2
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
                    goal, speed = down, State.TpInstant and math.huge or State.TpSpeed -- Teleport: под пол тем же ограниченным прыжком
                    pitchTarget = 0
                else
                    goal = down -- Touch: только вниз, лёжа
                end
            end
        end

        FarmPitch += math.clamp(pitchTarget - FarmPitch, -FARM_PITCH_RATE * dt, FARM_PITCH_RATE * dt)
        local stepDt = (State.FarmMethod == "teleport") and math.min(dt, 1 / 30) or dt -- после просадки FPS прыжок не раздуваем
        if goal then
            local delta = goal - pos
            local dist = delta.Magnitude
            if dist > 0.02 then pos += delta.Unit * math.min(speed * stepDt, dist) end
        end
        local hopLen = (pos - hrp.Position).Magnitude -- длина этого шага (для журнала киков)
        local nowc = os.clock()
        if nowc - (State.dbgHopT or 0) > 2 then State.dbgHopMax, State.dbgHopT = 0, nowc end
        State.dbgHop = hopLen
        if hopLen > (State.dbgHopMax or 0) then State.dbgHopMax = hopLen end
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
local GUN_DWELL = 0.06 -- сколько держим персонажа на пистолете (в турбо-режиме меньше)

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
        task.wait()
        -- зажми G: турбо-подбор (работает и при выключенном авто-подборе; только в раунде)
        local held = UserInputService:IsKeyDown(Enum.KeyCode.G) and not UserInputService:GetFocusedTextBox()
        if (State.AutoGun or held) and not GunBusy and os.clock() >= cooldownUntil then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and GetRole(LP) == "Innocent" then -- убийце и обладателю пистолета не нужно
                local gun
                for part in pairs(GunDrops) do
                    if part.Parent and part:IsDescendantOf(workspace) and (GunTries[part] or 0) < (held and 25 or 8) then gun = part; break end
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
                        local dwell, t0 = held and 0.03 or GUN_DWELL, os.clock()
                        repeat -- «жёстко»: каждый кадр заново ставим на пистолет и касаемся
                            hrp.CFrame = CFrame.new(gun.Position)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            if firetouchinterest then
                                firetouchinterest(hrp, gun, 0)
                                firetouchinterest(hrp, gun, 1)
                            end
                            task.wait()
                        until os.clock() - t0 >= dwell or not gun.Parent
                    end)
                    pcall(function()
                        if hrp.Parent then
                            hrp.CFrame = back
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                    end)
                    GunBusy = false
                    cooldownUntil = os.clock() + (held and 0.05 or 0.25)
                    if not held then Notify(L("Авто-подбор"), L("Пистолет: попытка ") .. GunTries[gun]) end
                end
            end
        end
    end
end)

-- ═══════════════ НЕВИДИМКА (локальная копия-призрак) ═══════════════
-- Настоящее тело уходит далеко «за карту» (его видят другие), а у тебя на экране полупрозрачная копия, которой ты управляешь.
-- Копия существует только на твоём клиенте. Игра переставила настоящее тело (старт раунда, телепорт) — копия идёт туда же.
-- При выключении настоящее тело ставится туда, где стоит копия. ЭВРИСТИКА: в игре не проверена, анимации копии — стандартные Roblox по памяти.
Invis.alpha = 0.55
Invis.anim = {
    R15 = { idle = "rbxassetid://507766666", walk = "rbxassetid://507777826" },
    R6  = { idle = "rbxassetid://180435571", walk = "rbxassetid://180426354" },
}

function Invis.Hide(pos) -- куда уводим настоящее тело: за дальний край карты (по монетам), иначе просто далеко
    local hx, hz, ly
    for part in pairs(Coins) do
        if part.Parent then
            local q = part.Position
            hx = hx and math.max(hx, q.X) or q.X
            hz = hz and math.max(hz, q.Z) or q.Z
            ly = ly and math.min(ly, q.Y) or q.Y
        end
    end
    if hx then return Vector3.new(hx + 300, ly, hz + 300) end
    return pos + Vector3.new(0, 0, 700)
end

function Invis.Disable(restore)
    if not Invis.on then return end
    Invis.on = false
    if Invis.conn then Invis.conn:Disconnect(); Invis.conn = nil end
    local char = Invis.char
    local rhrp = char and char:FindFirstChild("HumanoidRootPart")
    local rhum = char and char:FindFirstChildOfClass("Humanoid")
    if restore and rhrp and Invis.gcf then
        rhrp.CFrame = Invis.gcf -- тело встаёт туда, где стояла копия
        rhrp.AssemblyLinearVelocity = Vector3.zero
    end
    local cam = workspace.CurrentCamera
    if cam and rhum then cam.CameraSubject = rhum end
    if Invis.clone then Invis.clone:Destroy() end
    Invis.clone, Invis.char, Invis.ghum, Invis.ghrp = nil, nil, nil, nil
    Invis.idle, Invis.walk, Invis.playing = nil, nil, nil
end

function Invis.Enable()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then Notify(L("Невидимка"), L("Нет живого персонажа")); return end
    char.Archivable = true
    local ok, clone = pcall(function() return char:Clone() end)
    local ghrp = ok and clone and clone:FindFirstChild("HumanoidRootPart")
    local ghum = ok and clone and clone:FindFirstChildOfClass("Humanoid")
    if not (ghrp and ghum) then Notify(L("Невидимка"), L("Копию создать не удалось")); return end
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then
            d:Destroy() -- копия не должна выполнять чужие скрипты
        elseif d:IsA("BasePart") then
            d.Transparency = (d.Name == "HumanoidRootPart") and 1 or Invis.alpha
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = Invis.alpha
        end
    end
    clone.Name = "ProGhost"
    clone.PrimaryPart = ghrp
    ghum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    clone.Parent = workspace -- создана на клиенте: другие игроки её не видят

    -- простые анимации копии (иначе она скользит без движений ног)
    local animator = ghum:FindFirstChildOfClass("Animator")
    if not animator then animator = Instance.new("Animator"); animator.Parent = ghum end
    local set = Invis.anim[ghum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"]
    local function load(id)
        local a = Instance.new("Animation")
        a.AnimationId = id
        local okTrack, track = pcall(function() return animator:LoadAnimation(a) end)
        if okTrack and track then track.Looped = true; return track end
        return nil
    end
    Invis.idle, Invis.walk, Invis.playing = load(set.idle), load(set.walk), nil

    local cam = workspace.CurrentCamera
    if cam then cam.CameraSubject = ghum end
    Invis.hide = Invis.Hide(hrp.Position)
    hrp.CFrame = CFrame.new(Invis.hide) -- настоящее тело уходит за карту
    hrp.AssemblyLinearVelocity = Vector3.zero
    Invis.char, Invis.clone, Invis.ghum, Invis.ghrp, Invis.gcf, Invis.on = char, clone, ghum, ghrp, ghrp.CFrame, true

    Invis.conn = RunService.Stepped:Connect(function()
        local rchar = LP.Character
        local rhrp = rchar and rchar:FindFirstChild("HumanoidRootPart")
        local rhum = rchar and rchar:FindFirstChildOfClass("Humanoid")
        if not (Invis.on and rchar == Invis.char and rhrp and rhum and rhum.Health > 0) then
            Invis.Disable(false) -- умерли / респавн: восстанавливать нечего
            return
        end
        local g, gh = Invis.ghrp, Invis.ghum
        if not (g and g.Parent and gh and gh.Health > 0) then
            Invis.Disable(true) -- копия пропала: тело встаёт на её последнее место
            return
        end
        -- игра переставила настоящее тело (старт раунда / телепорт): копия идёт туда же, тело снова уводим за карту
        if (rhrp.Position - Invis.hide).Magnitude > 8 then
            g.CFrame = rhrp.CFrame
            Invis.hide = Invis.Hide(rhrp.Position)
        end
        rhrp.CFrame = CFrame.new(Invis.hide)
        rhrp.AssemblyLinearVelocity = Vector3.zero
        rhrp.AssemblyAngularVelocity = Vector3.zero

        -- управление копией: берём направление движения у настоящего Humanoid
        local cam2 = workspace.CurrentCamera
        if cam2 and cam2.CameraSubject ~= gh then cam2.CameraSubject = gh end
        gh.WalkSpeed = rhum.WalkSpeed
        pcall(function() gh.JumpPower = rhum.JumpPower end)
        local md = rhum.MoveDirection
        gh:Move(md, false)
        if rhum.Jump then gh.Jump = true end
        Invis.gcf = g.CFrame

        local moving = md.Magnitude > 0.1
        local want = moving and Invis.walk or Invis.idle
        if want and Invis.playing ~= want then
            if Invis.playing then Invis.playing:Stop(0.15) end
            want:Play(0.15)
            Invis.playing = want
        end
        if moving and Invis.walk then Invis.walk:AdjustSpeed(math.max(0.3, gh.WalkSpeed / 16)) end
    end)
end

function Invis.Set(on)
    if on == Invis.on then return end
    if on then Invis.Enable() else Invis.Disable(true) end
end

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
                -- рамка накапливается и не сжимается, когда монеты собирают
                local lo, hi = ESPZone.lo, ESPZone.hi
                for part in pairs(Coins) do
                    if part.Parent then
                        local q = part.Position
                        lo = lo and Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z)) or q
                        hi = hi and Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z)) or q
                    end
                end
                ESPZone.lo, ESPZone.hi = lo, hi
            elseif now - lastCoinSeen > 5 then
                ESPZone.lo, ESPZone.hi = nil, nil -- раунд закончился: рамку и роли сбрасываем
                for k in pairs(RoleMemo) do RoleMemo[k] = nil end
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
                    -- «в раунде» = стоит внутри рамки монет раунда или уже выдана роль; иначе он в лобби
                    local inRound = role ~= "Innocent" or ServerIn[p.Name] == true -- роль выдана сервером = уже в раунде (серый «лобби» только у остальных)
                    local zlo, zhi, m = ESPZone.lo, ESPZone.hi, ESPZone.m
                    if not inRound and zlo and phrp then
                        local q = phrp.Position
                        inRound = q.X >= zlo.X - m and q.X <= zhi.X + m
                            and q.Y >= zlo.Y - m and q.Y <= zhi.Y + m
                            and q.Z >= zlo.Z - m and q.Z <= zhi.Z + m
                    end
                    local color = Color3.fromRGB(150, 150, 150) -- лобби: серый, без ника
                    if inRound then
                        color = Color3.fromRGB(0, 255, 0)
                        if role == "Murderer" then color = Color3.fromRGB(255, 0, 0) end
                        if role == "Sheriff" then color = Color3.fromRGB(0, 100, 255) end
                    end
                    hl.FillColor, hl.OutlineColor = color, color
                    if nb then nb.Enabled = inRound end -- ник виден только у тех, кто в раунде
                    local lbl = nb and nb:FindFirstChild("Label")
                    if lbl then lbl.TextColor3 = color end
                end
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do ClearESP(p) end
    end
end)

-- ═══════════════ ЖУРНАЛ КИКОВ ═══════════════
-- Что именно написала игра при кике, я отсюда не вижу, поэтому оно записывается: сообщение + состояние фарма в момент кика.
-- Файл mm2prohub_kicklog.txt (нужен writefile). При следующем запуске последний кик показывается на вкладке «Фарм».
do
    local FILE = "mm2prohub_kicklog.txt"
    local GuiService = game:GetService("GuiService")
    local lastMsg = ""
    local function Record(msg)
        msg = tostring(msg or "")
        msg = msg:gsub("[\r\n]+", " ")
        if msg == "" or msg == lastMsg then return end
        lastMsg = msg
        local lp = LastSet and string.format("%.0f,%.0f,%.0f", LastSet.X, LastSet.Y, LastSet.Z) or "nil"
        local line = string.format("[%s] %s | autofarm=%s method=%s touchSpeed=%s tpSpeed=%s mode=%s coins=%s pos=%s hideY=%s tpPhase=%s lastHop=%.0f maxHop2s=%.0f",
            os.date("%Y-%m-%d %H:%M:%S"), msg, tostring(State.AutoFarm), tostring(State.FarmMethod), tostring(State.FarmFlySpeed), State.TpInstant and "instant" or tostring(State.TpSpeed),
            tostring(FarmMode), tostring(FarmCount), lp, HideY and string.format("%.0f", HideY) or "nil", tostring(TpPhase),
            State.dbgHop or 0, State.dbgHopMax or 0)
        pcall(function()
            if not writefile then return end
            local old = (isfile and readfile and isfile(FILE)) and readfile(FILE) or ""
            if #old > 4000 then old = old:sub(-3000) end
            writefile(FILE, old .. line .. "\n")
        end)
    end
    Connect(GuiService.ErrorMessageChanged, function()
        local ok, msg = pcall(function() return GuiService:GetErrorMessage() end)
        if ok then Record(msg) end
    end)
    task.spawn(function()
        pcall(function()
            local pg = CoreGui:WaitForChild("RobloxPromptGui", 20)
            local ov = pg and pg:WaitForChild("promptOverlay", 20)
            if not ov then return end
            Connect(ov.ChildAdded, function(c)
                if c.Name ~= "ErrorPrompt" then return end
                task.wait(0.2)
                local lbl = c:FindFirstChild("ErrorMessage", true)
                Record(lbl and lbl.Text or "ErrorPrompt")
            end)
        end)
    end)
    local lastLine
    pcall(function()
        if isfile and readfile and isfile(FILE) then
            local txt = readfile(FILE)
            for ln in txt:gmatch("[^\n]+") do lastLine = ln end
        end
    end)
    AddInfo(PageFarm, L("Последний кик: ") .. (lastLine and lastLine:sub(1, 200) or L("не записано")), 58)
    if lastLine then Notify(L("Последний кик"), lastLine:sub(1, 90)) end
    if State.TpAutoNote == "lowered" then
        Notify("Teleport", string.format(L("Скорость Teleport снижена до %d (кик по позиции)"), State.TpSpeed))
    elseif State.TpAutoNote == "min" then
        Notify("Teleport", L("Скорость Teleport на минимуме: причина кика, видимо, не в длине прыжка"))
    end
end

-- ═══════════════ СТАРТ ═══════════════
Fav.RestorePins() -- закрепы из прошлой сессии (интерфейс уже построен)
SelectTab("Основное")
task.spawn(RunIntro) -- интро само раскроет окно и покажет уведомление «Загружен»

end

-- ═══════════════ ПРОВЕРКА КЛЮЧА (по окончанию) / ФАЙЛ КЛЮЧА ═══════════════
-- Ключ вида MM2-XXXXXX-XXXXXX-ОКОНЧАНИЕ. Скрипт принимает ключ, только если его последние 6 символов есть в списке ниже.
-- Список окончаний вписывает бот при создании файла (команда /script); бот выдаёт ключи только с этими окончаниями.
local KEY_ENDINGS = { 
    ["27PQKK"]=true, ["2CRKM3"]=true, ["2HGSBA"]=true, ["2NNHWR"]=true, ["2U9ZNF"]=true, ["33THGR"]=true,
    ["36EPLU"]=true, ["3CX4EK"]=true, ["3DSNL8"]=true, ["3E7MUM"]=true, ["3KVHAU"]=true, ["3QGSJ6"]=true,
    ["3QJT3Q"]=true, ["3QL45V"]=true, ["3RDA2N"]=true, ["3SSFFB"]=true, ["3SZBFQ"]=true, ["3V62RP"]=true,
    ["49DAWR"]=true, ["4AAHZP"]=true, ["4B4XRM"]=true, ["4JAR85"]=true, ["4L5XVW"]=true, ["52DCD5"]=true,
    ["52XPRV"]=true, ["53YUW8"]=true, ["55SYTS"]=true, ["55VF9V"]=true, ["5AKLVW"]=true, ["5EA4UB"]=true,
    ["5JHST9"]=true, ["5RE7CS"]=true, ["5SNVAU"]=true, ["5VPN44"]=true, ["62SVMA"]=true, ["6C8PWL"]=true,
    ["6CUYNK"]=true, ["6Q4JAR"]=true, ["6XSDV2"]=true, ["762EXV"]=true, ["78STGZ"]=true, ["7ADFPD"]=true,
    ["7CAX4T"]=true, ["7CKKSQ"]=true, ["7DBFR5"]=true, ["7EJYXS"]=true, ["7J7NLS"]=true, ["7TSD8R"]=true,
    ["839BGP"]=true, ["83UWRP"]=true, ["8AAFLS"]=true, ["8JQB2H"]=true, ["8MEHNC"]=true, ["8QSHUZ"]=true,
    ["95A5AA"]=true, ["9799L5"]=true, ["98NE5D"]=true, ["9DRBXG"]=true, ["9HWXZE"]=true, ["9LQ6PD"]=true,
    ["9Q4UQK"]=true, ["9TN5P7"]=true, ["9WR937"]=true, ["A33L39"]=true, ["A6C9K5"]=true, ["A6ZVD6"]=true,
    ["AC9HCT"]=true, ["ADXQSG"]=true, ["AEB87Y"]=true, ["AMLR2Y"]=true, ["APRRPC"]=true, ["APW6YV"]=true,
    ["ATF5AQ"]=true, ["AWPTNN"]=true, ["AX3BW9"]=true, ["B7AFW3"]=true, ["BCKA8U"]=true, ["BE7SAQ"]=true,
    ["BEB92P"]=true, ["BGD5XC"]=true, ["BQR4A7"]=true, ["BT5MBC"]=true, ["BTN24B"]=true, ["BZMW9M"]=true,
    ["C22Z86"]=true, ["C7TRJV"]=true, ["C8SMY6"]=true, ["C9E54L"]=true, ["CALD9L"]=true, ["CDLZBU"]=true,
    ["CG5L2Q"]=true, ["CGM57R"]=true, ["CGS6JF"]=true, ["CHUFBM"]=true, ["CHYPBN"]=true, ["CHYVRS"]=true,
    ["CMB7KP"]=true, ["CYEFJ9"]=true, ["CZ8GTQ"]=true, ["D58VNW"]=true, ["D5AFJK"]=true, ["D5SJ89"]=true,
    ["DL3SJC"]=true, ["DSM6XZ"]=true, ["DTC7TH"]=true, ["DVG53X"]=true, ["DW3CLF"]=true, ["DYZWR6"]=true,
    ["E25V4S"]=true, ["E7Z5HJ"]=true, ["ED2ARY"]=true, ["EDHLTP"]=true, ["EH45DG"]=true, ["EKNFCR"]=true,
    ["ENMG64"]=true, ["EQMHJX"]=true, ["ES2J4T"]=true, ["ESJKVH"]=true, ["ETBNMX"]=true, ["EUM37K"]=true,
    ["F3JP5D"]=true, ["FATLWP"]=true, ["FCBBK7"]=true, ["FCBHPN"]=true, ["FJN7QU"]=true, ["FJQK9S"]=true,
    ["FMAXHC"]=true, ["FNK468"]=true, ["FNRLUK"]=true, ["FZSDTP"]=true, ["G36JEU"]=true, ["G3CNWV"]=true,
    ["GCD3HZ"]=true, ["GHNLVM"]=true, ["GT96RR"]=true, ["GUSY4L"]=true, ["H254GM"]=true, ["H28DUT"]=true,
    ["H37Z83"]=true, ["H7Y4LA"]=true, ["HA7FPR"]=true, ["HAAKSS"]=true, ["HDSUM4"]=true, ["HHA2PW"]=true,
    ["HHUHAX"]=true, ["HJBTCZ"]=true, ["HNE25J"]=true, ["HPEKGV"]=true, ["HRLJ2E"]=true, ["HSCG6L"]=true,
    ["J2ZBVY"]=true, ["J3ZU2J"]=true, ["J72XNY"]=true, ["JAYDFQ"]=true, ["JFE3VJ"]=true, ["JGRMMB"]=true,
    ["JS6F87"]=true, ["JVP2BT"]=true, ["K7H6LS"]=true, ["K9ZPP4"]=true, ["KE56H9"]=true, ["KHFPTQ"]=true,
    ["KJNYGM"]=true, ["KJVZK2"]=true, ["KJY629"]=true, ["KLQEJ6"]=true, ["KLU7L7"]=true, ["KURD2P"]=true,
    ["KY6MA6"]=true, ["L7A4V3"]=true, ["LDR9TB"]=true, ["LJSQBG"]=true, ["LPUTPF"]=true, ["LQWQVT"]=true,
    ["LSFFBP"]=true, ["LTTUZG"]=true, ["LX5EDH"]=true, ["LY4RHG"]=true, ["LY899H"]=true, ["M4ZV6N"]=true,
    ["MJGNDF"]=true, ["MK2FWX"]=true, ["ML3EZC"]=true, ["MMZF6K"]=true, ["MSUF75"]=true, ["MUV6XZ"]=true,
    ["MYVLDL"]=true, ["N2PSUL"]=true, ["N588T9"]=true, ["N9KS4B"]=true, ["NDXJ5P"]=true, ["NH6TB3"]=true,
    ["NVTJDS"]=true, ["NYJXPE"]=true, ["P38UDC"]=true, ["PA4ZVT"]=true, ["PLR3FV"]=true, ["PMQ5JF"]=true,
    ["PUEU8L"]=true, ["PVZYST"]=true, ["Q26S6G"]=true, ["Q2FNZ6"]=true, ["Q5BNNF"]=true, ["Q7N22T"]=true,
    ["QAQB87"]=true, ["QBN4YZ"]=true, ["QTZ6A8"]=true, ["QWM2DP"]=true, ["QWVXM2"]=true, ["QXTEYY"]=true,
    ["R36Y3Z"]=true, ["R3KEKM"]=true, ["R48XQM"]=true, ["R7T7BX"]=true, ["R83FPK"]=true, ["R9PZL4"]=true,
    ["RCT3S2"]=true, ["RFZH8M"]=true, ["RMP8GS"]=true, ["RS2MGV"]=true, ["RSSX9F"]=true, ["S2FXJZ"]=true,
    ["SFE7KC"]=true, ["SSXZEY"]=true, ["SUMK4F"]=true, ["SXCWLA"]=true, ["SZM2MU"]=true, ["T2KQJS"]=true,
    ["T43Z8D"]=true, ["T52AC4"]=true, ["T6TXGL"]=true, ["T7ALMS"]=true, ["T8R6G9"]=true, ["TE8B2G"]=true,
    ["TEJY7L"]=true, ["TJ5V39"]=true, ["TJB8YK"]=true, ["TUXP65"]=true, ["TVCDCJ"]=true, ["TVQGVK"]=true,
    ["TYKQ8F"]=true, ["TZGNPZ"]=true, ["U3SEML"]=true, ["U55FDL"]=true, ["U8CJ6F"]=true, ["UUHA3A"]=true,
    ["UVHGL2"]=true, ["UXMN82"]=true, ["UZ8PK5"]=true, ["V5247T"]=true, ["V9SYKF"]=true, ["VL7C72"]=true,
    ["VM8FQ8"]=true, ["VTG6PE"]=true, ["VX528D"]=true, ["W8WS2X"]=true, ["W9Q68F"]=true, ["WACK5G"]=true,
    ["WF9JMK"]=true, ["WG7TH3"]=true, ["WGEQRR"]=true, ["WJ56NU"]=true, ["WMDLGX"]=true, ["WMFDHN"]=true,
    ["WSQEYD"]=true, ["WWY547"]=true, ["WZN7MQ"]=true, ["X39ABT"]=true, ["X74VXT"]=true, ["X8U7T3"]=true,
    ["X9W5AB"]=true, ["XDAZ4S"]=true, ["XE64VP"]=true, ["XJEXPU"]=true, ["XPEMF5"]=true, ["XUWY2N"]=true,
    ["XY23G8"]=true, ["XYPGPR"]=true, ["Y7FXXN"]=true, ["Y7Z68Y"]=true, ["Y8B5YV"]=true, ["Y8CQ93"]=true,
    ["Y9K552"]=true, ["YBMVVQ"]=true, ["YCYBVQ"]=true, ["YKXPT7"]=true, ["YLZKP5"]=true, ["YZBKUR"]=true,
    ["Z4EXV4"]=true, ["Z6S7AD"]=true, ["Z8FW5G"]=true, ["Z9YUH2"]=true, ["ZC8GXP"]=true, ["ZH67R5"]=true,
    ["ZH67UX"]=true, ["ZKAS3W"]=true, ["ZQGB6V"]=true, ["ZTLCH4"]=true, ["ZZEVKP"]=true, ["ZZXUKS"]=true,
 }
local KEY_ALPHABET_PATTERN = "^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]+$"

-- возвращает: ok, сообщение
local function VerifyKey(raw)
    local k = tostring(raw):upper():gsub("[%s%-]", "")
    if k:sub(1, 3) ~= "MM2" or #k ~= 21 or not k:sub(4):match(KEY_ALPHABET_PATTERN) then
        return false, L("Неверный формат ключа")
    end
    if KEY_ENDINGS[k:sub(-6)] ~= true then return false, L("Ключ недействителен") end
    return true, L("Ключ принят")
end


local function SavedKey()
    local ok, k = pcall(function()
        if isfile and readfile and isfile(KEY_FILE) then return readfile(KEY_FILE) end
    end)
    return ok and type(k) == "string" and k:gsub("%s+", "") or ""
end
local function SaveKey(k)
    pcall(function() if writefile then writefile(KEY_FILE, k) end end)
end

-- ═══════════════ ОКНО ВВОДА КЛЮЧА ═══════════════
local old = CoreGui:FindFirstChild("MM2ProHubKey")
if old then old:Destroy() end
local SG = New("ScreenGui", { Name = "MM2ProHubKey", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
if not pcall(function() SG.Parent = CoreGui end) then SG.Parent = LP:WaitForChild("PlayerGui") end

local Win = New("Frame", {
    Size = UDim2.new(0, 400, 0, 322), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = SG,
})
Corner(Win, 8)
Stroke(Win)
local WinScale = New("UIScale", { Scale = 0.94, Parent = Win })
do
    local vp = SG.AbsoluteSize
    local fit = (vp.X > 1 and vp.Y > 1) and math.clamp(math.min(vp.X / 440, vp.Y / 340), 0.5, 1) or 1
    Tween(WinScale, 0.35, { Scale = fit }, Enum.EasingStyle.Quint)
end
New("ImageLabel", {
    Size = UDim2.new(1, 50, 1, 50), Position = UDim2.new(0, -25, 0, -25), BackgroundTransparency = 1,
    Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0, Parent = Win,
})

-- шапка
local Head = New("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, Parent = Win })
local icon = New("Frame", { Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 20, 0, 12), BorderSizePixel = 0, Parent = Head })
Corner(icon, 8)
BuildLogo(icon, 8)
New("TextLabel", {
    Size = UDim2.new(1, -140, 0, 20), Position = UDim2.new(0, 72, 0, 13), BackgroundTransparency = 1,
    Text = "MURDER MYSTERY 2", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Head,
})
New("TextLabel", {
    Size = UDim2.new(1, -140, 0, 14), Position = UDim2.new(0, 72, 0, 34), BackgroundTransparency = 1,
    Text = L("PRO HUB  ·  Активация"), TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Head,
})
local CloseBtn = New("TextButton", {
    Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -40, 0, 20), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
    AutoButtonColor = false, Text = "×", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 16, Parent = Head,
})
Corner(CloseBtn, 5)
CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, 0.12, { BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Text }) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, 0.12, { BackgroundColor3 = Theme.Bg, TextColor3 = Theme.TextDim }) end)
New("Frame", { Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 1, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = Head })

-- перетаскивание за шапку
do
    local dragging, dragStart, startPos
    local function press(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
    Head.InputBegan:Connect(function(i)
        if press(i) then dragging, dragStart, startPos = true, i.Position, Win.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = (i.Position - dragStart) / WinScale.Scale
            Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i) if press(i) then dragging = false end end)
end

-- поле ввода
New("TextLabel", {
    Size = UDim2.new(1, -40, 0, 16), Position = UDim2.new(0, 20, 0, 84), BackgroundTransparency = 1,
    Text = L("КЛЮЧ ДОСТУПА"), TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = Win,
})
local InputWrap = New("Frame", {
    Size = UDim2.new(1, -40, 0, 44), Position = UDim2.new(0, 20, 0, 104), BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0, Parent = Win,
})
Corner(InputWrap, 6)
local InputStroke = Stroke(InputWrap)
local Box = New("TextBox", {
    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
    Text = "", PlaceholderText = "MM2-XXXX-XXXX-XXXX", PlaceholderColor3 = Theme.TextDim, TextColor3 = Theme.Text,
    Font = Enum.Font.Code, TextSize = 16, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = InputWrap,
})
Box.Focused:Connect(function() Tween(InputStroke, 0.12, { Color = Theme.Accent }) end)
Box.FocusLost:Connect(function() Tween(InputStroke, 0.12, { Color = Theme.Border }) end)

local Status = New("TextLabel", {
    Size = UDim2.new(1, -40, 0, 32), Position = UDim2.new(0, 20, 0, 156), BackgroundTransparency = 1,
    Text = L("Вставь ключ из Telegram-бота"), TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = Win,
})
local function SetStatus(text, color)
    Status.Text = text
    Status.TextColor3 = color or Theme.TextDim
end

local Go = New("TextButton", {
    Size = UDim2.new(1, -40, 0, 42), Position = UDim2.new(0, 20, 0, 198), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
    AutoButtonColor = false, Text = L("Активировать"), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 14, Parent = Win,
})
Corner(Go, 6)
Go.MouseEnter:Connect(function() Tween(Go, 0.12, { BackgroundTransparency = 0.15 }) end)
Go.MouseLeave:Connect(function() Tween(Go, 0.12, { BackgroundTransparency = 0 }) end)

local GetKey = New("TextButton", {
    Size = UDim2.new(1, -40, 0, 34), Position = UDim2.new(0, 20, 0, 250), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
    AutoButtonColor = false, Text = L("Получить ключ (ссылка на бота)"), TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium,
    TextSize = 12, Parent = Win,
})
Corner(GetKey, 6)
Stroke(GetKey)
GetKey.MouseEnter:Connect(function() Tween(GetKey, 0.12, { BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text }) end)
GetKey.MouseLeave:Connect(function() Tween(GetKey, 0.12, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextDim }) end)
GetKey.MouseButton1Click:Connect(function()
    local ok = pcall(function() setclipboard(BOT_LINK) end)
    GetKey.Text = ok and L("Ссылка скопирована: ") .. BOT_LINK or BOT_LINK
    task.delay(3, function() if GetKey.Parent then GetKey.Text = L("Получить ключ (ссылка на бота)") end end)
end)

New("TextLabel", { -- подпись автора
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -24), BackgroundTransparency = 1, Text = "By shebx436",
    TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 12, Parent = Win,
})

CloseBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

-- ═══════════════ ПРОВЕРКА КЛЮЧА И ЗАПУСК СКРИПТА ═══════════════
local busy = false
local function Activate(raw)
    if busy then return end
    local trimmed = tostring(raw or ""):gsub("%s+", "")
    if trimmed == "" then return SetStatus(L("Введи ключ"), Theme.Danger) end
    if next(KEY_ENDINGS) == nil then
        return SetStatus(L("В скрипте нет окончаний ключей: возьми готовый файл у бота (команда /script)"), Theme.Danger)
    end
    busy = true
    Go.Text = L("Проверка…")
    task.spawn(function()
        local pok, ok, msg = pcall(VerifyKey, trimmed)
        busy = false
        Go.Text = L("Активировать")
        if not pok then return SetStatus(L("Ошибка проверки: ") .. tostring(ok), Theme.Danger) end
        if not ok then return SetStatus(tostring(msg), Theme.Danger) end
        SaveKey(trimmed)
        SetStatus(L("Ключ принят"), Theme.Good)
        task.wait(0.6)
        SG:Destroy()
        RunHub()
    end)
end

Go.MouseButton1Click:Connect(function() Activate(Box.Text) end)
Box.FocusLost:Connect(function(enter) if enter then Activate(Box.Text) end end)

-- сохранённый ключ проверяем сам
do
    local saved = SavedKey()
    if saved ~= "" then
        Box.Text = saved
        SetStatus(L("Проверяю сохранённый ключ…"), Theme.TextDim)
        task.delay(0.5, function() if SG.Parent then Activate(saved) end end)
    end
end
