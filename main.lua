--[[
    MM2 PRO HUB v4.14  |  один файл: проверка ключа + скрипт
    Ключ проверяется прямо в скрипте: его последние 6 символов должны быть в списке KEY_ENDINGS.
    Готовый файл со списком окончаний выдаёт бот командой /script; ключи создаёт бот командой /genkey.
    v4.18: второй риг (Yro: yro788888, координаты 52.996 / 504.527 / -3.699, поворот 56°, своя озвучка); риги собираются общим конструктором Invis.NewRig;
          «Поговорить» — кастомный ProximityPrompt в цветах интерфейса хаба (Style = Custom + PromptShown).
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
local LOGO_B64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAIAAABMXPacAAAiVklEQVR42u19+ZNc13Xe951733vdPfsMMFgJAiS4U6RISpFoWRblRbKWyIld5XLKlV9cSv4OV/kHO0oqi11x2XGipGJXqlSObVk2nVi0I2uzTEsiKUpcQRAAiX2A2ae737v3nJMfXg8AgpZdSohloLk1NdPTMz+8vuee9Tvnu8D22l7ba3ttr+21vbbXD+Pi1ntijp7Z3UHAr/6Du2/LdXvdchpAstPpdLvdTqcTJcQYRaR9P+fs5uampll1MBisrq5ulc8Vt8qDFkVx1113jY+PhxAEVFU3o4iq5pzNTFXVzd0XFha2BXANHjTGsixTSk3TCOjuZgZAVVNK7p5SCkVcW1u7ePEiya3iCbaMAFS1aZqiKMwMFDMzs3ajLwkjpbS0tJRzvuSotwXwjq2cc0pJREzVMNr39v2cs7tTuLK80u/3t9DxBxC2yoO6e1VVVVWpmZu2GqCbywF3v7h4IWfdWlFQ3ELPOhwOzSylFBjcrdWB9gXcVTU1I+OzhTRgKwmgrpumSYCpqo0EQIDuBAkaCDcnKBCDbQvgnV2S1ZrcCDS6RSARBhF0KMGATGcUmAYXQAx+RZa8LYD//+2HCTKY4YBHR0kEIgeuACQCCIEBcMK2TjFCtkq+LgBd6JUhqrhLAp2IBMQ1unUg3VDCYTQPuiWO/xbzAY7CrEMmyJoz0xPZyT5FmrhFRKIiagDYIg5giwiAAGjwogLQD6mKea6IJWNqpK6FEkBmCooqhn4Aoeq+rQHv4MmnECCsGXONGzM742MV5s4tvRomzkhvwWUNYWBSIzQKi1YI3Tz7diL2TikAKW7FZJyfTXcf8B95ZMenDvQeHQu7tB98kDosAp3CJvna+oAgkH07E/5/3m8ScqlQTpBChAnu2RMeu7P70YdnPzZr+4smTvXmZ3q3d5vJtEpH8MCBptW1VdCEVyA1HAlxWwBXbbSAcmlvuHnSUXhw9rwQuAnAEDE14/vu4Qcf3vmxe2af6OoeaKQLUtGzmT0T+zph5/p6TOAgL68OLggivCrhDvPQImVRICRA3xbApQDYR0DLJq7oiECEK6wwRIWZePCxHX74/rEff/fun9w7/mDRzIbUiQ5SAwhHho+Pze8Yv71jU7YBTSljzdjPCE6BO52jV2IebrroNNzI0MYBRCL6SAECIMHFCYvmEkud3YsH3jP18UfmP7KzuleGU0UaKzzSs0gCHBCLBXPo5bH5Yv+escO9OO2qDZoNz6CDFtzbSEPbtGdbAFdgoQTi5q4YqIBHFB4apxY6d1A+8L6Zn39g7sPjuhPNRNBuQKAoJDsUFEjhzgANpt6wG+fmpu6YqG4vdNY0q9bmCUhON9JQwAU3WZ3uRgqAoyDYEDLFCRAOghamuPee6oPvnf7UfdNPVHmHeykU0EF1JjAbg7EAWECIxkPOItkr17HJcte+icO7yt1F7iVPQ/SNGcEBJwm3bQG0NRAZFUKogNMRXQQhoDsf73tX9+Pvnf3kHRMPhaZL9NwqsKZkMANupCM4hEB0d0pC1BCNIC1qrjTOx7tmewerYgoeNKlaEuQYVM15M0VEN1AD2hPtoMNReFlgvMTMfHzkwbGffmzmk7vjA7CuknQWFoUJUAKAEAVdBC7MTjjEEeBWxBy8Vm3gwVJZxvFdkwdm421VPSVaJebaBs58U0Wk4frZG77l5LXWpo2DBDFgooP53cWDD07+zLvnPzxr+31YZSlMJJiVlkECgS6CQKcAgebUJApnIKqiXls/2a+Xut0Zta4Waw7EZmxW9u+dODxRzdXGoeXGVwHDKFF4S35wxS+8bqlDuC7ONoxstRsBIUAGAUF4AQR6byrcfmf5o4/OfuqhqSd6ecYUDCQ8uBM0ulHgER4JiDQuKcFNYo5JoSyGJzae/fbCn5+tXx8fHx8vJkARnRAfC8pKupOdXfsm75zEDsuFumcMEEwktorI2CoRAtqguAAKgnLtC9vhOkmYpFEgbcTjgFEAClH42M5wx91jP/rIzo/cOfFwrHumJAm2QNdmPozGRVWQRTKiIYgI3B3BipVXLn7plforR/I3z+cTaeg7xvePySRyFPcgAyIhx26cnOrs2lUd6GCmcR/YasIaqEKBBd80jIQ4CDpp1yFxC9enlC8wAYjCERwOMcQAk3HfsV/edd/ETz2882P7wl3FoHSEt2z7pcY40CVrSCrm7AAFYRJ0LS+8euGLp+Vr63OnTg1fXdGztQ6jdff0bi+8DKLkkDDxyptOaeNz1d657u2Tnd2iEblWGzjoCE51BEcUQJBBdTrIa503XGsB0BEJCwDhCjoEYqCLcdL33C6PPzz9T++f/cgcDlZNEc1V3lIHuhQ0qY85XWQY3MXFqOimc/3XvnfxqcXqb/LMqX4xvLi+lHWl9qWchrOyf2Zyl6mABCO8EovB2ZiVMrGjPLC3uGPK5oNW67Y+4DqgQAACoQID4SQQrnXeEK59sFM6XOgmcDEEgaHwOOcHDoXHH935s/fOfmjMdkhmoIDBhODmgrQ/QGaphFZmr6wUQYqLR9e/8cr6VxanXmgmXm/iBddibXmQmjVI01hT2vT01P5SZsQ65tFAYZYwVDF3RC0mw+6d3cMTcV4c9Aau7nA6peHIEwgY4brVBSBw0N3buN9jx6Z34PD95Ucf2/OJOyYejXVHkCBqiI6u8zKauKkBBGGhEU9iEoIM4+KLi18+MnhqferllepsHS66D2jSX1tVHToko2iy9uLO+fFDaDpEdBqkFgzFKohZzJkM7E1152+bOjAnOy2z0dxgXaWGgw4buWTbygIgQBWTgNLcQI82eSC8+4HeTz60++N7x+6WQRQDgzho7WG/4gPzsi3y6AlU6zTn/NjzF//iWPO1eurEIJ4FN9xNUShldWO5yZkMCk+oxzB7YOyucXQBgwjZpmAdE88hQzKhQdmT2bnuHZPd3cn1QnO6xqoDRAnQma918ejaO2EiOCKCAhDp+txDkz/+nl2fnAn7vQmCSHTcKiCQiRzCWzhAgNb2wN0Ilhq8qE/nl59Z+LNz8dvN5JlhWHHkEkN4zBxrIOv9tZwSBWAy0Uon98qBHZ1ZZoKBKGghBXeG4KFULzwLrLGYcm+6Oz/g2vH1Fzb8AhGISGQXvdZOOF7zorOVxmHDoXsJRIGOleUEp8sm51AO0AshVtpET2aS2YlItGgoQBgbSHIkYUDBoxef/u7wzzemjtXVcpbGLZGWPZib2KAAK48JEiAOV6Z1P3F+8OLt4w9G6wqckoAQjU7QBagcpcEFUsDhmVaWLQ7hMDRAhvNaa0C8LjnwpilxZO9fGJ5cnb4wHW5Ts8CmQBZRQNtTn1ExZHAId2dAsNjhRnP6uXNfPDH828HM64PO6cwh3YUAlAzCCJMo5cQ4ckaTsjnctMa55eHZGjVEKEpm0Amhjx7HRirqhDo8uASQo7DHbg1Q3kEFIAaARkvon1h/4cWVbzw0u2PMYtn0o0cjjIAzumksQCUTER1icbgwfPX4ha/O3X/0tn1eze0qx2erGCspYwgI6Ks2jeWEfj8P+nlpee3cuQtNShJkVg52zsSl4cLusQNmFCHVaXj7oXZncIkIMjrxbBu8bgEBGKgYAS5ONw96QU88v/SlIBMPzr53zneFOtZUExNj9AAfitPQNWEuNo5d/NqC/vW9H4iH3z09tmNyfFImeuVUb7IKJSIs6EY9XFxeXl0drK31l5fWNqb93v1dhzNi7+SDL385brx2loX6kPRRRQq4yrCw3W3CCV5nyOY6tKVoqwiAA+rutaydbJ4LFxPzyqOznxgv9rk7g8EpiKWlbC4F67D44rkvbXSeO/g+zzOLz7xxsbgQJdpYWRQSRajBEJ3DREPT5BDD3NxMNT6ZczMx0Z0eD3tnD6Qz+uyRJXodtKIRhEHfXmVzN4opVE1bg9lGTA5sdSfcFpuRIUTbRw5ITlw+l5773iIDJh/c9aGOjVmjEVQSplbWK3LmpQtfXiqf33W3Lsdm6czCwvKah6BugCEng2ax5NqsNjCEIL1e573vfWRmZjLlwWzZG5vpLvbtxaOvGR8OcCEdQeluf0fXolMtpMxGmRx2uWNz6zvh9uQHl7ZpEwKakdABh2/qi7oiSVbfveOJHueEjcV+E/KF5uhzp586Xn97mcfrv14yT52quP/eB2LsNQDJWBpMjVJnzZ11d29UDx+6J8vM2eUUWH7uf/7Z4rmFwjjR3PmR2z5ohmDw6B5chG+vsDmZ2Gyk9aH3EUazN+2/+ZY3Qb75UUYJfhDQAWfRx9Ip+xYW6jgsHtnzEzGWTVh/ffWl75z68on07BJOJU+OUIqvrQ9Onz+z/9Cd1rpQdxqEURSitcPnJiamx3r1Rr+I4ejrr59+85x6V1BMV7slTpCiMGM2GH3UnXJlmc3dkzYNNjKTE1fUf7jlfYABIxjW4Q7FqLRiPgRTrem0v5JWyyVeuHP3XasXz3xn6a9Op9cHvpRkYFBCGgtEdfLshZ1794cYAbjDCGdGNCJqzt1qrK4bVSuK4vXjb6p5R4ps2gmTk2E2eGoKA0OlGQgGmtBh9CyEI5CROa+kNza45ijoCaChIPRW6Q31q16RTpJOa7B0Ht8drJ15faMDH1zIF2oMFcktQdyhhMGlSbqx0Z+Zmbk0BOlwwEQCYA72+0N3r+tmfaMPwK2O6EzE2a6Mi5mIOYVOoh2occIF7UwNGJBSf62+kC3hMgECb9nmXAIRdIcKEpPiQm1LS2oOJQoHE9IlMIRQUlsAU0REpBXAFeNgXtf1cDjMTSqKIlIAGHPXJ+fKA+NxShqUkjODixAmNCfpiAh0VxokrduFvq4QOuqduPrc3ILd0WbuMFBoHkTKxpQUeBqdPgnw1oa5OjqdcmJiQlXbQvWlMTx3F5H19fUooR2d7Ha6QoKY5t59vUNddAUZTIF0donWAoGQ4AE0o2ZpFgYn1vMioOQoY7iV29MdULi3LVnaIgAeXOCubaLkAUpKO3uUhDx48GBZlq39aXe/3foYY0rJ1doZyrWVlU5ZFpRgnT2d23dV+1yTIgs1UJVKV2cCEFAYHFDGJsna6f6RDb/gyAIh6NwcMfNbVAOMAITuhBEq3ow+rPMykAwSruZ79+7Zu3dfO6itqiGEKwdR3T2GMBgM5mZmpnbvgfvunbuPfPPsvu7hnZ256JbpUQRQhEzzICYwAd2Di0pXl1ZPnh0cH2CZYsGibXoB+i0Qhn5/HaDLZtXF9ZLj89ja/cviAGJZhBBaTogQwpWsQa0GhBCaptm/f/+PvP/xpql16E8e+9uD1d3joRrYwMrKLQYkWJIQXaCuMEoMSdRluLD25nI+qxyQbUECVzpivyU1gDAS7tERfVSXFLi0CkHYqCdik4XJzESkZSi4kgpCghSxaEWSUlMPhyk1zOWBubv2cC9yRqHu5hbhDuS2O1HaLkfkGLmWV06vHtvAkrGdbNpMEuiOW1YD4A6HAWmkD95WjejYHO9yQCFCwNuYtY2CrhakGQGSFE95qNbQhRZvnz80sVwxZcIqs0DVoGJQDAtDpKYyeQbBk8uvvd48u44LbgGwTDU3GMDrMWYTb/wA2N/36z/M4sTNHjeSmpNZ2ygnU1NdWxyGooKkiCimHhKpAEyUzCSLXnlxeO7Y+ksLdtJHRo8Ouz7ud4uNqV7ulLjqTWE7xSdBFDB3mjtcihTK7DoQyW7mDEFyQDCHFUOHB60Qhqfyq0fWnu3bil9Ken17UPsHAZzbqB1CkDmrmhrc6S4GSY4mxhwkB0mUJkgqoWADacqIleHZ50//9anhkYyBb0JgfsvhAe8MQWIIoWVoertaOGFmQqbUmHvL7sRgDBYdLsag0VyDBWhwJKoEyTY4uvDCG6svD7FG6FsxSLmqmrVtgv4hLSBBppw1K8UcxqgSTaAhanQJZgxJaCJaUrTCsYVXnzn99WU960h+4+Zm4k1O0nSp7NOWgN6uATHGGEILnKibugXz7FqyQahpAjTwAhCiQZChaEBncXXx6ZNff01f7GOFgH7fjIvXOhPYGhrw9ujzKjNFByGac8o5RBPTjAFkGKR0ySG6uORQw2BRUq6fP/HsyyvfW+aCI8MNgkuxz3Xm9Ixbha/siqDzqt0XM4tCBwUhJS2kduZcqHOjsvGQxWWQ6RmoYlH52JdPfO1ri395DicUWRwOvs0C2VsAvW0B/P2OWkQoEFDVU0pWRMAKK2OhyfvKHDWX3rVQJOZnj3/jGye/dB6nGunTKR4dUHy/Djjf1oDLVugSEnDV7ouIuwKIMYzcckbUEAptuOawTtMJWq5Cnzv+7F++8cU3/MQg9p3O3GZx5I3jVrkVNICkO0iqamqSdVUVDZVByyapgzEuWf/rx7/1zVNfeSMfHcahC6loW+Sc7gLotgB+8Ey4fd/dKeJmJOt6aNozYFA22fOUVqE3dmpp9avHX/jq+a+ebV61FuXMEARCDG60ax/s3OoaQIAil4h01XITa62Yc3z59OvfPPbCN1deftOPW+nSiLgECECDGfJ16j+5JX1AiweEENyz24hHOqWcc9NBOD9Yfvb40WdOfufk+rEl3bCgcCrN0YJqbpJBp4GjKuy2AC4Hfi0owjZAB//uyvwlo0QIZUQibW5mDrenjzz7zaNHFvRs4EDIoKV7oWFgpjDDZu8VnQExI98QLYg3IT2iGN2jM4iz6zZA3aKEglE/yajRy9teIyephhCC5ZzNskPJjcJfGh49nY7FWNR5s0/bFfmKmpsBDoM78o2Kg26+aqhLdJZIYKOxbkQdKOoieOCVBFibVYLWNLVNFpeqF2au8NArCLjbFfi6j8Aff0uUfwMZ/m4yDXACkdAAMJoH5MYn0b2tuzuASYQtGRlHHBMAYO3sk5BokeGUUstm3+10fJu49Qe3QqrwhnBAGsx79/ED9z984JCnLEK5SlijrW87tC4XLVoBtPD9TU7kfbP5AKeoMTg6Mct+dD+w++CH3/f+RdYnV5cF0a8g0mjbpwSjPq0Qgqq31wy032OM27yhPzBCLI4Iuvqu2Pvw3nt++r77d0x21jcWA+EUfxvd0qVK9ZVF0/Zmn7GxsW0N+IEpKwWhUt0dq8cP3faxB+66fbLb9zWRIYkW/XVstqW0noBsTQ02bzppL9Qwt6rTodx0HGU3T1/QpXD/ylRU3MKuUD1x28GffOzefROh6V9AGQMR6LYZAvll1j+PZJDQ9hCJiJurKkHLGkOIQVLKvKq0SdzA1Pdm6Y6uwIZi4oAFRUlkhuSc73V+fO+hj99/z+x40eTlSgiIu9I1uDoBUsmWR4AgPMOsHT0l3CwL2owMVVl2yjKlzCvGUi/PPm6K4caK44ZpQEMBTMyd0CC1o2O6p6h+bPfujz90757Jct3XRRQIHkMuS4iRhXibR1nw0Y5neg6aqSI0R6YlMbg74UFCp4uNgbPwlrMPHpDaiRG/Qi/4w6YBTnhgUBSOxmlVBbM56If37vrUQ3ftn8TQl3LIUaXsTJxZ6b+xuNj0ZrLEtp+OMFLpbvAQx4Ooe3IXwt2i5QBCUQeRTqfAiHqjJS7ysLnbNupClM3jbz90Ttjo5iAYLEw537N350fefff8XGyaFQkoKF50n3/91F9998ipsph7bMY1EQSFFMAMBoeYBdOgFtvuFWRJWQSgFcJuVQAQZBvNAFPbjk/Cr+AQ5Q+dCXKwvXotoDBM5OF753d/9OF77tg33W82esKosV/Hrx899pUXXnt+cWXu9kO76KYJiJQIJySau8PgTYw5FipUNyNIH7oK0aGUnWocpARxGhwON3jb9AtveYy8ZSu7UVdu3DANiG4KAOy5PTw19qkHDz18YM7SWgHG2B30w1deeOXJI6++OhysArHEICaHibu4RQbVLAF0Ly16Lus6ihCmAKs6AAIpilDMFOPizkYFAMVBp7Y+2dzaIpCDcuO8QLyBMWhAEQ2Hx7sffejwY3dMhryUHEXonBs0/+d7r3/plWPH6mYYS1jDPChjoIeYEJompGTN0HKfpmWuqkZ79TBQihgI56nTAFwYqnCHbYTZqYHmfqPDRmu1viObG7wBDG6Ewe2HABO+HMGPTHBAyLYnTD5++PA/un9/5GKum1hOLw6bp1545U+PnnqzTkRZ5twFdg3S5JllHdRlsp6jB53pxl6UbhWrboyh6lazITAIBYS7EMPUJPek3ea++X6jG0O9uDRYWuufqtO5lZWL/cFqXa+ZDhwZgJB+5QWIfusIYDQXikgwIDvMCA80Yjbgif07fvqB/d2w0aBBp0hZvv7dE1/53ptLjXaiTJc40J28vdc9uHNmB5Ym5sqZyYnxbtkRdgILCYQT2dzcM3wEao1mWLuXpjGFDO6SdTqbr2heXreFi/XJixtHFi4cW18+1e8vqSaXKCVcDOpUR6aTLnaN0XpeF2tDILDlDoUZnOQU+L75mX/++EPv2j82GJ7XGCkzzzx74gvfOrLqtntueu/c9KG5idtmejvnerH0GGIU0M2tcc0j1uNRZrU5OLxZ5ncCbiPWjdFpFlIIoZh7AZRD54Xh4Pji6okLay+9ce7l5bX12gfGGsxiBqVTXPSWEIBcSneEBBBdHxsf+9nHDn/ogdlKF9ThxY5XXlt+5rmjMj23b9/8wfnp3WPVBJsQm6HUQyamor2jjeItsyqMAL0NinglyNIaOt2cNOKIjKad+mtNfsge1QmE8cGgXFq15y+cf/6Nc6+c33hjfbDm3naLXgcNuA7ErS2S5RCHCB2V25zEnzi098OP3DZRLAfbCKHq93H67MID993xvvv33rG7O9mrEVYaWa+RVAQuheWARFqgkiAdtNHGskUXDWy/HGKAjl63fxUDzOkuYpEq7sEN6jkFx9zY2O3zU/t275bO2Epj59fW26yN176SF689Ww3bebyWCjXSeu7375l+/8P7emPapFyGDr2IAY88tL8oiOGiNWqFaYnsiF4VOQQVF90kVdyEhCkA6e3A69UaQNpl0ImXOknVkMAIBGu5EkKWomnyxQrTnYCLS4uLq2schafutwJl2WbR013EWbrdNlE+ftfcob0VdcMYkxcRUhbq3k/ZcuxFhMJz0Tjo4rkwiMlGpCIA7tJeojra73CF6b/SE1yxeVfwYNIK1LToqBxizAhobBA7vXNr6UvPvvb0kVMLw4yWXrYllLAt35xr3rYAWgiUynH/rrH3HJwetxU1V0YJ7lq3I5JgpUJRhhwJV1EInNmFghJCtHTmNG8pVZ0iI2aHtjvxkrPxv4PyzdxpLAQingUweJNCLCbXBsWXXzr1pSPnTw1zHQTGAApNeQvkASThHDlDm5+sHrxj577pUgYXQqhqkFRKE0C3rmvZQRMcTmaGWujCCIutI4cBLnDbtM4t2flmlCPm2Uf7T9Lgly5raq1WAJBQiTB4Dt44aehkzD3z8omnnj9+bH2YQjCJ8ETz65MOxGsP+peCoQAJHmCH5yfv2z9BXRkGCjXQaE4PNKGrMLnGduhO4JWZmYsb6YoEiI8iHrHRlTDinkhwc1jY6SaBtGCNOIlSGVWCw+kaTEuvE2OWglIgNyjDt15/409fOv7d9WEiVRVqI4YjvzXYUnxUe4nue4vi0fm5g52xarDcxKrlLFFC6SZiBKAl1t3MJcADRUAxhrb2FkWcMiqnMbQRbhbANACe1V0FgDVKq1nGEKOCyOJZqIJMN4SShojkWUM1/sKbi08+c+KFi3UWUb/kxq9fKnzNaSsDDA5jCO77Joq7d3S70MwQoHR3DwY30IM4XCRGVoEyTGasapVGmTIHdarrumlqa0fYIebuoAQpK5aF9KqyYigldstQFFLEMDDLTQrMAhXoZg4RGoQgYM4ouy+d7T/5zMlvnxmsslC3G4Iex2udhQXAAIVE6Nykz+2QftwYBO/qMBIM3UIqQcyZyLY+aN4YxLVBWl0fLveXVwZpZWM4TNioU3d2YnJqEiLuaI+/muWUvRkyZ/G0Z8dsReuIV4FjvWL3bNg50fMgQk2W2gkwYYiuUJVq/NiK//E3j//NidV1SGJ2u0UBmdGlDY4SmKrQK90so+x5rPpZ1wa+sDI4t9xfXk8XF9cW1+tTTbG0MRymZpBQA427AgPg0Zk9D93+ruFwGEJ0hxNZtd/v1xuDwcbGWBV/4Zf+ZUd87eK5i+fPLp8/8+03XmmWj962c+rA/NTkWHeiW7IZoq4L1ho6p/vy5LPHnz65cd5F6XK5ffHWEkDLt0EgwCp4R8ajTaf+xunz6dRS//Ti2pmV/snl+twwXxyk5NKYZbRGhtqSOhEMdPUmhr7Z0E0sg3RnUl3PqY5hIQ1/6kNPlAdvq4cbE7tmJ++9a6I79vnf/5P/8pu/s39s+dDO3t17evftm7lzx8RM2TOVRR//39858VevXzzVWBIRz7wxp//6kHeTghwdmVwNU08+f3ph4fwba/nkan9taH1gA2hQZBQgGEKEwa2N86WtXxgaByUwBk+CENy9zilpkhCa/tqu+Z0f+tATCUghZM2B8cyZ87/9B3+ywDio5diJtWdOrx58deHB3eOP3bF/3/yOr756+s9fPHtiQ1VAUwUh0e2WbU8fXWE6gDx9+sI3+qtrTVprYcEANZKBQPAcHVBvBC6juV8Y3WEujqwsMypFdpes2mRmCzmr9/M/+ZlP3nHboeWV5RC6WdPk+Nh//I3fOXfubFVWGxkM1UqTzl/MR5eXnzuT7r9t/YVzK8f6OZF0owMsnRXYv9a3ldygUoRrGtWI9cTixctU2Zeqlq7mzhFzEEZA4YhNqDVHbaJrbto2osMyLYvp+urSBz7w+I898cHBxnq3Uwzrenp66qmn/uLJ//XFEEKdanqLPaNPDBSnFzeeXasb1TTqrmgfLEHzjYLl442hBPK3iOjqpOf7jOxSDHBN2VRd83DQv/OOQz//Cz8fYqhQ1rmZnJw8duz4v/13v+6g2wiFv8QPBVKJ9aSbt/pdgsBulAPeUnQ1atlU68FQczbT4XA4v3P+0//i0xPjY6qq8KrqNE36tV/7V0tLy1ex+l0at3dz8ua63HzLCMDdh4OhmYG+sbG+c+fOT3/6l3bumKvr2mgku93uZz7zb5559vmyLOz7B/U3W7P01pkTdm+aZjjsN3V9+PDhX/zFfzY1OZnqxgVmNjuz49d/4zf++At/GiSklP/+yy9uKhnEraMBtr6+2tT14+9//yf/8SeqqmqGdYhBYpiamv7vv/u7v/mbvyUS1WxrsYDFrUKVUtd1r9v9xMc//p73PKpZGxvGGGmYnZ75g8//0Wc+869DLEzbPncBbVsA7ySg4O4PP/Twz/3cz05PT6+vrxchSlGk1EzP7PzDP/r8L//yr7hxdLfqzeVibxXOuBDCE0/8WK/XWVtbKYoiQQnZsWPuC3/85K/86q+aQoQ6iuV5iXh0WwDvmAkqyyIEWV9fF5EYy5x1fHzi9//gD//9f/h1NQtBzOyKoH5bA95RighVnZgYj7Ews5SUDJOTE5/73Oc++9n/FmME2e7+lZz22wJ4h03Q5OS0iOSsIRYkP/vZ//pHn/+CtFMAm4PaW3H3twBrYjt5Ojk56Q6KNHX927/1n/7m6adDCOpmeZNkfWvu/hYwQe3OTkxMTIxPHHntyO/93v848tprIQa19hrOGzVZ9ENmgvbs2fOd5577rd/5zysrK0VRJM3w9q5ybK9rTtIkIvfcc89YtwegU1YxRoBgQIgMcXuXrqM8rqLL2j7+198Wba/ttb221/baXttre22vW2P9X8WcCuXtT0gTAAAAAElFTkSuQmCC"

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
    if Invis.rig2 and Invis.rig2.model then Invis.rig2.model:Destroy() end
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
-- Кастомный «Поговорить»: ProximityPromptService.PromptShown для промптов с атрибутом ProRig (Style = Custom).
-- Карточка в цветах интерфейса хаба: тёмная поверхность, акцентная рамка и кнопка клавиши, текст и полоска удержания.
function Invis.PromptUI()
    local PPS = game:GetService("ProximityPromptService")
    Connect(PPS.PromptShown, function(prompt, inputType)
        if not prompt:GetAttribute("ProRig") then return end
        local part = prompt.Parent
        if not (part and part:IsA("BasePart")) then return end
        local gui = New("BillboardGui", {
            Name = "ProPromptUI", Adornee = part, AlwaysOnTop = true, Active = true, ResetOnSpawn = false,
            Size = UDim2.fromOffset(250, 58), StudsOffset = Vector3.new(0, 0.4, 0), Parent = SG,
        })
        local card = New("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui,
        })
        Corner(card, 12)
        local st = Stroke(card, Theme.Accent, 1.5)
        st.Transparency = 1
        local scale = New("UIScale", { Scale = 0.85, Parent = card })

        local keyTxt = "TAP"
        if inputType == Enum.ProximityPromptInputType.Keyboard then
            keyTxt = prompt.KeyboardKeyCode.Name
        elseif inputType == Enum.ProximityPromptInputType.Gamepad then
            keyTxt = (prompt.GamepadKeyCode.Name:gsub("Button", ""))
        end
        local keyBox = New("Frame", {
            Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 10, 0.5, -19), BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1, BorderSizePixel = 0, Parent = card,
        })
        Corner(keyBox, 9)
        local keyLbl = New("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = keyTxt, TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBlack, TextSize = (#keyTxt > 2) and 11 or 18, TextTransparency = 1, Parent = keyBox,
        })
        local act = New("TextLabel", {
            Size = UDim2.new(1, -68, 0, 18), Position = UDim2.new(0, 58, 0, 9), BackgroundTransparency = 1, Text = prompt.ActionText,
            TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, TextTransparency = 1, Parent = card,
        })
        local obj = New("TextLabel", {
            Size = UDim2.new(1, -68, 0, 14), Position = UDim2.new(0, 58, 0, 29), BackgroundTransparency = 1, Text = prompt.ObjectText,
            TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, TextTransparency = 1, Parent = card,
        })
        local track = New("Frame", { -- полоска удержания (у «Поговорить» удержание 0, но если задашь HoldDuration — заработает)
            Size = UDim2.new(1, -20, 0, 3), Position = UDim2.new(0, 10, 1, -8), BackgroundColor3 = Theme.Border,
            BackgroundTransparency = 1, BorderSizePixel = 0, Parent = card,
        })
        Corner(track, 2)
        local fill = New("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track })
        Corner(fill, 2)
        local btn = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = card })

        Tween(card, 0.2, { BackgroundTransparency = 0.04 })
        Tween(st, 0.2, { Transparency = 0 })
        Tween(keyBox, 0.2, { BackgroundTransparency = 0 })
        Tween(keyLbl, 0.2, { TextTransparency = 0 })
        Tween(act, 0.2, { TextTransparency = 0 })
        Tween(obj, 0.2, { TextTransparency = 0 })
        Tween(track, 0.2, { BackgroundTransparency = 0 })
        Tween(scale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)

        local conns = {}
        conns[#conns + 1] = btn.InputBegan:Connect(function(i) if IsPress(i) then prompt:InputHoldBegin() end end)
        conns[#conns + 1] = btn.InputEnded:Connect(function(i) if IsPress(i) then prompt:InputHoldEnd() end end)
        conns[#conns + 1] = prompt.PromptButtonHoldBegan:Connect(function()
            Tween(scale, 0.1, { Scale = 0.96 })
            Tween(fill, math.max(prompt.HoldDuration, 0.05), { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Linear)
        end)
        conns[#conns + 1] = prompt.PromptButtonHoldEnded:Connect(function()
            Tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
            Tween(fill, 0.15, { Size = UDim2.new(0, 0, 1, 0) })
        end)
        conns[#conns + 1] = prompt.Triggered:Connect(function() -- вспышка рамки при нажатии
            st.Color = Color3.new(1, 1, 1)
            Tween(st, 0.35, { Color = Theme.Accent })
        end)
        conns[#conns + 1] = prompt.PromptHidden:Connect(function()
            for _, cn in ipairs(conns) do cn:Disconnect() end
            Tween(card, 0.15, { BackgroundTransparency = 1 })
            Tween(st, 0.15, { Transparency = 1 })
            Tween(scale, 0.15, { Scale = 0.85 })
            task.delay(0.18, function() gui:Destroy() end)
        end)
    end)
end
Invis.PromptUI()

-- Риги собираются конструктором: у каждого своя модель, имя, координаты, озвучка и «Поговорить».
function Invis.NewRig(rig)
-- Озвучка (необязательно): играет звук из головы рига. Roblox не умеет синтезировать речь сам, нужен готовый звук:
-- rbxassetid (если ассет доступен тебе в этой игре) либо mp3/ogg, положенный в папку workspace эксплоита (читается через getcustomasset).
function rig.PlayVoice(idx)
    local src = rig.voice and rig.voice[idx]
    local emb = rig.voiceB64 and rig.voiceB64[idx]
    local head = rig.model and rig.model:FindFirstChild("Head")
    if not head or ((not src or src == "") and not emb) then return end
    pcall(function()
        local id = src
        if not src or src == "" then -- вшитая озвучка: пишем файл один раз за сессию и грузим через getcustomasset
            if not (isfile and writefile and getcustomasset) then return end
            local name = (rig.voiceFile or "mm2prohub_rig_voice") .. tostring(idx) .. ".mp3"
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
function rig.Say(text, idx)
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

function rig.Spawn()
    local old = workspace:FindFirstChild(rig.name)
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
    res.Name = rig.name
    res.PrimaryPart = hrp
    hrp.Anchored = true -- стоит на месте (под картой пола может не быть)
    -- надпись над головой; стандартное имя Humanoid («ProShebRig») прячем
    local hum = res:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    local head = res:FindFirstChild("Head") or hrp
    local tag = Instance.new("BillboardGui")
    tag.Name = rig.name .. "Tag"
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
    prompt.Name = "ProRigPrompt"
    prompt.Style = Enum.ProximityPromptStyle.Custom -- вид рисует Invis.PromptUI (цвета интерфейса хаба)
    prompt:SetAttribute("ProRig", true)
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
    while Alive and not rig.failed do
        if not (rig.model and rig.model.Parent) then rig.Spawn() end
        task.wait(5)
    end
end)

    return rig
end

Invis.rig = Invis.NewRig({
    name = "ProShebRig",
    voiceFile = "mm2prohub_sheb_voice",
    pos = Vector3.new(55.914, 504.577, -12.487),
    yaw = 90, -- поворот вокруг вертикали в градусах = Orientation (0, 90, 0) в Studio; плюс = влево (против часовой сверху)
    idle = "rbxassetid://507766388", -- стандартная R15-анимация покоя, какую получает любой аватар при входе в Roblox
    label = "shebx436", -- надпись над головой
    lines = { "Дарова PRO хабер, веселись и завладей весь сервер детишек в мм2)" }, -- реплики по кругу при нажатии на «Поговорить»
    voice = {}, -- своя озвучка реплик (необязательно, перекрывает вшитую): voice[номер] = "rbxassetid://ID" ИЛИ имя файла (mp3/ogg) в папке workspace эксплоита
    voiceB64 = { [1] = "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hDxdiaxU4XXhODbKIhOKLwbc0hIioycLqLpJlF01Jw2MoyWTq6isqcLJpLwnm+V1v8opVOE3IiEsdXUbYeyiIRoFgfEBOODwpIjp1A2eNEpEIQeB4bIEaBdRdA6UZRWVLFSpxOlURCNDZ0ougbZRIVixdRt0oyiqknCcLq1VrqKypw6dUXYezIkrTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//uSxOSDlboK9gQZN8sowNPE8yW5VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVQ==" }, -- вшитая озвучка: номер реплики -> mp3 в base64 (реплика 1: «Дарова PRO хабер…»)
    file = "mm2prohub_sheb_rig_v1.rbxm",
    b64 = "PHJvYmxveCGJ/w0KGgoAABgAAAD5AAAAAAAAAAAAAABNRVRBJAAAACIAAAAAAAAA8BMBAAAAEgAAAEV4cGxpY2l0QXV0b0pvaW50cwQAAAB0cnVlU1NUUoKwAABMIgEAAAAAAFAAAAAAIAUADwIAEKAPAAAAQ1NHUEhTNgBcQkxPQ0s2ACQPJiMA+f//////////////////////////////////////////////////////////////////////////////////////////YQgAAAACACi1L/1g9DXNLwEaHO5+ORAQbUsHXISN22XU4JEFHjFtjhlEJsM1AaZZOIX9/pUQvs2yQmkhqtA2Do3CCiGycg+ECEAtGRElAQMI0wfTB2Cuiu0KPjiaFYT/YqHagwJc7mjjyQKzE5vgCILMsJH8mDHUgsgmS1l6nZf5rynavruCFZZLss/UuoiQjPYJL6AiC2U76vFV/E2yx2prVW5iPniZo8SoGksNzj+Lim2o7hypssetitg4W3m+Rnjhx1TsttMLNkfBRUaW4ZB3U9d+3Bm7gSCR1j7KV/bdLI6aMQAwvbFU5dSiGHI8To7VJkOFxr3gljyOCaB9itToQ9DEf5PKtjsVL9B+etilh1OygPVWFZH4GkbF/jJ1QhNJdtvShkfM8uguEXFepM8XdcWeQzLp5AO0P16sEZydCBiPH0+WzYkFdEnt3OCOK01svBme4r6w/cf4BcO0NTf9cHYm7DODXZ9NwIDWoRJaz84I+yyTFBonBBWHUaf6rNyCXTsX62wRNG/UytyInQVquVdKUtjDm7t9unknMPkbKb3jqsTJBRZ0775INbg8JUAqBA73x6tQURROcIdIZ6/h2rpmHhsdNAAZ8Vab1AYUXFrsJcJzpCD9CIYsOpxH+juuX+ckQGg3GSjAx5Bw8tguvs1CW3+AglgvnTPdKHhA/k0VPce827JTMCK9z9WpPxgou4Jp1f+gKHUmRE7sAWy8PdBklPNRydsWxmA/KGvR+ZYI7qgQVz/EduhMmmTtnTHSB+uYOd+LoM1FQfvhL7bOJ4LM/FhOH+wo5EyGwM2Xr2kfNETUH0uDto4VAv7HB4t3mkAzd5L5/I2q2Mc0eDK3HXH4nApTrqo2uHsi6a8hYOZhKOM2EeKkv3J54kCTgmfGkISa5R61eJVELV4HfL4o5cp/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MAAIHgACEgBT2ADZANoMAAIeAAgSAA4MAAIkAFHmAOUA50UiBAwAWd0A3gDYEgBRwwDCAMGYgQQYAAJOAAhCAAI2AAIYAA4MAFPeAOAA4WwAAh4AAgwACFoACBIAuQQABgAFAAoACQALDAACEgBTDAANAA4eAAIMAA8kABEE9QwRBvsMBmAACBgAAmAACBIAAgwAAgYADzYACwI8AAgkAAISAAKiAA8MAAUCHgAPNgAFD3gAC1MBAAAAA80NAioACBIAU1YAVwBYHgAIDAACigACKgAOGAACkABTRgBDAEUeAAIwAAISAAIeAFlCAEMARAwACB4AAjYAAhIAAioAAgwAAgYAAh4AAgYAAhIAAodhAhIACJYADhIAAh4ACOoAAiQAAgYACEgADwwAEQ82AAsInAAODAAIPAATt3MqBioACBIADwwAEQJgAAIqAA4MAAISAAhKAQ4MAAiMAQIMAPMCVABSAFEALgAvADAAMAAvADISAAKNJwIYAALFKBE0BRFZfQB+AHswAALaIFl7AHoAfR4AU1IAVABVVABTMgAvADNaAAIYAFMeACAAHB4AAloAU34AfQB/EgACMAACTgAIGAACnAAI2AAIEgBTQwBCAEWuAAIYAAJsAAIaARFGYjoCGAACEgACHgBROgA7ADxBDBO2XAECGAACJAAIEgACKgCzEQATABIAGAAZABoqAAISAAI+AQK6AFM4ADYAOboAAh4AAhgACNIAAt4cAh4AAioAU+UA5gDj/gQCHgACGAAC8gQIPAAIKgACGAAIZAUIEgAImAEIJAACYAACyS0CXgWzjgCNAI8A3wDgAN4uHgLXKwISADNnAGYXDBNsGAAC/yoCGAACEgBTGwAaABkYAAIsAQIYAAIMADMQABF8oxMSQgACHgACigACfgACDAACFAECYS8CJAACogACEgYCKgACDAACnAACNgYCGAACBgBT6ADpAOopKwI8AAIqABGZO0oCtAACV08ChRJTrQCsAK/8AAIYAAhgAAIMAAgkAALkADFfAF5gHzNmAGlFMFnEAMoAyxIAAk4AAjAAAggBAgUuAggEAhgAAiYEAvJWDhgAU1cAVgBZYAACQgAClAICKgBTyQDKAMQeAFPVANYA0XIAAgQFAloAApwAAm8NAhgAAhIAAjAAAkIAUdEA0ADV9Q4EQgAIMAACTAUCMAACMS4C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",
})

Invis.rig2 = Invis.NewRig({
    name = "ProYroRig",
    voiceFile = "mm2prohub_yro_voice",
    pos = Vector3.new(52.996, 504.527, -3.699),
    yaw = 56, -- Orientation (-0, 56, 0) в Studio
    idle = "rbxassetid://507766388",
    label = "yro788888", -- надпись над головой
    lines = { "А я простой Урито, который просто тут стоит и…" }, -- полный текст реплики пока не знаю (в имени mp3 он обрезан)
    voice = {},
    voiceB64 = { [1] = "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SNk2JScioykz0iI6hVVgw0iyMdWXfJXFDMGsPtRqql9XDyJ6T8Zmr4NnXTWUYTUQEexn1SHsJKJb1SRT//uSxO0BWbYQ/KeZIMMbwV+E8zH5GIkCeuFU02liZGqlayckJlNgmiiXmqhghkkk5ZFDT9mBU4PKm6pAuToEUC6NVxkUisQgKRlFEIhQWVdGT1i2OEo1atomBCgWIqNcToNRDCMZFyAYSJkJorMUmA+FWSFRNpstBEu1xMUEUDMhCK2h9dJrguTisGwuUWDR4jRrpjxeRgmEsiBgZkseSWXGs6xR6w1eUveLiDRk83BZS2eOZcvaRZmJTNiaayAUeGgLofZAjLR1Ue+X+MXFEUYo4lCBZAXChkJXZsMTrHPv4+sxWtX2jL8VKxx36kbq5mMvaycUUdEnT/BFlXbvKXftGcnEa0emG/as2/Fh6y8+uaK6aNCJ3xP4aQPMXXkiutnUFSq0tUH6IsKoSW+H64dRyZUq2SWhriQenaxCl5QmLhzUTioXkipovGx8cFkSS+4Jw6FK7MR6hEYjFgehKocopMkB4lUECAIALR48kj0kzJl+9tSJmR/4hGcamHO8KSMUkMN5cW0S1aWXpb7PhGFmmHlqeiSGUaukDTdZz3Of3f/7ksTpA9l6DPoHmSPDKsFfAPMyOZ1bY1NBJZVoaWVfNubqJqQE0N903JHaKVU5zV4kS9tPzVZd0K5IOrSmgC8R1RhsnYLVTO3E5J6GUIKpzpExKeLq42QCcuq5l6Jko8kOkpUfRs4t1UKqNlNReaRV8xYVokm3RQIxEIrI0KRwgMNIIoWIkx86QOPkC7OkpKROHGS3OnktBcQBgNComa9bGVoUOSRIkUbpZr+8NRNR74cSZLZk0jPOJEiWz5I0+HEtlq/8yxKmNIwS2crTgElRxIkDEpcijOaCkaqqcjh1SUSqqrmktihQsx8lUKFyzVqoZX5S1VwWJYoYJgiSoWdVQ5SyJqUc/tCzl7arNIt9yl1miEUilm1Y11kWxTCoZJRShQoRSiWaRItSFTSqkxShISUhJU0KQqeqhgFiVCz/UpkO0KmlhUKhUFhSFQyzFChFIpRSTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+5LE5ABXwg77B5kvwvRB3dSTJnhVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV" }, -- озвучка Yro, реплика 1
    file = "mm2prohub_yro_rig_v1.rbxm",
    b64 = "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AwkAGAMGAB4DCQAnAwYALQMGADMDBgA5AwkAQgMJAEsDBgBRAwkAWgMGAGADDABsAwwAeAMJAIEDCQCKAwYAkAMJAJkDBgCfAwYApQMDAKgDAwCrAwMArgMJALcDBgC9AwMAwAMGAMYDBgDMAwkA1QMJAN4DCQDnAwkA8AMMAPwDBgACBAkACwQGABEEBgAXBAkAIAQJACkEBgAvBAkAOAQDADsEBgBBBAMARAQDAEcEBgBNBAYAUwQJAFwECQBlBAkAbgQGAHQECQB9BAkAhgQJAI8ECQCYBAkAoQQMAK0ECQC2BAwAwgQJAMsECQDUBAkA3QQJAOYECQDvBAYA9QQMAAEFCQAKBQwAFgUJAB8FCQAoBQYALgUJADcFBgA9BQYAQwUGAEkFBgBPBQYAVQUGAFsFBgBhBQYAZwUGAG0FBgBzBQkAfAUGAIIFBgCIBQkAkQUGAJcFCQCgBQYApgUGAKwFCQC1BQMAuAUDALsFAwC+BQYAxAUJAM0FBgDTBQYA2QUGAN8FBgDlBQYA6wUGAPEFBgD3BQYA/QUJAAYGBgAMBgYAEgYGABgGDAAkBgwAMAYGADYGBgA8BgYAQgYDAEUGBgBLBgYAUQYGAFcGBgBdBgYAYwYMAG8GBgB1BgYAewYDAH4GBgCEBgkAjQYGAJMGBgCZBgkAogYGAKgGCQCxBgYAtwYGAL0GBgDDBgYAyQYJANIGBgDYBgYA3gYJAOcGBgDtBgYA8wYJAPwGCQAFBwYACwcGABEHAwAUBwYAGgcGACAHBgAmBwYALAcJADUHDABBBwYARwcGAE0HBgBTBwYAWQcJAGIHCQBrBwkAdAcGAHoHCQCDBwkAjAcGAJIHBgCYBwYAngcDAKEHCQCqBwMArQcDALAHBgC2BwkAvwcJAMgHCQDRBwYA1wcGAN0HBgDjBwYA6QcGAO8HBgD1BwYA+wcJAAQIBgAKCAYAEAgDABMIDAAfCAYAJQgGACsIBgAxCAkAOggJAEMIBgBJCAYATwgGAFUIBgBbCAYAYQgGAGcIBgBtCAkAdggGAHwICQCFCAkAjggGAJQIDACgCAkAqQgJALIIBgC4CAMAuwgGAMEIBgDHCAwA0wgJANwICQDlCAkA7ggJAPcIDAADCQYACQkJABIJCQAbCQkAJAkGACoJCQAzCQkAPAkJAEUJBgBLCQkAVAkMAGAJBgBmCQYAbAkMAHgJCQCBCQkAigkJAJMJCQCcCQwAqAkJALEJCQC6CQkAwwkMAM8JCQDYCQkA4QkMAO0JCQD2CQwAAgoJAAsKBgARCgkAGgoJACMKDAAvCgwAOwoJAEQKCQBNCgkAVgoJAF8KCQBoCgkAcQoJAHoKBgCACgkAiQoGAI8KDACbCgkApAoGAKoKCQCzCgkAvAoJAMUKBgDLCgYA0QoGANcKBgDdCgYA4woGAOkKCQDyCgwA/goJAAcLDAATCwkAHAsJACULCQAuCwkANwsMAEMLDABPCwkAWAsJAGELCQBqCwYAcAsJAHkLCQCCCwMAhQsGAIsLCQCUCwYAmgsJAKMLBgCpCwYArwsJALgLCQDBCwkAygsGANALCQDZCwkA4gsJAOsLDAD3CwkAAAwMAAwMCQAVDAkAHgwMACoMBgAwDAkAOQwMAEUMDABRDAwAXQwMAGkMDAB1DAYAewwJAIQMDACQDAkAmQwMAKUMCQCuDAkAtwwJAMAMDADMDAkA1QwMAOEMDADtDAwA+QwMAAUNDAARDQwAHQ0MACkNDAA1DQwAQQ0JAEoNCQBTDQkAXA0JAGUNDABxDQkAeg0MAIYNCQCPDQwAmw0MAKcNDACzDQkAvA0JAMUNDADRDQkA2g0JAOMNBgDpDQkA8g0JAPsNCQAEDgYACg4JABMOCQAcDgkAJQ4JAC4OCQA3DgYAPQ4JAEYOAwBJDgkAUg4DAFUOCQBeDgkAZw4GAG0ODAB5DgkAgg4GAIgOCQCRDgkAmg4GAKAOCQCpDgkAsg4JALsOCQDEDgkAzQ4MANkOBgDfDgYA5Q4JAO4OCQD3DgwAAw8MAA8PCQAYDwYAHg8MACoPDAA2DwkAPw8JAEgPCQBRDwwAXQ8JAGYPDAByDwkAew8JAIQPDACQDwwAnA8JAKUPCQCuDwYAtA8JAL0PDADJDwkA0g8MAN4PCQDnDwkA8A8JAPkPDAAFEAkADhAJABcQDAAjEAwALxAJADgQBgA+EAwAShAGAFAQDABcEAMAXxAMAGsQBgBxEAYAdxAJAIAQCQCJEAkAkhAGAJgQBgCeEAkApxAJALAQDAC8EAwAyBAMANQQDADgEAYA5hAGAOwQCQD1EAwAAREJAAoRCQATEQkAHBEJACURCQAuEQkANxEJAEARCQBJEQkAUhEJAFsRCQBkEQwAcBEJAHkRDACFEQwAkREMAJ0RDACpEQkAshEJALsRBgDBEQkAyhEMANYRCQDfEQkA6BEJAPERCQD6EQkAAxIMAA8SCQAYEgkAIRIJACoSCQAzEgwAPxIMAEsSDABXEgwAYxIMAG8SCQB4EgkAgRIMAI0SCQCWEgkAnxIMAKsSDAC3EgwAwxIJAMwSCQDVEgwA4RIJAOoSCQDzEgwA/xIMAAsTDAAXEwwAIxMMAC8TDAA7EwwARxMJAFATDABcEwkAZRMJAG4TDAB6EwkAgxMMAI8TDACbEwkApBMJAK0TCQC2EwkAvxMJAMgTCQDREwkA2hMJAOMTDADvEwkA+BMJAAEUDAANFAwAGRQJACIUDAAuFAkANxQMAEMUCQBMFAwAWBQGAF4UBgBkFAkAbRQMAHkUCQCCFAkAixQJAJQUCQCdFAwAqRQJALIUDAC+FAwAyhQJANMUDADfFAkA6BQMAPQUCQD9FAwACRUJABIVDAAeFQwAKhUJADMVDAA/FQYARRUJAE4VCQBXFQkAYBUMAGwVDAB4FQwAhBUMAJAVDACcFQwAqBUMALQVDADAFQwAzBUMANgVDADkFQkA7RUMAPkVDAAFFgwAERYJABoWCQAjFgkALBYMADgWCQBBFgwATRYGAFMWCQBcFgkAZRYJAG4WBgB0FgkAfRYMAIkWBgCPFgkAmBYJAKEWCQCqFgwAthYJAL8WDADLFgkA1BYJAN0WCQDmFgkA7xYJAPgWCQABFwwADRcJABYXCQAfFwkAKBcGAC4XCQA3FwYAPRcJAEYXDABSFwYAWBcGAF4XBgBkFwkAbRcMAHkXCQCCFwkAixcJAJQXCQCdFwkAphcJAK8XCQC4FwkAwRcGAMcXAwDKFwkA0xcJANwXBgDiFwwA7hcJAPcXDAADGAkADBgJABUYCQAeGAkAJxgJADAYBgA2GAYAPBgGAEIYCQBLGAkAVBgJAF0YDABpGAkAchgJAHsYBgCBGAkAihgJAJMYBgCZGAYAnxgJAKgYCQCxGAYAtxgJAMAYDADMGAwA2BgMAOQYCQDtGAkA9hgGAPwYCQAFGQMACBkJABEZBgAXGQYAHRkGACMZAwAmGQMAKRkGAC8ZAwAyGQMANRkDADgZBgA+GQYARBkDAEcZAwBKGQMATRkDAFAZBgBWGQMAWRkDAFwZAwBfGQMAYhkDAGUZAwBoGQMAaxkDAG4ZAwBxGQMAdBkDAHcZAwB6GQYAgBkGAIYZBgCMGQYAkhkGAJgZBgCeGQMAoRkDAKQZAwCnGQMAqhkDAK0ZAwCwGQMAsxkDALYZAwC5GQMAvBkDAL8ZAwDCGQMAxRkDAMgZAwDLGQMAzhkDANEZAwDUGQMA1xkDANoZAwDdGQMA4BkDAOMZAwDmGQMA6RkDAOwZAwDvGQMA8hkDAPUZAwD4GQMA+xkDAP4ZDAAKGgkAExoMAB8aDAArGgwANxoMAEMaDABPGgkAWBoMAGQaDABwGgkAeRoMAIUaCQCOGgkAlxoJAKAaDACsGgwAuBoMAMQaCQDNGgwA2RoJAOIaDADuGgYA9BoJAP0aCQAGGwwAEhsJABsbCQAkGwkALRsMADkbCQBCGwkASxsJAFQbDABgGwkAaRsMAHUbCQB+GwwAihsJAJMbCQCcGwkApRsJAK4bDAC6GwkAwxsGAMkbBgDPGwkA2BsJAOEbBgDnGwkA8BsGAPYbCQD/GwYABRwGAAscCQAUHAkAHRwJACYcDAAyHAwAPhwJAEccCQBQHAkAWRwJAGIcBgBoHAkAcRwJAHocDACGHAwAkhwJAJscBgChHAkAqhwJALMcDAC/HAYAxRwGAMscBgDRHAkA2hwJAOMcBgDpHAkA8hwJAPscCQAEHQkADR0GABMdCQAcHQYAIh0JACsdBgAxHQkAOh0GAEAdAwBDHQMARh0DAEkdAwBMHQMATx0DAFIdAwBVHQMAWB0DAFsdAwBeHQMAYR0DAGQdAwBnHQMAah0DAG0dAwBwHQMAcx0DAHYdAwB5HQMAfB0DAH8dAwCCHQMAhR0DAIgdAwCLHQMAjh0DAJEdAwCUHQMAlx0DAJodAwCdHQMAoB0GAKYdBgCsHQYAsh0GALgdBgC+HQYAxB0GAModBgDQHQYA1h0GANwdBgDiHQYA6B0GAO4dBgD0HQYA+h0GAAAeAwADHgMABh4DAAkeAwAMHgMADx4GABUeAwAYHgMAGx4DAB4eAwAhHgMAJB4DACceAwAqHgYAMB4GADYeBgA8HgYAQh4GAEgeBgBOHgMAUR4DAFQeBgBaHgYAYB4DAGMeBgBpHgMAbB4DAG8eAwByHgYAeB4GAH4eAwCBHgYAhx4DAIoeAwCNHgYAkx4DAJYeBgCcHgYAoh4GAKgeAwCrHgMArh4DALEeAwC0HgYAuh4GAMAeBgDGHgYAzB4DAM8eBgDVHgYA2x4GAOEeBgDnHgkA8B4GAPYeBgD8HgkABR8DAAgfAwALHwYAER8GABcfBgAdHwYAIx8GACkfBgAvHwkAOB8JAEEfBgBHHwkAUB8JAFkfBgBfHwkAaB8JAHEfAwB0HwMAdx8DAHofAwB9HwMAgB8DAIMfAwCGHwMAiR8DAIwfAwCPHwMAkh8DAJUfAwCYHwMAmx8DAJ4fAwChHwMApB8DAKcfAwCqHwYAsB8GALYfAwC5HwYAvx8DAMIfAwDFHwYAyx8GANEfAwDUHwMA1x8GAN0fBgDjHwYA6R8JAPIfCQD7HwkABCAJAA0gDAAZIAwAJSAJAC4gCQA3IAYAPSADAEAgCQBJIAkAUiAJAFsgCQBkIAYAaiAGAHAgAwBzIAMAdiADAHkgAwB8IAYAgiADAIUgCQCOIAkAlyADAJogAwCdIAMAoCADAKMgAwCmIAMAqSADAKwgBgCyIAYAuCAJAMEgBgDHIAYAzSAGANMgBgDZIAMA3CAGAOIgBgDoIAYA7iAGAPQgBgD6IAYAACEJAAkhCQASIQkAGyEGACEhCQAqIQYAMCEGADYhCQA/IQkASCEDAEshAwBOIQYAVCEGAFohBgBgIQYAZiEGAGwhAwBvIQYAdSEDAHghAwB7IQYAgSEGAIchBgCNIQYAkyEJAJwhBgCiIQMApSEGAKshAwCuIQYAtCEGALohCQDDIQMAxiEJAM8hCQDYIQMA2yEDAN4hBgDkIQMA5yEJAPAhBgD2IQMA+SEGAP8hAwACIgMABSIJAA4iBgAUIgYAGiIJACMiBgApIgMALCIDAC8iBgA1IgkAPiIGAEQiCQBNIgkAViIJAF8iCQBoIgkAcSIGAHciBgB9IgYAgyIDAIYiBgCMIgYAkiIGAJgiBgCeIgMAoSIDAKQiAwCnIgMAqiIDAK0iAwCwIgMAsyIDALYiAwC5IgMAvCIDAL8iAwDCIgMAxSIDAMgiAwDLIgMAziIDANEiAwDUIgMA1yIDANoiAwDdIgMA4CIDAOMiAwDmIgMA6SIGAO8iBgD1IgkA/iIDAAEjBgAHIwYADSMGABMjBgAZIwYAHyMDACIjCQArIwMALiMGADQjBgA6IwkAQyMDAEYjAwBJIwYATyMJAFgjBgBeIwkAZyMGAG0jBgBzIwYAeSMDAHwjAwB/IwMAgiMDAIUjAwCI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EgBiugu7C7wLKgACjAECohgIGAACKgACPAACHgYOEgACZgYCGAACPABoeQp4CnsKEgACPAACGAAObAAIEgACGhliKgsrCywLkAACEgACDAACYABo2QnYCdsJJAACEgACKgAIJAACcgACfgACqAAIDABieAp5CnoKEgACKgAOEgACWgAIHgAIEgBi2AnZCdoJEgAIDAACigACWgAOeAACGAAI4gUCEgACfgAIbAACGAACEgACDABf3AndCd48AAYCHgBitwm2CbkJDAAIKgAPEgAFAmQFAlYHU0oJSwlMPAAOEgACHgAIYAACtAAIEgACJABitgm3CbgJGABZHwkeCSESAAKAIgIYAAhCAAJEAQIGAAIYAAgMAAJoAWKvCK4IsQgYAAJgAAISAA5gAAIkAA42AAgYAGKuCK8IsAhCAAKWAAgSAAIqAAISAAgeAAhGIwIeAAKeHAgwAAISAAIqAALgHAISAAIkAAIMAA8eAAUIMAACDAACNgACWAICEgACQgACDAACGAACOBwEEgBCJAglCNoBDwYApwLICgLAAA8MAEcCdgsCYAAPDAA9DwYADwJaDA8kAAsOHgAINgAODAAI9gMPDAALAh4ACBoEDgwACBIACDAAAhgAAgYACBgAAgwACAYAAsIBCBIAAgwADhgACBIADwwABQI8AAgGAA+EAAUPGAALDx4ACwJgAAgkAA6CBQgeAAgMAA4qAAJOAAIGAAIeAA8MAC8CYgcCTgACZgYPEgALDx4ACw5CAA8wABcCKgAPBgBBAiYBCAYAAvAAAhIACAwADxIABQ4YAA42AA8kAAsIMAAC5AACEgAOMgEPEgAdAroDDk4ADhgADxIAEQKcAAIqAAIMAAImCgISAALGCQ4YAA8kAAsONgAIQgACDAAPBgAFAngACB4AAhIADlQAAhIAAvADDwYAEQKwAQIqAAI+AQIMAALEBQgSAAgqAA8MABECSAAPKgARCGYAAqAFAjwACgwABlQGAh4AAjYACGAAAjAAAhgACCQAAkwCCB4AAhIAAioAAgwACGAACAwAAiQADjwAAjYAAgYAAh4ADwwAIw42AAISAAIGAA9aACMCHAIPQgAFDlQAAhIAAjYAAgwACDwAAhgAAhIAAgYAAiQACBgADhIAAoABAgYAAh4AAgwAAgYACGIBBBIABlQACBIAAgwACAYADzwAAQjc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AGsZCQB0GQkAfRkMAIkZDACVGQwAoRkJAKoZDAC2GQkAvxkMAMsZCQDUGQwA4BkMAOwZDAD4GQkAARoJAAoaDAAWGgwAIhoMAC4aDAA6GgwARhoMAFIaDABeGgwAahoJAHMaDAB/GgwAixoJAJQaDACgGgwArBoMALgaCQDBGgYAxxoMANMaDADfGgwA6xoMAPcaCQAAGwwADBsMABgbDAAkGwkALRsMADkbCQBCGwkASxsJAFQbCQBdGwYAYxsJAGwbDAB4GwkAgRsJAIobDACWGwYAnBsJAKUbBgCrGwkAtBsGALobBgDAGwMAwxsGAMkbBgDPGwkA2BsJAOEbBgDnGwYA7RsGAPMbBgD5GwYA/xsDAAIcAwAFHAYACxwGABEcCQAaHAkAIxwJACwcBgAyHAkAOxwMAEccDABTHAwAXxwMAGscCQB0HAkAfRwJAIYcCQCPHAwAmxwJAKQcCQCtHAwAuRwMAMUcCQDOHAwA2hwJAOMcDADvHAkA+BwJAAEdDAANHQwAGR0MACUdDAAxHQYANx0JAEAdDABMHQkAVR0MAGEdCQBqHQwAdh0JAH8dCQCIHQwAlB0JAJ0dDACpHQwAtR0MAMEdCQDKHQkA0x0JANwdCQDlHQkA7h0MAPodDAAGHgwAEh4JABseBgAhHgkAKh4MADYeCQA/HgkASB4MAFQeDABgHgwAbB4MAHgeDACEHgwAkB4MAJweCQClHgkArh4MALoeCQDDHgwAzx4JANgeCQDhHgkA6h4JAPMeBgD5HgkAAh8GAAgfDAAUHwwAIB8JACkfCQAyHwYAOB8MAEQfCQBNHwkAVh8JAF8fBgBlHwwAcR8JAHofDACGHwYAjB8JAJUfDAChHwkAqh8MALYfCQC/HwYAxR8JAM4fCQDXHwkA4B8MAOwfDAD4HwwABCAJAA0gCQAWIAkAHyAJACggCQAxIAkAOiAJAEMgDABPIAwAWyAJAGQgCQBtIAkAdiAMAIIgCQCLIAkAlCAMAKAgCQCpIAkAsiAJALsgDADHIAwA0yAJANwgDADoIAwA9CAJAP0gBgADIQYACSEJABIhBgAYIQwAJCEJAC0hDAA5IQwARSEMAFEhCQBaIQwAZiEJAG8hDAB7IQwAhyEGAI0hDACZIQwApSEJAK4hDAC6IQkAwyEMAM8hDADbIQYA4SEJAOohBgDwIQkA+SEMAAUiCQAOIgkAFyIMACMiCQAsIgwAOCIMAEQiCQBNIgkAViIMAGIiDABuIgwAeiIMAIYiDACSIgwAniIJAKciDACzIgwAvyIMAMsiDADXIgkA4CIMAOwiDAD4IgwABCMJAA0jDAAZIwkAIiMMAC4jCQA3IwwAQyMJAEwjDABYIwkAYSMMAG0jDAB5IwwAhSMMAJEjDACdIwkApiMMALIjCQC7IwwAxyMMANMjBgDZIwYA3yMGAOUjAwDoIwkA8SMMAP0jCQAGJAwAEiQJABskCQAkJAwAMCQMADwkCQBFJAYASyQJAFQkBgBaJAkAYyQMAG8kDAB7JAkAhCQMAJAkDACcJAkApSQMALEkDAC9JAkAxiQMANIkCQDbJAwA5yQJAPAkCQD5JAkAAiUJAAslDAAXJQwAIyUJACwlCQA1JQwAQSUMAE0lDABZJQkAYiUMAG4lDAB6JQwAhiUMAJIlCQCbJQwApyUMALMlDAC/JQwAyyUMANclCQDgJQkA6SUGAO8lBgD1JQkA/iUGAAQmCQANJgkAFiYMACImCQArJgkANCYJAD0mDABJJgkAUiYMAF4mCQBnJgwAcyYGAHkmBgB/JgwAiyYJAJQmAwCXJgkAoCYMAKwmCQC1JgwAwSYMAM0mDADZJgwA5SYMAPEmDAD9JgwACScJABInDAAeJwkAJycMADMnDAA/JwkASCcJAFEnCQBaJwwAZicJAG8nCQB4JwwAhCcMAJAnCQCZJwwApScMALEnCQC6JwkAwycMAM8nCQDYJwkA4ScMAO0nDAD5JwkAAigMAA4oDAAaKAkAIygJACwoDAA4KAwARCgMAFAoDABcKAwAaCgJAHEoCQB6KAwAhigJAI8oDACbKAwApygMALMoDAC/KAkAyCgMANQoCQDdKAkA5igMAPIoDAD+KAwACikMABYpDAAiKQwALikMADopDABGKQwAUikJAFspCQBkKQwAcCkMAHwpDACIKQwAlCkJAJ0pDACpKQwAtSkJAL4pDADKKQwA1ikMAOIpCQDrKQwA9ykMAAMqDAAPKgwAGyoJACQqDAAwKgwAPCoJAEUqDABRKgkAWioMAGYqCQBvKgYAdSoMAIEqDACNKgkAlioMAKIqDACuKgwAuioJAMMqCQDMKgwA2CoJAOEqCQDqKgkA8yoMAP8qDAALKwYAESsMAB0rCQAmKwwAMisJADsrDABHKwkAUCsGAFYrDABiKwkAaysMAHcrDACDKwwAjysMAJsrDACnKwwAsysMAL8rCQDIKwwA1CsMAOArCQDpKwwA9SsJAP4rDAAKLAYAECwMABwsDAAoLAkAMSwMAD0sCQBGLAwAUiwMAF4sBgBkLAYAaiwGAHAsBgB2LAkAfywMAIssCQCULAwAoCwMAKwsDAC4LAkAwSwMAM0sBgDTLAwA3ywJAOgsDAD0LAwAAC0JAAktCQASLQkAGy0MACctCQAwLQkAOS0JAEItDABOLQwAWi0GAGAtBgBmLQMAaS0DAGwtCQB1LQYAey0GAIEtCQCKLQwAli0MAKItDACuLQwAui0MAMYtDADSLQkA2y0MAOctDADzLQwA/y0JAAguCQARLgwAHS4MACkuDAA1LgwAQS4MAE0uDABZLgwAZS4MAHEuDAB9LgwAiS4MAJUuDAChLgwArS4MALkuDADFLgwA0S4MAN0uDADpLgwA9S4MAAEvDAANLwwAGS8JACIvDAAuLwwAOi8JAEMvDABPLwwAWy8MAGcvDABzLwwAfy8JAIgvCQCRLwwAnS8MAKkvDAC1LwkAvi8MAMovDADWLwwA4i8MAO4vCQD3LwYA/S8MAAkwDAAVMAkAHjAJACcwBgAtMAkANjAMAEIwBgBIMAkAUTAJAFowDABmMAkAbzAJAHgwCQCBMAwAjTAMAJkwCQCiMAkAqzAMALcwCQDAMAwAzDAMANgwDADkMAkA7TAMAPkwCQACMQwADjEJABcxCQAgMQwALDEGADIxCQA7MQYAQTEJAEoxDABWMQkAXzEMAGsxCQB0MQwAgDEMAIwxCQCVMQYAmzEMAKcxDACzMQwAvzEJAMgxDADUMQwA4DEMAOwxDAD4MQkAATIMAA0yCQAWMgwAIjIMAC4yDAA6MgwARjIJAE8yDABbMgwAZzIMAHMyCQB8MgwAiDIMAJQyBgCaMgkAozIDAKYyAwCpMgkAsjIDALUyAwC4MgYAvjIGAMQyCQDNMgkA1jIJAN8yCQDoMgkA8TIJAPoyCQADMwkADDMGABIzCQAbMwkAJDMJAC0zCQA2MwYAPDMGAEIzBgBIMwkAUTMJAFozCQBjMwkAbDMJAHUzCQB+MwkAhzMJAJAzBgCWMwkAnzMGAKUzCQCuMwYAtDMJAL0zBgDDMwMAxjMGAMwzBgDSMwYA2DMD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AJYGAwCZBgMAnAYDAJ8GAwCiBgYAqAYGAK4GBgC0BgYAugYDAL0GBgDDBgYAyQYDAMwGAwDPBgYA1QYGANsGCQDkBgMA5wYGAO0GBgDzBgMA9gYJAP8GAwACBwYACAcGAA4HBgAUBwYAGgcDAB0HBgAjBwYAKQcGAC8HAwAyBwYAOAcGAD4HBgBEBwkATQcGAFMHBgBZBwYAXwcGAGUHCQBuBwYAdAcJAH0HDACJBwYAjwcGAJUHAwCYBwMAmwcGAKEHAwCkBwMApwcGAK0HBgCzBwYAuQcGAL8HAwDCBwMAxQcGAMsHBgDRBwYA1wcJAOAHBgDmBwYA7AcDAO8HBgD1BwYA+wcDAP4HBgAECAwAEAgJABkIDAAlCAwAMQgMAD0IDABJCAkAUggMAF4IDABqCAwAdggMAIIIDACOCAYAlAgGAJoIBgCgCAYApggGAKwIBgCyCAYAuAgGAL4IBgDECAYAyggGANAIBgDWCAYA3AgGAOIICQDrCAwA9wgJAAAJCQAJCQYADwkGABUJCQAeCQkAJwkMADMJDAA/CQwASwkJAFQJDABgCQwAbAkMAHgJCQCBCQkAigkMAJYJDACiCQkAqwkMALcJCQDACQkAyQkJANIJCQDbCQkA5AkJAO0JDAD5CQwABQoJAA4KDAAaCgwAJgoMADIKDAA+CgkARwoJAFAKCQBZCgwAZQoMAHEKCQB6CgwAhgoJAI8KCQCYCgkAoQoJAKoKDAC2CgkAvwoMAMsKCQDUCgwA4AoMAOwKCQD1CgkA/goJAAcLDAATCwkAHAsJACULCQAuCwkANwsMAEMLCQBMCwwAWAsJAGELCQBqCwwAdgsMAIILCQCLCwwAlwsJAKALDACsCwwAuAsJAMELDADNCwkA1gsJAN8LDADrCwkA9AsMAAAMCQAJDAwAFQwJAB4MCQAnDAwAMwwJADwMCQBFDAwAUQwJAFoMCQBjDAwAbwwMAHsMCQCEDAwAkAwJAJkMDAClDAkArgwJALcMCQDADAwAzAwJANUMCQDeDAwA6gwMAPYMCQD/DAwACw0MABcNCQAgDQkAKQ0JADINCQA7DQkARA0MAFANCQBZDQkAYg0GAGgNBgBuDQMAcQ0GAHcNBgB9DQYAgw0GAIkNBgCPDQMAkg0GAJgNBgCeDQYApA0JAK0NBgCzDQYAuQ0GAL8NBgDFDQYAyw0J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AjwADk4AAhIAWR4AHwAckAAPDAA1Am4BAqgADwwANVPsAO0A7jgBDwwAEQJQAQ4GAAKQAF/oAOkA6gwAGAIqAAgGAAK4AgIyAQ8MAAUCHgAOBgAClgACGAACDAAC6AICMgEPDAAFAh4ACAYAApAAAhIACAwAcYwAjQCOAJQ7NLN0AHUAdgB9AH8AfnIDU3EAcABzGAACJAACMAARcAheAhgAU10AXABfMAAIJABZWABZAFqupbNgAGEAYgBkAGUAZnIAAk4AAmgEU3oAewB4MAACKgACTgACDAAINgACEgBTaABpAGpIAALqAwJIAFNaAFsAWEgACBgAAgwAU0wATQBOvAQCEgACNgACDAAPHgAFWVAAUQBS5gQCDABTpAClAKbgBAISALPmAOcA5ADuAO8A7BgAU9gA3ADZPAACGAACEgCzwADBAMIAsQCwALMwAAIYAAISAHHYANkA2gDEZRwCEgBTtAC2ALcYAHHMAM0AzgAG9mYIGADCyADJAMoA0ADRANIAGAACJABZqQCoAKsYAGi9ALwAvwAYAFPUANEA0BIAU+oA6QDrEgBZuAC5ALoSAALEBVXhAOAA4xgABtYFCAwAWaEAoACj9AVTrQCsAK/2ALO0ALUAtgCwALEAshIADh4AAsYACCQAArQAU6wArQCuMAAIJAAC8AMIJAAOHgACJAAC9AUCDAACGAYCEgBTqACpAKoIAQ4MAAIOBAIYAAIMAAIGAAK6BgIMAAgwBgKsAgL2Aw8MAAczYgBj3gZVdAB2AHcMADN1AHYSAAIGAAJsAwgMAAISAAIGAAIOBAj8qAISAAIeAALiAgISAA8MABECGgECFAECDAACvgICEgACBgACPAYODAACsAEINgACEgACygICSAAIEgACGAACEAICsAEEEgAztgC3jAEI7AEO4AECkgECGAAIDAACuAICEgACngECEgAIDAAIvAECDAACBgAC/AYODAACqAMC8ANT/QD8AP/0CA4YAA4SAAIoCAI2AAI6CAIkAAISAALeA1PaANkA2xIAAiQAAgoFAhIAAtIDAioAAhIACB4AAvwDAiQAApwADh4AU9AA0gDT3gMCJAAC6gMCugMCEgAINgACpgUCEgBiDAEPAQ0BJAACGAACQAUIGAACEgACJAAPDAALAlwKAh4JAjAADhIADpwACBIAAioJAhoHAgwACCwHCEIDAgYDAoQDCBgACAwACCQAApYDAmwDCFQDAkIAAh4ADxgABQJgAw4eAAIYAAKEAwpsAAaICwgMAAgwAA4MAAISAAK6CQ4MAAIICgjsBwgMAAJABQJyAwIMAAgGAAIYAAKiAwIMAAJCAwIkAAgMAAgkAAIMAAL2AwIqAAI8AAgYAAIeAAIGAAIYAAIkAA8wAAUIJAAINgACDAACBgAC/gEIDAACEgAOBgACTgAIKgACEgACKgACDAACHgACDAACnAAIHgACEgAIHgAIDAAIxgAPDAAXAioAAgYAAqQBCGIBAhgACAYADiQACDAACB4ACBgADwwABQgwAA4MAAISAAIGAAJCAAI6BQISAAIMAA8YAEECWgACBgACbAMCBgAC3gMCDAACBgAPEgAFCBgAAgwAAgYAAs4BCAwADkgAAh4AAgYAAjAACCQADhgAAiYEAiQADgwAAjAAAhgADk4AAhgACDwACDAAAnACAiQAAjwAAgwAAj4EDwwABQg2AA8qAAsIQgACZAIOPAACQgAIBgACKgAIEgAIDAAIHgAI7AQPDAAFAjAAApwMAkgADyoABQIYAAgqAAKIAghCAAIkAA8GAAsCQgACJAAPDAALAh4AAgYAAmwAAgwAAgYACBIADwwABQKcAA74CggYAAIMAAT0CDO1ALb0CAIYAAI8AAJoBAgkAAJ4AwL0CAIqAAIkAAJCAAgeAAIYAALaBAIYAAJaAw8YAAUCKgACFgsCKgAIEgAIDAAClAICEgACDAACMAACBAsCFAEOEgACHgAC9AICBgAC9AICDAAIyAcCEgAOBgACuAICGAACDAACBgACQAIIDAACEgACBgAC8gEPDAAFAh4ACAYAAkQHAhIACAwAAv4BD7Ae///X9BEzMDQwMWE0M2RmNGZkOTJhZjM3YmFlYWMzNzJmM2I1MS4cBAIAI90OTRxkqAAAAF4FFwD3FgkACQAJABIACQAbAAkAJAAMADAADAA8AAkARQAMAFEABgBXAAk4WdcDAGwABgByAAYAeAAGXRz/AgYAlgAGAJwABgCiAAYAqAAJMFkA+zYJAN4ABgDkAAMA5wADAOoACQDzAAYA+QAGAP8ABgAFAQYACwEGABEBBgAXAQYAHQEGACMBAwAmAQMAKQEGAC8BBgA1AQOBHBcDUFkTCYEc2wMAawEDAG4BAwBxAQmFHJMGAJIBCQCbAQl5HJMJALMBBgC5AQltHPdyCQDRAQYA1wEJAOABBgDmAQYA7AEGAPIBCQD7AQkABAIMABACBgAWAgkAHwIGACUCAwAoAgYALgIDADECCQA6AgwARgIGAEwCAwBPAgYAVQIJAF4CBgBkAgMAZwIDAGoCBgBwAgMAcwIDAHYCBgB8AgYAggIJAIsCDACXAgYAnQIJdRxXDADHAgyYWfMiDAD0AgwAAAMJAAkDBgAPAwkAGAMJACEDDAAtAwkANgMJAD8DCQBIAwkAUQMJAFoDCXUc+yYMAHsDCQCEAwwAkAMJAJkDDAClAwwAsQMGALcDAwC6AwkAwwMMAM8DDADbAwwA5wMMAPMDBphZUwkAJgQMS+n/BgkARAQMAFAEDABcBAwAaAQMAHQEDJhZANsJALYEDADCBAYAyAQJnFkXCSkc8wIMAB8FDAArBQwANwUJAEAFDCEccwkABAAFAAbhGFkRABAAExIAArRLAh4AUw0ADAAPJAACEgBTDAANAA4YAAKPDQgYAAItBggYAAISALMdABwAHwDDAMIAwXgAAmYACCoAEdw5FFkdABwAHwwADiQAAh4AAngAAgwACAYADkIACIQAWTUANAA3EgAC0gAIGAAIEgACDAAC8AAIDAACEgACGgECDAACVRoCEgAIDABTGAAZABpiAQIeAAgSAAK4LA4SAAIgAQIyAQIkAA4SAAIeAAgGAAIUAQgqAAISAAIkAAIMAAKnELM5ADgAOwDFAMQAxyMWDxgABQIbEgIwAA4MAAISAFMgACEAIkMaAhIACDAACFoACAwACCoAAjAACB4ACAwAAioADhIAAjYAAh4ADgYACDAACKIADwwAHVO5ALgAu94ACDIBCAwAAn4AAhIAAjAAAmYAAlw0CAwAAsZOAhIADioACBIAAgwAAkIAAjYAAqEWAmYAAt4ADgwAAhcTAhgAUckAyADL7RYT0+wBAhIAAloACCQAAjYADioAAjAAAh4AU9YA1wDUEgACQgACDAACBgAIHgAIEgBTtQC0ALevFwIYAAISAAhCAAIMAAIGAAIkAAIMAAg2AAISAAgeAAISAAIGAAImAQIMAAgGAAgYAAI+AQIeAAIYAAgSALOAAIEAggAhACAAI+wBEVDKKQgSAAK2AQ8SAAUCpAECHgACXxkCQgBTVQBXAFYMAFNUAFUAVhIAAvYDAt4DWYsAigCJGAACSAARKDhOUzIAMQAzHgACGAACEgACcgBT4ADhAOL7HFOIAIkAiioAAhgAAosdAjAAAngAAhgAAhQEAn4ACBIACAwAAn0ZAhIAAgwAAkgAAgwAAlMNAhIAAhkXAgwAApYAAhIAAgwAAmgBAhIAArMNAhYCAncNAgwAApgBAhIACAwAAjYAAkIAAhgAAhIAAs4EU+QA5wDlVAACPAACGAACogACEgAPMAAFAioAAkIAU+0A7ADveAYCGAACQgACPAACAgECMgEIHgAC9gNRJQAkACfNGBF0klcTP0ACAhgAAiQAAgYAAhIACLYEAhYCApkVUz0APAA/PAYCGAACKRwOGAACOgJTeAB5AHpUAFNFAEQAR1oAAjAAAhgAAhIAAosXAloAUzwAPQA+qAAC3R8CJAAIGABTQQBAAEPmBwg2ALORAJMAkgA4ADkAOmwAAngAAhgACEgAAp4ECBgAAm4ECBgAU8QAxQDGmAQIGAACFxZTaQBoAGtCAAKcAAIYAAJuBwISADV8AH3BHQJOAAIrHQI2AAIwAAi2B1N9AHwAf8EdAjAAAlMQAvkYCDAAU5UAlACXCSECQgACtw8CKAgCMAACQgAC2AACIgUPEgAFAmkbAiQAAjwAAgwAAjkeAgwAAkAFAhIAU6UApACn6RACHgACNgBZoAChAKIYAAIwAAIqAAI9EQiiAAhUAAJmAwIqAAIkALPYANoA2wAdABwAH0IDAiQAAlQAAssQAjAAUY0AjACPPi8EGABTjACNAI42AA4wAAKzGVMdABwAH2ADAk4AAqgDU90A3ADfEgACugkOKgACGAACPAAInAMPiRD/PvQRNTYyNjhhZjI1N2Y2MWYyN2FjMjI4Nzk4NzhhZWM1NGPSDgQCACO/D/EOkcQAAABhBQAAAhoAkwkACQAGAA8ABkIr8wYGACQACQAtAAkANgAGADwABgBCAAP9DlMJAFoACfkOBE4rBCFokwkAkwAMAJ8ACe0OUwYAtwAM7Q7XBgDSAAYA2AAGAN4ADOkO8QYJAAIBCQALAQkAFAEMACABDAAsARsEAFNHAQwAUxAAk18BDABrAQwAdxAAe4MBDACPAQy1DvMmDAC/AQwAywEMANcBDADjAQwA7wEMAPsBDAAHAgwAEwIMAB8CDAArAgwANwIMAEMCDABPAgz2KlMMAHACDH0O82oMAI4CDACaAgkAowIMAK8CAwCyAgYAuAIDALsCBgDBAgYAxwIGAM0CBgDTAgYA2QIGAN8CBgDlAgMA6AIGAO4CBgD0AgYA+gIGAAADBgAGAwYADAMGABIDAwAVAwwAFQMMACEDCQAqAwYAMAMDADMDCQA8AwkARQMGHiv5CgYAVwMGAF0DCQBmAwYAbAMGAHIDBgB4AwYc+AQoAXuKAwYAkAMDNitXCQCuAwPRDtMDAL0DBgDDAwYAyQMGOiv1ggYA2wMJAOQDAwDnAwMA6gMGAPADAwDzAwMA9gMGAPwDBgACBAYACAQGAA4EAwARBAMAFAQGABoEAwAdBAYAIwQGACkEAwAsBAYAMgQJADsEDABHBAkAUAQJAFkECQBiBAYAaAQJAHEEBgB3BAYAfQQJAIYEBgCMBAYAkgQMAJ4EBgCkBAYAqgQGALAEBgC2BAYgAQQIABO8FAACMQ8CQAETywgABCQADAgAE840APMU1AQDANcEAwDaBAwA5gQJAO8EDAD7BAkABAUMABAFDAAcBQmKK9MMAD0FDABJBQwAVQUMtQm5KAAqACsAVQBUAFcMAAISAALDBwQPCgYSAALxCQIwAAgMAFNRAFAAU0gAAqQjDhIAAlQAUxkAGAAbDAACrQgCDAACGAAC+w4CGAACEgBTHQAcAB+hDgIYAA4SAFMOAA8ADMwAAk4ACJwACB4AAgwABCQABh4AAloADx4ABQLSAFlNAEwAT4oAAjAAAk0LAgwAAioACE4AMQAAAYYEOQIAAyoAAhgAAr0HAjwAAhIACAwAAisPAhgADgwAAk4AAisMAiQAAhIAAtUKAgwAApAAAgwAAsAAAhIACGURU9oA2wDY+RACfgACEgACVAAIogAIGAACkAACSwcCGAAClwkCkwdTLgAvACw5CrO2ALUAtwDNAMwAz+8LArEHAsMKAjYAApAANaYApVkICBgAs4UAhACHAB0AHAAfGAAC2QkCSABTHQAcAB/pCAISAAJkAg4YAAL4AQIeAAKLDAIwAFNwAHIAc5QCAqgACBgAs5EAkACTAGwAbQBuxgACMAACEgACgicIDAAC+CMCrwkIGAACNgBTaABpAGo2AAISAAKEAwKPUwgSAAKuAAIqABEwa2ICGQkCYAAIGAACQgACdQoCMwoCMAACKgACGCgCHQ4CwAMCHgACeAAChCsIGAAChwoCcQ4ITgACGAARIC4sAjAAAuQDAhgAAlgCAhIAAvsLCBgAAvcPU5QAlQCWGABTgACCAINeGwIeAAIYAAKNCgJ4AALOGgIeAAJGAgKwLLO+AL0AvwCeAJ0AnwULAksNAhgAAoICAs4mCDYAAhgAAhIADnACAloAU6IAowCg5AMCEgAC3AIIDAACbAACKgACBgMCJAACGAACKAICBgACgAECDAACBgAIEgACagIC6gAIGAAODAAIJAACDAACGgECKgAIEgACDCgCHgACGAAOJAAIGAAOMAACPAACBgAIKgACEgACxgAINgACqxMCEgACDAACKgACEgACDAACGAAOEgACGAACtgEPDAARD0IACwLaAQJOAA8MAAsCHgAIngQIDAACHgACngECGAAC9gAIEgAOJAACEgAIBgAIigAOGAAIVAACDAACqgECZgACMAACGAACEgACBgACkAACHgAOBgAPcgALCGIBAjwACDAAAgwACAYACDAAAhgADzYABQIYAALsAQIqAAIMAAIYAAISAA68AQ4YAA4SAAKEAA48AAIOAQJgAAJsAAgSAA8MAAUC0AIIMAAIEgAIbgECGAAIEgACngEIEgAPDAAFAjwAAmYACAwAAjAACEgAAgwACAYACDAAAkIAAgYAs0gASQBKADgAOQA6aAQCLAECGAACJgECEgACxjECGAACngQCMAACDAACLxECEgACJAACVB9T0QDQANM1EVPAAMIAwx4AAjYAAh4AAoYBAgwAAnIAAhIAAqIAAgcPAh4AAjYAAnYIAo6TAhgAAioAAtAFAhIAU9QA1QDWfxUCMAAIHgBT5ADlAOY2CQIYAAJmBg9nDzWCAAAAAP////8GAAYIAA8CAEMxAQABbgAPAgALBJQADwIATyIBAAIAIv//mAACCgAIAgACFAAPAgAH8UVMsLy+9EtlvpRqjz6g3Tk9jDhrPiz75j6AXoq91vDvPmBuO73wOcA9wYwUP6xviT4kAFsANTBlOWZhZTdjNzFhYWNlMDdiODQ4NDg5MTc3MjNkOWOxDwcCACM/FtMPZO4AAAA9CBoABMQekwYAGAAJACEADM8PlwkAPwAJAEgACcsP0wwAbwAJAHgACQCBAAnodwS8HvMGCQClAAkArgAJALcACQDAAAkAyQAJyw/3CgMA2wAGAOEADADtAAkA9gAJAP8ACQAIAQYpO/My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",
})

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
