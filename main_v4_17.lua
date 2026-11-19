--[[
    MM2 PRO HUB v4.14  |  один файл: проверка ключа + скрипт
    Ключ проверяется прямо в скрипте: его последние 6 символов должны быть в списке KEY_ENDINGS.
    Готовый файл со списком окончаний выдаёт бот командой /script; ключи создаёт бот командой /genkey.
    v4.17: озвучка рига: mp3 «Дарова PRO хабер…» вшит в скрипт (base64), при первой реплике сам записывается файлом и играет из головы рига — класть файл в workspace не нужно.
    v4.16: вкладка «Анимации» — карточки паков с превью позы (ViewportFrame), кнопки «ID» (копирует ID анимаций пака) и ★ (избранные паки идут первыми).
    v4.15: вкладка «Анимации» — паки анимаций из каталога Roblox (R15): меняются настоящие анимации Animate, видны всем; проверка загрузки, повтор после респауна.
    v4.14: Kill All переделан на firetouchinterest по Handle ножа (реальный способ для MM2, без телепорта); добавлено состояние Lobby
           (IsInRound) — Kill All игнорирует тех, кто ждёт раунд. Шот мардера: более широкий поиск remote'ов пистолета и несколько форм
           аргументов; добавлена кнопка «Скопировать remote-имена оружия» для диагностики, если выстрел всё ещё не засчитывается.
    v4.13: Kill All (убийца, без телепорта к целям — экспериментально), Шот мардера (шериф, телепорт за спину на безопасную дистанцию и стрельба),
           авто Kill All при заполнении мешка монет.
    v4.12: Анти-флинг (Основное -> Защита); счётчик MainGui: имена без учёта регистра, RichText, разбор ContentText.
    v4.11: счётчик MainGui опрашивается всегда, запасной поиск CoinBags/Coins, диагностика пути и кнопка «Скопировать структуру MainGui».
    v4.10: Auto-Farm читает число собранных монет из MainGui.Lobby.Dock.CoinBags.Container.Coin.CurrencyFrame.Coins (PlayerGui, затем ReplicatedStorage)
           и делает ресет на 40; авто-калибровка осталась запасным вариантом.
    v4.9: режим Teleport удалён целиком (переключатель, ветки в логике, диагностика); Auto-Farm работает только в режиме Touch, его логика не менялась.
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
    ["Риг"] = "Rig",
    ["Не удалось загрузить: "] = "Could not load: ",
    ["В модели нет HumanoidRootPart"] = "The model has no HumanoidRootPart",
    ["Анимацию загрузить не удалось"] = "Could not load the animation",
    ["Поговорить"] = "Talk",
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
    ["Счётчик MainGui не обновляется, пробую другой источник"] = "MainGui counter is not updating, trying another source",
    ["Скопировать структуру MainGui"] = "Copy MainGui structure",
    ["Защита"] = "Protection",
    ["Анти-флинг"] = "Anti-Fling",
    ["Другие игроки не могут тебя отбросить: без столкновений с ними, рывки скорости гасятся, после выброса ты возвращаешься на место"] = "Other players cannot throw you: no collisions with them, speed spikes are cancelled, and you are put back after a throw",
    ["Флинг отбит"] = "Fling blocked",
    ["Kill All (я убийца)"] = "Kill All (I'm the Murderer)",
    ["Шот мардера (я шериф)"] = "Shot the Murderer (I'm the Sheriff)",
    ["Авто Kill All при полном мешке"] = "Auto Kill All on full bag",
    ["Собрал 40 и ты убийца: сразу Kill All, потом обычный ресет"] = "Reached 40 and you're the Murderer: Kill All first, then the usual reset",
    ["Ты не убийца"] = "You are not the Murderer",
    ["Нож не найден"] = "Knife not found",
    ["Нет живых целей"] = "No living targets",
    ["Убито: %d из %d"] = "Killed: %d of %d",
    ["Ты не шериф"] = "You are not the Sheriff",
    ["Пистолет не найден"] = "Gun not found",
    ["Убийца не найден"] = "Murderer not found",
    ["Шериф"] = "Sheriff",
    ["Шот не засчитан"] = "Shot not registered",
    ["Убийца убит"] = "Murderer killed",
    ["Нет живых целей (все в Lobby?)"] = "No living targets (everyone in Lobby?)",
    ["У ножа нет Handle"] = "Knife has no Handle",
    ["Эксплоит не поддерживает firetouchinterest"] = "Your exploit does not support firetouchinterest",
    ["Скопировать remote-имена оружия"] = "Copy weapon remote names",
    ["Оружие"] = "Weapons",
    ["не экипирован"] = "not equipped",
    ["Структура скопирована в буфер"] = "Structure copied to clipboard",
    ["Нет setclipboard"] = "setclipboard is not available",
    ["Анимации"] = "Animations",
    ["Паки анимаций из каталога"] = "Catalog animation packs",
    ["Паки анимаций"] = "Animation packs",
    ["Нажми на карточку пака: бег, ходьба, прыжок и остальное сменятся. Видят все игроки. Только R15. ID — скопировать ID анимаций, ★ — в избранное (такие паки идут первыми)."] = "Tap a pack card: run, walk, jump and the rest change. Everyone sees it. R15 only. ID copies the animation IDs, ★ adds to favorites (starred packs come first).",
    ["ID скопированы: "] = "IDs copied: ",
    ["Паки"] = "Packs",
    ["Нажми на пак: бег, ходьба, прыжок и остальное сменятся. Видят все игроки. Только R15."] = "Tap a pack: run, walk, jump and the rest will change. Everyone can see it. R15 only.",
    ["Проверять загрузку анимаций"] = "Check that animations load",
    ["Если анимация не грузится, пак не ставится (иначе персонаж может застыть в позе)"] = "If an animation fails to load, the pack is not applied (otherwise the character may freeze in a pose)",
    ["Сбросить анимации на стандартные"] = "Reset to default animations",
    ["Текущий пак: "] = "Current pack: ",
    ["Стандартные"] = "Default",
    ["Нужен персонаж R15"] = "R15 character required",
    ["Нет скрипта Animate у персонажа"] = "The character has no Animate script",
    ["Проверяю пак…"] = "Checking the pack…",
    ["Не загрузились: "] = "Failed to load: ",
    ["Применён: "] = "Applied: ",
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

local KillAll, ShotMurderer -- задаются ниже, после ролей и подбора оружия
local State = {
    ESP = false,
    Speed = false,
    SpeedValue = 50,
    Fly = false,
    AutoFarm = false,
    FarmReset = true,     -- после 40 монет сделать ресет (смерть) и ждать следующий раунд
    AntiAFK = true,
    AutoGun = false,
    FarmFlySpeed = 24,     -- Touch: скорость полёта, всегда 24 (слайдера нет)
    FarmHideDepth = 3,   -- на сколько стадов ниже пола лежим
    FarmStartDelay = 0,  -- сколько секунд после старта раунда ждём, прежде чем лететь за монетами
    FarmTrigger = "coins", -- что считать стартом раунда: "role" (выдача ролей) или "coins" (появление монет)
    FlySpeed = 50,
    Aimbot = false,
    AntiFling = true,     -- защита от флинга других игроков
    AutoKillAll = false,  -- при заполнении мешка (40 монет), если ты убийца: сразу Kill All, потом обычный ресет
}

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

-- «Lobby» — не роль, а состояние: игрок ждёт раунд (в меню/на респауне) и его не нужно трогать Kill All'ом.
-- «В раунде» = ему уже выдана роль сервером, либо (запасной вариант) он физически стоит внутри рамки монет текущего раунда.
local function IsInRound(p)
    if ServerIn[p.Name] == true then return true end
    if RoleOf(p) ~= "Innocent" then return true end
    local zlo, zhi, m = ESPZone.lo, ESPZone.hi, ESPZone.m
    if not zlo then return false end
    local char = p.Character
    local phrp = char and char:FindFirstChild("HumanoidRootPart")
    if not phrp then return false end
    local q = phrp.Position
    return q.X >= zlo.X - m and q.X <= zhi.X + m
        and q.Y >= zlo.Y - m and q.Y <= zhi.Y + m
        and q.Z >= zlo.Z - m and q.Z <= zhi.Z + m
end
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
-- ═══════════════ АНИМАЦИИ: паки из каталога Roblox (R15) ═══════════════
-- Меняет ID анимаций в скрипте Animate твоего персонажа (бег, ходьба, прыжок, падение, лазание, плавание, стойка).
-- Это настоящие анимации персонажа, а не локальный визуал: их проигрывает твой Animator, и их видят другие игроки.
-- После респауна выбранный пак применяется заново. Работает только на R15 и только если в игре есть стандартный Animate.
-- Источники ID (проверены по документации, не по памяти):
--   • Roblox Creator Docs, animation/using.md, «Catalog animations»: Astronaut, Bubbly, Cartoony, Elder, Knight, Levitation,
--     Mage, Ninja, Pirate, Robot, Rthro, Stylish, Superhero, Toy, Vampire, Werewolf, Zombie
--     (у Astronaut в докe Walk = Run = 891636393; взят 891667138, он совпадает с другим источником);
--   • Roblox Wiki, «Canceled items/Animation packs»: Princess, Cowboy, Confident, Popstar, Patrol, Sneaky;
--   • DevForum «List of the Default R15 Animation IDs»: стандартные анимации (кнопка сброса).
-- Перед применением пак проверяется на загрузку (ContentProvider:PreloadAsync): если ключевая анимация не грузится, пак не ставится.
do
    local PageAnim = AddTab("Анимации", "", 5, "Паки анимаций из каталога")
    local ContentProvider = game:GetService("ContentProvider")

    -- P(имя, idle1, idle2, walk, run, jump, fall, climb, swim, swimidle)
    local function P(name, idle1, idle2, walk, run, jump, fall, climb, swim, swimidle)
        return { name = name, idle1 = idle1, idle2 = idle2, walk = walk, run = run, jump = jump, fall = fall,
            climb = climb, swim = swim, swimidle = swimidle }
    end
    local PACKS = {
        P("Astronaut",  891621366, 891633237, 891667138, 891636393, 891627522, 891617961, 891609353, 891639666, 891663592),
        P("Bubbly",     910004836, 910009958, 910034870, 910025107, 910016857, 910001910, 909997997, 910028158, 910030921),
        P("Cartoony",   742637544, 742638445, 742640026, 742638842, 742637942, 742637151, 742636889, 742639220, 742639812),
        P("Elder",      845397899, 845400520, 845403856, 845386501, 845398858, 845396048, 845392038, 845401742, 845403127),
        P("Knight",     657595757, 657568135, 657552124, 657564596, 658409194, 657600338, 658360781, 657560551, 657557095),
        P("Levitation", 616006778, 616008087, 616013216, 616010382, 616008936, 616005863, 616003713, 616011509, 616012453),
        P("Mage",       707742142, 707855907, 707897309, 707861613, 707853694, 707829716, 707826056, 707876443, 707894699),
        P("Ninja",      656117400, 656118341, 656121766, 656118852, 656117878, 656115606, 656114359, 656119721, 656121397),
        P("Pirate",     750781874, 750782770, 750785693, 750783738, 750782230, 750780242, 750779899, 750784579, 750785176),
        P("Robot",      616088211, 616089559, 616095330, 616091570, 616090535, 616087089, 616086039, 616092998, 616094091),
        P("Rthro",      2510197257, 2510196951, 2510202577, 2510198475, 2510197830, 2510195892, 2510192778, 2510199791, 2510201162),
        P("Stylish",    616136790, 616138447, 616146177, 616140816, 616139451, 616134815, 616133594, 616143378, 616144772),
        P("Superhero",  616111295, 616113536, 616122287, 616117076, 616115533, 616108001, 616104706, 616119360, 616120861),
        P("Toy",        782841498, 782845736, 782843345, 782842708, 782847020, 782846423, 782843869, 782844582, 782845186),
        P("Vampire",    1083445855, 1083450166, 1083473930, 1083462077, 1083455352, 1083443587, 1083439238, 1083464683, 1083467779),
        P("Werewolf",   1083195517, 1083214717, 1083178339, 1083216690, 1083218792, 1083189019, 1083182000, 1083222527, 1083225406),
        P("Zombie",     616158929, 616160636, 616168032, 616163682, 616161997, 616157476, 616156119, 616165109, 616166655),
        P("Princess",   941003647, 941013098, 941028902, 941015281, 941008832, 941000007, 940996062, 941018893, 941025398),
        P("Cowboy",     1014390418, 1014398616, 1014421541, 1014401683, 1014394726, 1014384571, 1014380606, 1014406523, 1014411816),
        P("Confident",  1069977950, 1069987858, 1070017263, 1070001516, 1069984524, 1069973677, 1069946257, 1070009914, 1070012133),
        P("Popstar",    1212900985, 1212954651, 1212980338, 1212980348, 1212954642, 1212900995, 1213044953, 1212852603, 1212998578),
        P("Patrol",     1149612882, 1150842221, 1151231493, 1150967949, 1150944216, 1148863382, 1148811837, 1151204998, 1151221899),
        P("Sneaky",     1132473842, 1132477671, 1132510133, 1132494274, 1132489853, 1132469004, 1132461372, 1132500520, 1132506407),
    }
    local DEFAULT = P("Default", 507766666, 507766951, 507777826, 507767714, 507765000, 507767968, 507765644, 507784897, 507785072)
    DEFAULT.idle3 = 507766388 -- у стандартного Animate есть третья (основная) стойка

    local KEYS = { "idle1", "idle2", "walk", "run", "jump", "fall", "climb", "swim", "swimidle" }
    local CRITICAL = { idle1 = true, walk = true, run = true, jump = true }

    local checkOn, busy, selected = true, false, nil
    local statusLbl

    local function setStatus()
        if statusLbl then statusLbl.Text = L("Текущий пак: ") .. (selected and selected.name or L("Стандартные")) end
    end

    -- проверка: все анимации пака реально грузятся (до 8 секунд). Возвращает ok, список_не_загрузившихся
    local function CheckPack(pack)
        local list, names = {}, {}
        for _, k in ipairs(KEYS) do
            if pack[k] then
                local a = Instance.new("Animation")
                a.AnimationId = "rbxassetid://" .. pack[k]
                list[#list + 1] = a
                names[a.AnimationId] = k
            end
        end
        local bad, done = {}, false
        task.spawn(function()
            pcall(function()
                ContentProvider:PreloadAsync(list, function(cid, status)
                    if status ~= Enum.AssetFetchStatus.Success then
                        local k = names[cid] or tostring(cid)
                        if CRITICAL[k] or not names[cid] then bad[#bad + 1] = k end
                    end
                end)
            end)
            done = true
        end)
        local t0 = os.clock()
        while not done and os.clock() - t0 < 8 do task.wait(0.1) end
        for _, a in ipairs(list) do a:Destroy() end
        if not done then return false, { "timeout" } end
        return #bad == 0, bad
    end

    local function SetId(animate, folder, name, id)
        local f = animate:FindFirstChild(folder)
        local a = f and f:FindFirstChild(name)
        if a and id then a.AnimationId = "rbxassetid://" .. id end
    end

    local function ApplyIds(animate, pack)
        SetId(animate, "idle", "Animation1", pack.idle1)
        SetId(animate, "idle", "Animation2", pack.idle2)
        SetId(animate, "idle", "Animation3", pack.idle3 or pack.idle1) -- чтобы стандартная стойка не «просачивалась»
        SetId(animate, "walk", "WalkAnim", pack.walk)
        SetId(animate, "run", "RunAnim", pack.run)
        SetId(animate, "jump", "JumpAnim", pack.jump)
        SetId(animate, "fall", "FallAnim", pack.fall)
        SetId(animate, "climb", "ClimbAnim", pack.climb)
        SetId(animate, "swim", "Swim", pack.swim)
        SetId(animate, "swimidle", "SwimIdle", pack.swimidle)
    end

    local btns = {}
    local function markSelected()
        for pk, c in pairs(btns) do
            local on = (pk == selected)
            c.stroke.Color = on and Theme.Accent or Theme.Border
            c.stroke.Thickness = on and 2 or 1
            c.title.TextColor3 = on and Theme.AccentHi or Theme.Text
        end
    end

    local function ApplyPack(pack, silent, isReset)
        if busy then return end
        local function getParts()
            local char = LP.Character
            return char, char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("Animate")
        end
        local char, hum, animate = getParts()
        if not hum then return end
        if hum.RigType ~= Enum.HumanoidRigType.R15 then
            if not silent then Notify(L("Анимации"), L("Нужен персонаж R15")) end
            return
        end
        if not animate then
            if not silent then Notify(L("Анимации"), L("Нет скрипта Animate у персонажа")) end
            return
        end
        busy = true
        if not silent and checkOn and not isReset then
            Notify(L("Анимации"), L("Проверяю пак…"))
            local ok, bad = CheckPack(pack)
            if not ok then
                busy = false
                Notify(L("Анимации"), L("Не загрузились: ") .. table.concat(bad, ", "))
                return
            end
            char, hum, animate = getParts() -- за время проверки персонаж мог смениться
            if not (hum and animate) then busy = false; return end
        end
        pcall(function()
            local animator = hum:FindFirstChildOfClass("Animator")
            animate.Disabled = true
            if animator then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0) end
            end
            ApplyIds(animate, pack)
            task.wait()
            animate.Disabled = false -- перезапуск Animate: он заново читает ID
        end)
        selected = (not isReset) and pack or nil
        busy = false
        setStatus()
        markSelected()
        if not silent then Notify(L("Анимации"), L("Применён: ") .. pack.name) end
    end

    -- после респауна Animate сбрасывается на стандартные: ставим выбранный пак заново
    Connect(LP.CharacterAdded, function(char)
        local pk = selected
        if not pk then return end
        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 15)
            local animate = char:WaitForChild("Animate", 15)
            if not (hum and animate) then return end
            task.wait(0.8)
            if LP.Character == char and selected == pk then ApplyPack(pk, true) end
        end)
    end)

    AddSection(PageAnim, L("Паки анимаций"))
    AddInfo(PageAnim, L("Нажми на карточку пака: бег, ходьба, прыжок и остальное сменятся. Видят все игроки. Только R15. ID — скопировать ID анимаций, ★ — в избранное (такие паки идут первыми)."), 64)
    statusLbl = AddInfo(PageAnim, "", 40)
    setStatus()
    AddToggle(PageAnim, L("Проверять загрузку анимаций"),
        L("Если анимация не грузится, пак не ставится (иначе персонаж может застыть в позе)"), true,
        function(on) checkOn = on end)
    AddButton(PageAnim, L("Сбросить анимации на стандартные"), Theme.Surface, function()
        task.spawn(function() ApplyPack(DEFAULT, false, true) end)
    end)

    AddSection(PageAnim, L("Паки"))
    local grid = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = PageAnim })
    local gridLayout = New("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 156), CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid,
    })
    local function relayout() -- столбцов столько, сколько влезает (от 2 до 4)
        local w = grid.AbsoluteSize.X
        local cols = math.clamp(math.floor((w + 8) / 138), 2, 4)
        gridLayout.CellSize = UDim2.new(1 / cols, -8 * (cols - 1) / cols, 0, 156)
    end
    Connect(grid:GetPropertyChangedSignal("AbsoluteSize"), relayout)
    relayout()

    local function PackIdsText(pk) -- что копирует кнопка «ID»
        local out = { pk.name }
        for _, k in ipairs(KEYS) do
            if pk[k] then out[#out + 1] = k .. " = rbxassetid://" .. pk[k] end
        end
        return table.concat(out, "\n")
    end

    -- Карточка: превью позы (ViewportFrame), сверху справа «ID» и ★, снизу название. Клик по карточке ставит пак.
    for i, pk in ipairs(PACKS) do
        local favKey = "anim:" .. pk.name
        local card = New("TextButton", {
            BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = grid,
        })
        Corner(card, 10)
        local stroke = Stroke(card)
        local vp = New("ViewportFrame", {
            Size = UDim2.new(1, -12, 1, -50), Position = UDim2.new(0, 6, 0, 6), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
            Ambient = Color3.fromRGB(200, 200, 210), LightColor = Color3.fromRGB(255, 255, 255), Parent = card,
        })
        Corner(vp, 8)
        local hint = New("TextLabel", { -- «…», пока превью готовится; «—», если не вышло
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "…", TextColor3 = Theme.TextDim,
            Font = Enum.Font.GothamBold, TextSize = 18, Parent = vp,
        })
        local idBtn = New("TextButton", {
            Size = UDim2.new(0, 30, 0, 24), Position = UDim2.new(1, -72, 0, 12), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
            AutoButtonColor = false, Text = "ID", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 3, Parent = card,
        })
        Corner(idBtn, 6)
        local star = New("TextButton", {
            Size = UDim2.new(0, 30, 0, 24), Position = UDim2.new(1, -38, 0, 12), BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
            AutoButtonColor = false, Text = "☆", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 15, ZIndex = 3, Parent = card,
        })
        Corner(star, 6)
        local title = New("TextLabel", {
            Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 1, -42), BackgroundTransparency = 1, Text = pk.name,
            TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, Parent = card,
        })

        local function paintStar() -- избранные паки идут первыми
            local on = Fav.set[favKey]
            star.Text = on and "★" or "☆"
            star.TextColor3 = on and Theme.AccentHi or Theme.TextDim
            card.LayoutOrder = (on and 0 or 1000) + i
        end
        paintStar()
        Fav.list[#Fav.list + 1] = { PaintStar = paintStar } -- Fav.ToggleFav перерисует и эту звезду
        Connect(star.MouseButton1Click, function() Fav.ToggleFav(favKey) end)
        Connect(idBtn.MouseButton1Click, function()
            local txt = PackIdsText(pk)
            local ok = pcall(function() setclipboard(txt) end)
            Notify(L("Анимации"), ok and (L("ID скопированы: ") .. pk.name) or L("Нет setclipboard"))
        end)

        Connect(card.MouseEnter, function() if selected ~= pk then Tween(card, 0.12, { BackgroundColor3 = Theme.Surface2 }) end end)
        Connect(card.MouseLeave, function() Tween(card, 0.12, { BackgroundColor3 = Theme.Surface }) end)
        Connect(card.MouseButton1Click, function() task.spawn(function() ApplyPack(pk, false) end) end)
        btns[pk] = { card = card, stroke = stroke, title = title, vp = vp, hint = hint }
        Fav.Reg(PageAnim, "button", pk.name, "", card)
    end

    -- ───── превью поз ─────
    -- Один раз, при первом открытии вкладки, в фоне: клиентский R15-манекен (серверу не виден) стоит высоко над картой, проигрывает idle1
    -- каждого пака на нулевой скорости, поза клонируется в ViewportFrame карточки. Манекен — Players:CreateHumanoidModelFromDescription;
    -- если его нет, берётся копия твоего R15-персонажа без одежды и аксессуаров. Не вышло — на карточке остаётся «—».
    -- ЭВРИСТИКА: в игре не проверено (зависит от того, разрешает ли эксплоит создание манекена и грузятся ли анимации у клиента).
    local PREVIEW_COLOR = Color3.fromRGB(176, 176, 214)
    local previewsStarted = false

    local function BuildRig()
        local rig
        pcall(function()
            rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
        end)
        if not rig then
            pcall(function()
                local char = LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.RigType == Enum.HumanoidRigType.R15 then
                    local was = char.Archivable
                    char.Archivable = true
                    rig = char:Clone()
                    char.Archivable = was
                end
            end)
        end
        if not rig then return nil end
        for _, d in ipairs(rig:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Accessory") or d:IsA("Clothing") or d:IsA("ShirtGraphic")
                or d:IsA("BodyColors") or d:IsA("CharacterMesh") then
                pcall(function() d:Destroy() end)
            end
        end
        local hrp = rig:FindFirstChild("HumanoidRootPart")
        local hum = rig:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) then rig:Destroy(); return nil end
        for _, d in ipairs(rig:GetDescendants()) do
            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.Color = PREVIEW_COLOR end
        end
        hrp.Anchored = true
        rig.Name = "MMPreviewRig"
        rig:PivotTo(CFrame.new(0, 9000, 0))
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then animator = Instance.new("Animator"); animator.Parent = hum end
        rig.Parent = workspace
        return rig, animator
    end

    local function PoseSnapshot(rig, animator, pack) -- клон манекена в позе idle1; nil, если анимация не загрузилась
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. pack.idle1
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not (ok and track) then anim:Destroy(); return nil end
        track:Play(0, 1, 0)
        local t0 = os.clock()
        while track.Length == 0 and os.clock() - t0 < 5 do task.wait(0.1) end
        if track.Length == 0 then track:Stop(0); anim:Destroy(); return nil end
        track.TimePosition = math.min(0.5, track.Length * 0.25)
        task.wait(0.15) -- несколько кадров, чтобы поза применилась к частям
        local snap = rig:Clone()
        track:Stop(0)
        anim:Destroy()
        return snap
    end

    local function FillPreview(vp, snap)
        for _, d in ipairs(snap:GetDescendants()) do
            if d:IsA("Humanoid") or d:IsA("Script") or d:IsA("LocalScript") then pcall(function() d:Destroy() end) end
        end
        snap.Parent = vp
        local cam = Instance.new("Camera")
        cam.FieldOfView = 30
        cam.Parent = vp
        vp.CurrentCamera = cam
        local hrp = snap:FindFirstChild("HumanoidRootPart")
        local cf, size = snap:GetBoundingBox()
        local look = hrp and hrp.CFrame.LookVector or Vector3.new(0, 0, -1)
        local right = hrp and hrp.CFrame.RightVector or Vector3.new(1, 0, 0)
        local ext = math.max(size.X, size.Y, size.Z)
        local dist = (ext / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.25
        local dir = (look + right * 0.4 + Vector3.new(0, 0.18, 0)).Unit -- спереди, чуть сбоку и сверху
        cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
    end

    local function GeneratePreviews()
        if previewsStarted then return end
        previewsStarted = true
        task.spawn(function()
            local rig, animator = BuildRig()
            if not rig then
                for _, c in pairs(btns) do c.hint.Text = "—" end
                return
            end
            for _, pk in ipairs(PACKS) do
                if not Alive then break end
                local c = btns[pk]
                local ok, snap = pcall(PoseSnapshot, rig, animator, pk)
                if ok and snap and c and c.vp.Parent then
                    if pcall(FillPreview, c.vp, snap) then
                        c.hint.Visible = false
                    else
                        c.hint.Text = "—"
                        pcall(function() snap:Destroy() end)
                    end
                elseif c then
                    c.hint.Text = "—"
                end
                task.wait(0.05)
            end
            rig:Destroy()
        end)
    end
    if PageAnim.Visible then GeneratePreviews() end
    Connect(PageAnim:GetPropertyChangedSignal("Visible"), function() if PageAnim.Visible then GeneratePreviews() end end)
end

local PageSettings = AddTab("Настройки", "", 5, "Интерфейс и сессия")

local Ctl = {} -- управление тумблерами (для экранных кнопок)
AddBanner(PageMain)
AddSection(PageMain, L("Движение"))
Ctl.Speed = AddToggle(PageMain, "Speed Hack", L("Переопределяет WalkSpeed"), false, function(s) State.Speed = s end)
AddSlider(PageMain, L("Скорость"), 16, 100, State.SpeedValue, function(v) State.SpeedValue = v end)
Ctl.Fly = AddToggle(PageMain, L("Fly (Полёт)"), L("WASD + Space вверх / Shift вниз"), false, function(s) State.Fly = s end)
AddSlider(PageMain, L("Скорость Fly"), 10, 100, State.FlySpeed, function(v) State.FlySpeed = v end)
AddSection(PageMain, L("Защита"))
AddToggle(PageMain, L("Анти-флинг"), L("Другие игроки не могут тебя отбросить: без столкновений с ними, рывки скорости гасятся, после выброса ты возвращаешься на место"), true, function(s) State.AntiFling = s end)
AddSection(PageMain, L("Бой"))
AddButton(PageMain, L("Kill All (я убийца)"), Theme.Danger, function() if KillAll then KillAll() end end)
AddButton(PageMain, L("Шот мардера (я шериф)"), Theme.Danger, function() if ShotMurderer then ShotMurderer() end end)
AddButton(PageMain, L("Скопировать remote-имена оружия"), Theme.Surface, DumpWeaponRemotes)
AddToggle(PageMain, L("Авто-подбор пистолета"), L("Шериф умер: на миг телепорт к пистолету и обратно (только в раунде). Зажми G — турбо"), false, function(s) State.AutoGun = s end)
Ctl.Invis = AddToggle(PageMain, L("Невидимка"), L("Тело далеко за картой, ты управляешь полупрозрачной копией. Выкл: тело встанет на место копии"), false, function(s) Invis.Set(s) end)
AddToggle(PageMain, "Aimbot", L("Пока без логики, как в исходнике"), false, function(s) State.Aimbot = s end)

AddSection(PageVisual, L("Игроки"))
Ctl.ESP = AddToggle(PageVisual, L("ESP Игроков (Роли)"), "Murderer / Sheriff / Innocent", false, function(s) State.ESP = s end)

AddSection(PageFarm, L("Автоматизация"))
Ctl.Farm = AddToggle(PageFarm, "Auto-Farm", L("Под картой, монеты находит сам. Лобби и смерть — выкл."), false, function(s) State.AutoFarm = s end)
AddToggle(PageFarm, L("Ресет после 40 монет"), L("Собрал 40 — ресет и ждём следующий раунд. Выкл: собирает без лимита"), true, function(s) State.FarmReset = s end)
AddSegmented(PageFarm, L("Старт отсчёта"), { L("Выдача роли"), L("Появление монет") }, 2, function(i)
    State.FarmTrigger = (i == 1) and "role" or "coins"
end)
AddSegmented(PageFarm, L("Ожидание перед фармом"), { L("0 с"), L("6 с"), L("12 с"), L("18 с") }, 1, function(i)
    State.FarmStartDelay = ({ 0, 6, 12, 18 })[i]
end)
AddToggle(PageFarm, L("Анти-АФК"), L("Не выкидывает с сервера за бездействие"), true, function(s) State.AntiAFK = s end)
AddToggle(PageFarm, L("Авто Kill All при полном мешке"), L("Собрал 40 и ты убийца: сразу Kill All, потом обычный ресет"), false, function(s) State.AutoKillAll = s end)
AddSection(PageFarm, L("Диагностика"))
local FarmStatus = AddInfo(PageFarm, L("Статус: выключено"), 46)
local FarmDebug  = AddInfo(PageFarm, "—", 46)
local CoinSel    = AddInfo(PageFarm, L("Монеты: ищем объекты с именем Coin / Candy (учитывается Collected)"), 46)
Fav.GuiInfo = AddInfo(PageFarm, L("Счётчик монет в GUI: ") .. L("калибруется: нужно 3 собранные монеты"), 84)
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
    local method = "Touch"
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
    State.ESP, State.Speed, State.AutoFarm, State.Fly, State.Aimbot, State.AutoKillAll = false, false, false, false, false, false
    State.AutoGun = false
    if Invis.on then Invis.Disable(true) end
    if Invis.rig and Invis.rig.model then Invis.rig.model:Destroy() end
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
    -- ЗАДАННЫЙ путь счётчика: MainGui.Lobby.Dock.CoinBags.Container.Coin.CurrencyFrame.Coins (TextLabel). Он важнее авто-калибровки.
    -- MainGui ищется в PlayerGui (живая копия, там число обновляется), затем в ReplicatedStorage (как указано). Источник, где число
    -- не появилось за 8 с или не растёт при наших монетах, помечается плохим (badRoot) и пропускается.
    FIXED = { "Lobby", "Dock", "CoinBags", "Container", "Coin", "CurrencyFrame", "Coins" },
    badRoot = {}, fixed = nil, fixedSince = 0, fixedSeen = false, adopt = false, nextFixed = 0, diag = "",
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

function GameCoins.TextOf(l) -- ContentText (RichText уже без тегов), если пусто — Text
    local ok, ct = pcall(function() return l.ContentText end)
    if ok and type(ct) == "string" and ct ~= "" then return ct end
    return l.Text
end

function GameCoins.Child(o, name) -- дочерний элемент: точное имя, иначе без учёта регистра и пробелов по краям
    local c = o:FindFirstChild(name)
    if c then return c end
    local want = name:lower()
    for _, x in ipairs(o:GetChildren()) do
        if x.Name:lower():gsub("^%s+", ""):gsub("%s+$", "") == want then return x end
    end
    return nil
end

function GameCoins.FindDeep(root, name) -- потомок с таким именем (регистр не важен)
    local c = root:FindFirstChild(name, true)
    if c then return c end
    local want = name:lower()
    for _, x in ipairs(root:GetDescendants()) do
        if x.Name:lower() == want then return x end
    end
    return nil
end

function GameCoins.ParseLoose(text)
    if type(text) ~= "string" then return nil end
    local t = text:gsub("<[^>]*>", ""):gsub(",", "")
    local a, b = t:match("(%d+)%s*/%s*(%d+)")
    if a then return tonumber(a), tonumber(b) end
    local n = t:match("(%d+)")
    return n and tonumber(n) or nil
end

function GameCoins.FindGui(rootName) -- корень MainGui: PlayerGui или ReplicatedStorage
    local root = rootName == "PlayerGui" and LP:FindFirstChildOfClass("PlayerGui") or game:GetService("ReplicatedStorage")
    if not root then return nil end
    local g = GameCoins.FindDeep(root, "MainGui")
    if g and g:IsDescendantOf(SG) then return nil end
    return g
end

function GameCoins.ResolveFixed() -- (надпись, имя корня) или nil
    for _, rn in ipairs({ "PlayerGui", "ReplicatedStorage" }) do
        if not GameCoins.badRoot[rn] then
            local gui = GameCoins.FindGui(rn)
            if gui then
                local o = gui
                for _, n in ipairs(GameCoins.FIXED) do o = o and GameCoins.Child(o, n) end
                if o and o:IsA("TextLabel") then return o, rn end
                -- запас: путь чуть другой — ищем CoinBags где угодно внутри MainGui и берём Coins (или любую числовую надпись)
                local cb = GameCoins.FindDeep(gui, "CoinBags")
                if cb then
                    local l = GameCoins.FindDeep(cb, "Coins")
                    if l and l:IsA("TextLabel") then return l, rn end
                    for _, d in ipairs(cb:GetDescendants()) do
                        if d:IsA("TextLabel") and GameCoins.ParseLoose(GameCoins.TextOf(d)) then return d, rn end
                    end
                end
            end
        end
    end
    return nil
end

function GameCoins.Diagnose() -- почему путь не находится: до какого звена дошли и что лежит внутри
    local out = {}
    for _, rn in ipairs({ "PlayerGui", "ReplicatedStorage" }) do
        local gui = GameCoins.FindGui(rn)
        if not gui then
            out[#out + 1] = rn .. ": MainGui not found"
        else
            local o = gui
            for _, n in ipairs(GameCoins.FIXED) do
                local nx = GameCoins.Child(o, n)
                if not nx then
                    local names = {}
                    for _, c in ipairs(o:GetChildren()) do names[#names + 1] = c.Name; if #names >= 8 then break end end
                    out[#out + 1] = rn .. ": no '" .. n .. "' in " .. o.Name .. " [" .. table.concat(names, ", ") .. "]"
                    o = nil
                    break
                end
                o = nx
            end
            if o then
                out[#out + 1] = rn .. ": path OK" .. (o:IsA("TextLabel") and (" text='" .. GameCoins.TextOf(o):sub(1, 24) .. "'") or (", but it is " .. o.ClassName))
                    .. (GameCoins.badRoot[rn] and " (skipped)" or "")
            end
        end
    end
    return table.concat(out, "  |  ")
end

function GameCoins.Dump() -- структура GUI в буфер обмена, чтобы увидеть реальные названия
    local lines = {}
    local function walk(inst, depth)
        if #lines >= 260 then return end
        local extra = inst:IsA("TextLabel") and (" text='" .. inst.Text:sub(1, 40) .. "'") or ""
        lines[#lines + 1] = string.rep("  ", depth) .. inst.Name .. " [" .. inst.ClassName .. "]" .. extra
        if depth < 7 then for _, c in ipairs(inst:GetChildren()) do walk(c, depth + 1) end end
    end
    for _, rn in ipairs({ "PlayerGui", "ReplicatedStorage" }) do
        local gui = GameCoins.FindGui(rn)
        lines[#lines + 1] = "== " .. rn .. ": " .. (gui and gui:GetFullName() or "MainGui not found")
        if gui then
            walk(GameCoins.FindDeep(gui, "CoinBags") or gui, 0)
        else
            local root = rn == "PlayerGui" and LP:FindFirstChildOfClass("PlayerGui") or game:GetService("ReplicatedStorage")
            if root then
                for i, c in ipairs(root:GetChildren()) do
                    if i > 60 then break end
                    lines[#lines + 1] = "  " .. c.Name .. " [" .. c.ClassName .. "]"
                end
            end
        end
    end
    local ok = pcall(function() setclipboard(table.concat(lines, "\n")) end)
    Notify("Auto-Farm", ok and L("Структура скопирована в буфер") or L("Нет setclipboard"))
end

-- чтение заданного пути: работает всегда (не только при включённом Auto-Farm), чтобы в диагностике сразу было видно, находится ли счётчик
function GameCoins.PollFixed(now)
    if now >= GameCoins.nextFixed then
        GameCoins.nextFixed = now + 1.5
        if GameCoins.label and not GameCoins.label.Parent then GameCoins.label, GameCoins.fixed = nil, nil end
        if not GameCoins.fixed then
            local f, root = GameCoins.ResolveFixed()
            if f then
                GameCoins.label, GameCoins.fixed, GameCoins.fixedSince, GameCoins.fixedSeen = f, root, now, false
                GameCoins.value, GameCoins.limit, GameCoins.adopt = nil, nil, true
                GameCoins.path = (f:GetFullName():gsub("^Players%.[^%.]+%.", ""))
                Notify("Auto-Farm", L("Счётчик монет в GUI найден"))
            else
                GameCoins.diag = GameCoins.Diagnose()
            end
        end
    end
    if GameCoins.fixed and GameCoins.label then
        local v = GameCoins.ParseLoose(GameCoins.TextOf(GameCoins.label)) -- лимит у заданного пути всегда FARM_COIN_LIMIT = 40
        if v then
            GameCoins.fixedSeen = true
            -- первое чтение: большое число — общий счёт, а не монеты раунда; считаем от него (иначе ресет сработал бы сразу)
            if GameCoins.adopt then GameCoins.adopt, GameCoins.base = false, (v > 60) and v or 0 end
            GameCoins.value = v
        elseif not GameCoins.fixedSeen and now - GameCoins.fixedSince > 8 then
            GameCoins.DropFixed() -- в надписи нет числа (шаблон): берём другой источник
        end
    end
end

function GameCoins.InfoText()
    local head = L("Счётчик монет в GUI: ")
    if GameCoins.label then
        return head .. tostring(GameCoins.path or "?") .. " = " .. tostring(GameCoins.value or "?")
            .. "  [" .. tostring(GameCoins.TextOf(GameCoins.label)):sub(1, 24) .. "]" .. (GameCoins.limit and ("/" .. GameCoins.limit) or "")
    end
    return head .. L("калибруется: нужно 3 собранные монеты") .. "  ·  " .. tostring(GameCoins.diag or "")
end

function GameCoins.DropFixed()
    if GameCoins.fixed then GameCoins.badRoot[GameCoins.fixed] = true end
    GameCoins.label, GameCoins.path, GameCoins.value, GameCoins.fixed, GameCoins.fixedSeen = nil, nil, nil, nil, false
    Notify("Auto-Farm", L("Счётчик MainGui не обновляется, пробую другой источник"))
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
    GameCoins.PollFixed(now)
    if GameCoins.fixed then return end -- заданный путь найден: калибровка не нужна
    if now >= GameCoins.nextScan then
        GameCoins.nextScan = now + 3
        if GameCoins.label and not GameCoins.label.Parent then GameCoins.label, GameCoins.fixed = nil, nil end
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
        if GameCoins.fixed then GameCoins.badRoot[GameCoins.fixed] = true end
        GameCoins.label, GameCoins.path, GameCoins.value, GameCoins.own, GameCoins.fixed, GameCoins.fixedSeen = nil, nil, nil, 0, nil, false
        return nil
    end
    return c
end

function GameCoins.OnRoundStart() GameCoins.base, GameCoins.own = GameCoins.value or 0, 0 end

task.spawn(function() -- опрос и диагностика работают и при выключенном Auto-Farm
    while Alive do
        pcall(GameCoins.PollFixed, os.clock())
        if not State.AutoFarm and Fav.GuiInfo then
            local t = GameCoins.InfoText()
            if t ~= GameCoins.lastTxt then GameCoins.lastTxt = t; Fav.GuiInfo.Text = t end
        end
        task.wait(1)
    end
end)
AddButton(PageFarm, L("Скопировать структуру MainGui"), Theme.Surface, function() GameCoins.Dump() end)

-- ═══════════════ АНТИ-ФЛИНГ ═══════════════
-- Флинг: чужой персонаж с огромной скоростью/вращением задевает тебя и выбрасывает за карту. Защита на твоей стороне (твоей физикой управляешь ты):
--  1) у всех остальных игроков каждый кадр отключаем CanCollide — они физически не могут тебя толкнуть;
--  2) если скорость/вращение тела скачком выше нормы — гасим их и возвращаем на позицию ~0.5 с назад (ещё до удара);
--  3) выпал под карту (ниже FallenPartsDestroyHeight) — возврат на безопасное место.
-- Порог скорости учитывает твои Speed Hack и Fly. Не трогаем позицию, пока включены Auto-Farm, Невидимка или подбор пистолета
-- (там тело перемещается намеренно), но скорость всё равно гасим. Проверено только по коду, в игре не запускалось.
local AF = { hist = {}, safe = nil, lastNote = 0 }
Connect(RunService.Stepped, function()
    if not (State.AntiFling and Alive) then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local ch = p ~= LP and p.Character
        if ch then
            for _, d in ipairs(ch:GetDescendants()) do
                if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
            end
        end
    end
end)
Connect(RunService.Heartbeat, function()
    if not (State.AntiFling and Alive) then AF.hist = {}; return end
    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then AF.hist = {}; return end
    local now = os.clock()
    local own = Invis.on or State.AutoFarm or GunBusy -- тело перемещается самим скриптом: позицию не откатываем
    local thr = math.max(300, (State.Speed and State.SpeedValue or 16) * 5, State.Fly and State.FlySpeed * 5 or 0)
    local lin, ang = hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity
    local flung = lin.Magnitude > thr or ang.Magnitude > 60
    local fell = (not own) and hrp.Position.Y < workspace.FallenPartsDestroyHeight + 30
    if flung or fell then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if not own and AF.safe then hrp.CFrame = AF.safe end
        if now - AF.lastNote > 3 then AF.lastNote = now; Notify(L("Анти-флинг"), L("Флинг отбит")) end
        AF.hist = {}
        return
    end
    if own then AF.hist = {}; return end
    AF.hist[#AF.hist + 1] = { t = now, cf = hrp.CFrame }
    while #AF.hist > 1 and now - AF.hist[1].t > 0.5 do table.remove(AF.hist, 1) end
    AF.safe = AF.hist[1].cf -- самая старая позиция за последние ~0.5 с
end)

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
            if roundStart and gv then FarmCount = math.max(gv, GameCoins.own) end -- max: если надпись вдруг не растёт, наш подсчёт всё равно доведёт до 40
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
                    if State.AutoKillAll and GetRole(LP) == "Murderer" and KillAll then KillAll() end
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
                        if not FarmTarget then FarmPhase = "cruise" end -- цели нет: сбрасываем фазу
                        if not best and total > 0 then -- монеты есть, но все временно пропущены: снимаем пропуски и ищем заново
                            for k in pairs(CoinSkip) do CoinSkip[k] = nil end
                            best, bestCost = ScanCoins(hrp)
                        end
                        if FarmPhase ~= "reach" and best then -- пока тянемся к монете (reach), цель не меняем; иначе выбор свободен
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
                    FarmPhase == "reach" and L("Голова вверх") or L("Лёжа под картой"),
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
            if total == 0 and candidates ~= "" then dbg = dbg .. L("   ·   Похожие объекты: ") .. candidates end
            if dbg ~= lastDebug then lastDebug = dbg; FarmDebug.Text = dbg end
            local gtxt = GameCoins.InfoText()
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
        if FarmMode == "collect" and target and target:IsDescendantOf(workspace) then
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
                goal = down -- только вниз, лёжа
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

-- ═══════════════ KILL ALL (ты убийца) ═══════════════
-- Нож в MM2 убивает КАСАНИЕМ: когда Handle ножа трогает тело игрока (пока нож в руке), сервер засчитывает удар. Поэтому вместо remote'ов
-- используется firetouchinterest — та же техника, что уже применяется в скрипте для подбора монет и пистолета, только «касание» идёт
-- от Handle ножа к телу каждой цели, а не от HumanoidRootPart к предмету. Персонаж физически не двигается, как ты просил.
-- ОГОВОРКА: это известный публичный способ для MM2, но не гарантия — если игра дополнительно проверяет реальную дистанцию
-- до цели на сервере (анти-чит), удар по игрокам не рядом с тобой всё равно не засчитается.
-- Lobby (ждут раунд) Kill All пропускает — см. IsInRound выше.
local KillBusy = false
local function FindKnife()
    local function scan(c)
        if not c then return nil end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") or n:find("dagger") or n:find("murder") then return t end
            end
        end
        return nil
    end
    return scan(LP.Character) or scan(LP:FindFirstChildOfClass("Backpack"))
end

local function WeaponHandle(tool)
    return tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
end

local function BodyParts(tchar)
    local out = {}
    for _, name in ipairs({ "HumanoidRootPart", "UpperTorso", "Torso", "Head", "LowerTorso" }) do
        local p = tchar:FindFirstChild(name)
        if p and p:IsA("BasePart") then out[#out + 1] = p end
    end
    return out
end

KillAll = function()
    if KillBusy then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.Health > 0) then Notify(L("Убийца"), L("Ты мёртв")); return end
    if GetRole(LP) ~= "Murderer" then Notify(L("Убийца"), L("Ты не убийца")); return end
    local knife = FindKnife()
    if not knife then Notify(L("Убийца"), L("Нож не найден")); return end
    local handle = WeaponHandle(knife)
    if not handle then Notify(L("Убийца"), L("У ножа нет Handle")); return end
    if not firetouchinterest then Notify(L("Убийца"), L("Эксплоит не поддерживает firetouchinterest")); return end

    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and IsInRound(p) then
            local tc = p.Character
            local th = tc and tc:FindFirstChildOfClass("Humanoid")
            if th and th.Health > 0 then targets[#targets + 1] = tc end
        end
    end
    if #targets == 0 then Notify(L("Убийца"), L("Нет живых целей (все в Lobby?)")); return end

    KillBusy = true
    local killed = 0
    pcall(function()
        if knife.Parent ~= char then hum:EquipTool(knife) end
        task.wait(0.1) -- серверу нужно время навесить Touched на Handle после экипировки
        for _, tc in ipairs(targets) do
            local th = tc:FindFirstChildOfClass("Humanoid")
            local parts = BodyParts(tc)
            local t0 = os.clock()
            while th and th.Health > 0 and os.clock() - t0 < 0.5 and handle.Parent do
                for _, pp in ipairs(parts) do
                    pcall(firetouchinterest, handle, pp, 0)
                    pcall(firetouchinterest, handle, pp, 1)
                end
                task.wait()
            end
            if th and th.Health <= 0 then killed += 1 end
        end
    end)
    KillBusy = false
    Notify(L("Убийца"), string.format(L("Убито: %d из %d"), killed, #targets))
end

-- ═══════════════ ШОТ МАРДЕРА (ты шериф) ═══════════════
-- Телепорт за спину убийце на безопасное расстояние (вне радиуса ножа), серия выстрелов, возврат на прежнее место.
-- ВАЖНО, почему «не стреляет вообще»: у пистолетов в большинстве игр выстрел считается либо (а) по касанию пули/луча, который реально
-- летит из ствола в игровом мире — тогда помогает только прицеливание, либо (б) по remote с ДРУГИМИ именами/аргументами, чем
-- «shoot/fire/beam» из прошлой версии. Протестировать оба варианта без доступа к игре нельзя, поэтому:
--  1) пробуем remote'ы под самим инструментом с более широким списком имён и разными формами аргументов;
--  2) если выстрел так и не регистрируется — используй кнопку "Скопировать remote-имена оружия" ниже и пришли мне результат,
--     это единственный способ узнать настоящее имя события без доступа к игре.
local function WeaponRemotes(tool) -- все remote'ы под инструментом, независимо от имени
    local out = {}
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then out[#out + 1] = d end
    end
    return out
end

local SHOT_SAFE_DIST = 10 -- стадов за спиной цели: дальше радиуса удара ножом
local SHOT_DWELL = 1.4    -- сколько секунд стреляем, прежде чем вернуться, если цель не умерла раньше
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

local function ShootAt(gun, tchar, remotes)
    local aim = tchar:FindFirstChild("Head") or tchar:FindFirstChild("HumanoidRootPart")
    if not aim then return end
    local hum = tchar:FindFirstChildOfClass("Humanoid")
    local pos, origin = aim.Position, gun:IsA("Tool") and gun:FindFirstChild("Handle")
    origin = origin and origin.Position or pos
    pcall(function() gun:Activate() end)
    for _, d in ipairs(remotes) do
        if d:IsA("RemoteEvent") then
            pcall(function() d:FireServer(pos) end)
            pcall(function() d:FireServer(hum) end)
            pcall(function() d:FireServer(origin, pos) end)
            pcall(function() d:FireServer({ Origin = origin, Direction = (pos - origin).Unit, Hit = pos }) end)
        elseif d:IsA("RemoteFunction") then
            task.spawn(function() pcall(function() d:InvokeServer(pos) end) end)
            task.spawn(function() pcall(function() d:InvokeServer(1, pos) end) end)
        end
    end
end

ShotMurderer = function()
    if KillBusy then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum and hum.Health > 0) then Notify(L("Шериф"), L("Ты мёртв")); return end
    if GetRole(LP) ~= "Sheriff" then Notify(L("Шериф"), L("Ты не шериф")); return end
    local gun = FindGun()
    if not gun then Notify(L("Шериф"), L("Пистолет не найден")); return end
    local remotes = WeaponRemotes(gun)
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and RoleOf(p) == "Murderer" then
            local tc = p.Character
            local th = tc and tc:FindFirstChildOfClass("Humanoid")
            if th and th.Health > 0 then target = tc; break end
        end
    end
    if not target then Notify(L("Шериф"), L("Убийца не найден")); return end
    local thrp = target:FindFirstChild("HumanoidRootPart")
    local thum = target:FindFirstChildOfClass("Humanoid")
    if not thrp then Notify(L("Шериф"), L("Убийца не найден")); return end

    KillBusy = true
    local back = hrp.CFrame
    pcall(function()
        if gun.Parent ~= char then hum:EquipTool(gun) end
        task.wait(0.1) -- серверу нужно время принять экипировку, прежде чем Activate()/remote сработают
        local t0 = os.clock()
        repeat
            if not (thrp.Parent and hrp.Parent and hum.Health > 0) then break end
            hrp.CFrame = CFrame.lookAt(thrp.Position - thrp.CFrame.LookVector * SHOT_SAFE_DIST, thrp.Position)
            hrp.AssemblyLinearVelocity = Vector3.zero
            ShootAt(gun, target, remotes)
            task.wait(0.1)
        until thum.Health <= 0 or os.clock() - t0 >= SHOT_DWELL
    end)
    pcall(function()
        if hrp.Parent then
            hrp.CFrame = back
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    KillBusy = false
    Notify(L("Шериф"), thum.Health <= 0 and L("Убийца убит") or L("Шот не засчитан"))
end

local function DumpWeaponRemotes() -- в буфер обмена: все remote-имена ножа/пистолета + похожие по ключевым словам из ReplicatedStorage
    local lines = {}
    local function add(tool, label)
        if not tool then lines[#lines + 1] = label .. ": " .. L("не экипирован"); return end
        lines[#lines + 1] = label .. " = " .. tool.Name
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                lines[#lines + 1] = "  " .. d.ClassName .. " " .. d:GetFullName()
            end
        end
    end
    add(FindKnife(), "Knife")
    add(FindGun(), "Gun")
    lines[#lines + 1] = "== ReplicatedStorage (похожие по имени):"
    local rs = game:GetService("ReplicatedStorage")
    for _, d in ipairs(rs:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            local n = d.Name:lower()
            if n:find("knife") or n:find("gun") or n:find("shoot") or n:find("fire") or n:find("kill")
                or n:find("stab") or n:find("murder") or n:find("sheriff") or n:find("damage") or n:find("hit") then
                lines[#lines + 1] = d.ClassName .. " " .. d:GetFullName()
            end
        end
    end
    local ok = pcall(function() setclipboard(table.concat(lines, "\n")) end)
    Notify(L("Оружие"), ok and L("Структура скопирована в буфер") or L("Нет setclipboard"))
end

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
                    local inRound = IsInRound(p) -- Lobby (ждёт раунд) — остальные состояния считаются «в раунде»
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
        local line = string.format("[%s] %s | autofarm=%s touchSpeed=%s mode=%s coins=%s",
            os.date("%Y-%m-%d %H:%M:%S"), msg, tostring(State.AutoFarm), tostring(State.FarmFlySpeed),
            tostring(FarmMode), tostring(FarmCount))
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
end

-- ═══════════════ СТАРТ ═══════════════
-- ═══════════════ РИГ Sheb: стоит на заданных координатах ═══════════════
-- Модель Sheb.rbxm вшита в скрипт (base64), при запуске записывается файлом и загружается через game:GetObjects(getcustomasset(...)).
-- Нужны writefile + getcustomasset (как для иконки). Риг создаётся на клиенте: виден только тебе. Меши и текстуры внутри риг берёт с серверов Roblox
-- по их rbxassetid — если эти ассеты приватные, они могут не отобразиться. HumanoidRootPart стоит ровно в Invis.rig.pos и закреплён (Anchored).
-- Состояние лежит в таблице Invis.rig (а не в новых local): в RunHub уже почти 200 локальных переменных — лимит Lua/Luau.
Invis.rig = {
    pos = Vector3.new(55.914, 504.577, -12.487),
    yaw = 90, -- поворот вокруг вертикали в градусах = Orientation (0, 90, 0) в Studio; плюс = влево (против часовой сверху)
    idle = "rbxassetid://507766388", -- стандартная R15-анимация покоя, какую получает любой аватар при входе в Roblox
    label = "shebx436", -- надпись над головой
    lines = { "Дарова PRO хабер, веселись и завладей весь сервер детишек в мм2)" }, -- реплики по кругу при нажатии на «Поговорить»
    voice = {}, -- своя озвучка реплик (необязательно, перекрывает вшитую): voice[номер] = "rbxassetid://ID" ИЛИ имя файла (mp3/ogg) в папке workspace эксплоита
    voiceB64 = { [1] = "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hDxdiaxU4XXhODbKIhOKLwbc0hIioycLqLpJlF01Jw2MoyWTq6isqcLJpLwnm+V1v8opVOE3IiEsdXUbYeyiIRoFgfEBOODwpIjp1A2eNEpEIQeB4bIEaBdRdA6UZRWVLFSpxOlURCNDZ0ougbZRIVixdRt0oyiqknCcLq1VrqKypw6dUXYezIkrTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//uSxOSDlboK9gQZN8sowNPE8yW5VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVQ==" }, -- вшитая озвучка: номер реплики -> mp3 в base64 (реплика 1: «Дарова PRO хабер…»)
    file = "mm2prohub_sheb_rig_v1.rbxm",
    b64 = "PHJvYmxveCGJ/w0KGgoAABgAAAD5AAAAAAAAAAAAAABNRVRBJAAAACIAAAAAAAAA8BMBAAAAEgAAAEV4cGxpY2l0QXV0b0pvaW50cwQAAAB0cnVlU1NUUoKwAABMIgEAAAAAAFAAAAAAIAUADwIAEKAPAAAAQ1NHUEhTNgBcQkxPQ0s2ACQPJiMA+f//////////////////////////////////////////////////////////////////////////////////////////YQgAAAACACi1L/1g9DXNLwEaHO5+ORAQbUsHXISN22XU4JEFHjFtjhlEJsM1AaZZOIX9/pUQvs2yQmkhqtA2Do3CCiGycg+ECEAtGRElAQMI0wfTB2Cuiu0KPjiaFYT/YqHagwJc7mjjyQKzE5vgCILMsJH8mDHUgsgmS1l6nZf5rynavruCFZZLss/UuoiQjPYJL6AiC2U76vFV/E2yx2prVW5iPniZo8SoGksNzj+Lim2o7hypssetitg4W3m+Rnjhx1TsttMLNkfBRUaW4ZB3U9d+3Bm7gSCR1j7KV/bdLI6aMQAwvbFU5dSiGHI8To7VJkOFxr3gljyOCaB9itToQ9DEf5PKtjsVL9B+etilh1OygPVWFZH4GkbF/jJ1QhNJdtvShkfM8uguEXFepM8XdcWeQzLp5AO0P16sEZydCBiPH0+WzYkFdEnt3OCOK01svBme4r6w/cf4BcO0NTf9cHYm7DODXZ9NwIDWoRJaz84I+yyTFBonBBWHUaf6rNyCXTsX62wRNG/UytyInQVquVdKUtjDm7t9unknMPkbKb3jqsTJBRZ0775INbg8JUAqBA73x6tQURROcIdIZ6/h2rpmHhsdNAAZ8Vab1AYUXFrsJcJzpCD9CIYsOpxH+juuX+ckQGg3GSjAx5Bw8tguvs1CW3+AglgvnTPdKHhA/k0VPce827JTMCK9z9WpPxgou4Jp1f+gKHUmRE7sAWy8PdBklPNRydsWxmA/KGvR+ZYI7qgQVz/EduhMmmTtnTHSB+uYOd+LoM1FQfvhL7bOJ4LM/FhOH+wo5EyGwM2Xr2kfNETUH0uDto4VAv7HB4t3mkAzd5L5/I2q2Mc0eDK3HXH4nApTrqo2uHsi6a8hYOZhKOM2EeKkv3J54kCTgmfGkISa5R61eJVELV4HfL4o5cp/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MAAIHgACEgBT2ADZANoMAAIeAAgSAA4MAAIkAFHmAOUA50UiBAwAWd0A3gDYEgBRwwDCAMGYgQQYAAJOAAhCAAI2AAIYAA4MAFPeAOAA4WwAAh4AAgwACFoACBIAuQQABgAFAAoACQALDAACEgBTDAANAA4eAAIMAA8kABEE9QwRBvsMBmAACBgAAmAACBIAAgwAAgYADzYACwI8AAgkAAISAAKiAA8MAAUCHgAPNgAFD3gAC1MBAAAAA80NAioACBIAU1YAVwBYHgAIDAACigACKgAOGAACkABTRgBDAEUeAAIwAAISAAIeAFlCAEMARAwACB4AAjYAAhIAAioAAgwAAgYAAh4AAgYAAhIAAodhAhIACJYADhIAAh4ACOoAAiQAAgYACEgADwwAEQ82AAsInAAODAAIPAATt3MqBioACBIADwwAEQJgAAIqAA4MAAISAAhKAQ4MAAiMAQIMAPMCVABSAFEALgAvADAAMAAvADISAAKNJwIYAALFKBE0BRFZfQB+AHswAALaIFl7AHoAfR4AU1IAVABVVABTMgAvADNaAAIYAFMeACAAHB4AAloAU34AfQB/EgACMAACTgAIGAACnAAI2AAIEgBTQwBCAEWuAAIYAAJsAAIaARFGYjoCGAACEgACHgBROgA7ADxBDBO2XAECGAACJAAIEgACKgCzEQATABIAGAAZABoqAAISAAI+AQK6AFM4ADYAOboAAh4AAhgACNIAAt4cAh4AAioAU+UA5gDj/gQCHgACGAAC8gQIPAAIKgACGAAIZAUIEgAImAEIJAACYAACyS0CXgWzjgCNAI8A3wDgAN4uHgLXKwISADNnAGYXDBNsGAAC/yoCGAACEgBTGwAaABkYAAIsAQIYAAIMADMQABF8oxMSQgACHgACigACfgACDAACFAECYS8CJAACogACEgYCKgACDAACnAACNgYCGAACBgBT6ADpAOopKwI8AAIqABGZO0oCtAACV08ChRJTrQCsAK/8AAIYAAhgAAIMAAgkAALkADFfAF5gHzNmAGlFMFnEAMoAyxIAAk4AAjAAAggBAgUuAggEAhgAAiYEAvJWDhgAU1cAVgBZYAACQgAClAICKgBTyQDKAMQeAFPVANYA0XIAAgQFAloAApwAAm8NAhgAAhIAAjAAAkIAUdEA0ADV9Q4EQgAIMAACTAUCMAACMS4C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",
}

-- Озвучка (необязательно): играет звук из головы рига. Roblox не умеет синтезировать речь сам, нужен готовый звук:
-- rbxassetid (если ассет доступен тебе в этой игре) либо mp3/ogg, положенный в папку workspace эксплоита (читается через getcustomasset).
function Invis.rig.PlayVoice(idx)
    local rig = Invis.rig
    local src = rig.voice and rig.voice[idx]
    local emb = rig.voiceB64 and rig.voiceB64[idx]
    local head = rig.model and rig.model:FindFirstChild("Head")
    if not head or ((not src or src == "") and not emb) then return end
    pcall(function()
        local id = src
        if not src or src == "" then -- вшитая озвучка: пишем файл один раз за сессию и грузим через getcustomasset
            if not (isfile and writefile and getcustomasset) then return end
            local name = "mm2prohub_sheb_voice" .. tostring(idx) .. ".mp3"
            rig.voiceWritten = rig.voiceWritten or {}
            if not rig.voiceWritten[idx] or not isfile(name) then
                writefile(name, B64Decode(emb))
                rig.voiceWritten[idx] = true
            end
            id = getcustomasset(name)
        elseif not tostring(src):find("^rbxasset") then
            if not (isfile and getcustomasset and isfile(src)) then return end
            id = getcustomasset(src)
        end
        local snd = Instance.new("Sound")
        snd.SoundId = id
        snd.RollOffMaxDistance = 80
        snd.Volume = 1
        snd.Parent = head
        snd.Ended:Connect(function() snd:Destroy() end)
        snd:Play()
    end)
end

-- Реплика под именем: печатается по буквам, через 6 секунд пропадает. Новая реплика прерывает старую.
function Invis.rig.Say(text, idx)
    local rig = Invis.rig
    local label = rig.speech
    if not label then return end
    rig.sayId = (rig.sayId or 0) + 1
    local id = rig.sayId
    label.Text = ""
    rig.PlayVoice(idx)
    task.spawn(function()
        for i = 1, utf8.len(text) do
            if rig.sayId ~= id then return end
            label.Text = text:sub(1, utf8.offset(text, i + 1) - 1)
            task.wait(0.035)
        end
        task.wait(6)
        if rig.sayId == id then label.Text = "" end
    end)
end

function Invis.rig.Spawn()
    local rig = Invis.rig
    local old = workspace:FindFirstChild("ProShebRig")
    if old then old:Destroy() end
    local ok, res = pcall(function()
        local write = writefile
        local get = getcustomasset or getsynasset
        if not (write and get) then error("нужны writefile и getcustomasset") end
        write(rig.file, B64Decode(rig.b64))
        local asset = get(rig.file)
        local okG, objs = pcall(function() return game:GetObjects(asset) end)
        if okG and objs and objs[1] then return objs[1] end
        return game:GetService("InsertService"):LoadLocalAsset(asset) -- запасной способ загрузки
    end)
    if not ok or not res then
        rig.failed = true
        Notify(L("Риг"), L("Не удалось загрузить: ") .. tostring(res))
        return
    end
    local hrp = res:FindFirstChild("HumanoidRootPart")
    if not hrp then
        rig.failed = true
        res:Destroy()
        Notify(L("Риг"), L("В модели нет HumanoidRootPart"))
        return
    end
    res.Name = "ProShebRig"
    res.PrimaryPart = hrp
    hrp.Anchored = true -- стоит на месте (под картой пола может не быть)
    -- надпись над головой; стандартное имя Humanoid («ProShebRig») прячем
    local hum = res:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    local head = res:FindFirstChild("Head") or hrp
    local tag = Instance.new("BillboardGui")
    tag.Name = "ProShebTag"
    tag.Adornee = head
    tag.AlwaysOnTop = false -- сквозь стены не видна
    tag.Size = UDim2.new(0, 280, 0, 74)
    tag.StudsOffset = Vector3.new(0, 2.8, 0)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Text = rig.label
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 22
    lbl.Parent = tag
    local speech = Instance.new("TextLabel") -- реплика под именем
    speech.Position = UDim2.new(0, 0, 0, 28)
    speech.Size = UDim2.new(1, 0, 0, 46)
    speech.BackgroundTransparency = 1
    speech.Text = ""
    speech.TextWrapped = true
    speech.TextYAlignment = Enum.TextYAlignment.Top
    speech.TextColor3 = Color3.fromRGB(255, 230, 140)
    speech.TextStrokeTransparency = 0
    speech.Font = Enum.Font.GothamMedium
    speech.TextSize = 15
    speech.Parent = tag
    rig.speech = speech
    tag.Parent = head

    -- «Поговорить»: ProximityPrompt (работает локально, видишь и жмёшь только ты)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = L("Поговорить")
    prompt.ObjectText = rig.label
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 14
    prompt.RequiresLineOfSight = false
    prompt.Parent = hrp
    prompt.Triggered:Connect(function()
        rig.lineIdx = (rig.lineIdx or 0) % #rig.lines + 1
        rig.Say(rig.lines[rig.lineIdx], rig.lineIdx)
    end)
    res.Parent = workspace
    res:PivotTo(CFrame.new(rig.pos) * CFrame.Angles(0, math.rad(rig.yaw), 0))
    rig.model = res

    -- стандартная анимация покоя (после Parent: Animator работает только внутри DataModel)
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        local anim = Instance.new("Animation")
        anim.AnimationId = rig.idle
        local okTrack, track = pcall(function() return animator:LoadAnimation(anim) end)
        if okTrack and track then
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Idle
            track:Play()
        else
            Notify(L("Риг"), L("Анимацию загрузить не удалось"))
        end
    end
end

task.spawn(function() -- если игра убрала риг (смена карты и т.п.) — ставим заново; при ошибке загрузки не повторяем
    local rig = Invis.rig
    while Alive and not rig.failed do
        if not (rig.model and rig.model.Parent) then rig.Spawn() end
        task.wait(5)
    end
end)

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
