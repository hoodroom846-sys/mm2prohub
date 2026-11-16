--[[
    MM2 PRO HUB v4.0  |  один файл: проверка ключа + скрипт
    Ключ проверяется прямо в скрипте: его последние 6 символов должны быть в списке KEY_ENDINGS.
    Готовый файл со списком окончаний выдаёт бот командой /script; ключи создаёт бот командой /genkey.
    RightShift — скрыть/показать окно хаба. Fly: WASD + Space / LeftShift. Клик/клавиша в интро — пропустить.
]]

local BOT_LINK   = "https://t.me/BYSHEB_bot"
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
    FarmFlySpeed = 24,
    FarmHideDepth = 3,   -- на сколько стадов ниже пола лежим
    FarmStartDelay = 0,  -- сколько секунд после старта раунда ждём, прежде чем лететь за монетами
    FarmTrigger = "coins", -- что считать стартом раунда: "role" (выдача ролей) или "coins" (появление монет)
    FlySpeed = 50,
    Aimbot = false,
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
local function GetRole(p)
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
    return scan(p.Character) or scan(p:FindFirstChildOfClass("Backpack")) or "Innocent"
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
    return math.clamp(math.min(vp.X / 820, vp.Y / 520), 0.5, 1)
end
local BaseScale = FitScale()

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 760, 0, 470),
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
        Size = UDim2.new(0, 220, 0, 12), Position = UDim2.new(0, 50, 0, 23), BackgroundTransparency = 1,
        Text = "PRO HUB  ·  v4.0", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 10,
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

-- ═══════════════ МЕНЮ СЛЕВА ═══════════════
local Sidebar = New("Frame", {
    Size = UDim2.new(0, 176, 1, -43), Position = UDim2.new(0, 0, 0, 43), BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0, Parent = Main,
})
Corner(Sidebar, 8)
New("Frame", { -- прячет верхние и правые скругления
    Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = Sidebar,
})
New("Frame", {
    Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0, Parent = Sidebar,
})
New("Frame", { -- правая граница
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0, Parent = Sidebar,
})

local ChipText, ChipDot, FpsLabel
do
    -- статус фарма + FPS
    local card = New("Frame", {
        Size = UDim2.new(1, -20, 0, 46), Position = UDim2.new(0, 10, 1, -126), BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0, Parent = Sidebar,
    })
    Corner(card, 6)
    Stroke(card)
    ChipDot = New("Frame", {
        Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Theme.TextDim,
        BorderSizePixel = 0, Parent = card,
    })
    Corner(ChipDot, 4)
    ChipText = New("TextLabel", {
        Size = UDim2.new(1, -34, 0, 16), Position = UDim2.new(0, 28, 0, 8), BackgroundTransparency = 1,
        Text = "Фарм выкл", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    FpsLabel = New("TextLabel", {
        Size = UDim2.new(1, -34, 0, 14), Position = UDim2.new(0, 28, 0, 25), BackgroundTransparency = 1,
        Text = "", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
    })
    -- профиль
    local prof = New("Frame", {
        Size = UDim2.new(1, -20, 0, 44), Position = UDim2.new(0, 10, 1, -70), BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0, Parent = Sidebar,
    })
    Corner(prof, 6)
    Stroke(prof)
    local av = New("ImageLabel", {
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 7, 0, 7), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LP.UserId .. "&w=150&h=150", Parent = prof,
    })
    Corner(av, 6)
    New("TextLabel", {
        Size = UDim2.new(1, -52, 0, 16), Position = UDim2.new(0, 44, 0, 7), BackgroundTransparency = 1,
        Text = LP.DisplayName, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = prof,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -52, 0, 12), Position = UDim2.new(0, 44, 0, 24), BackgroundTransparency = 1,
        Text = "@" .. LP.Name, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = prof,
    })
end

New("TextLabel", { -- подпись автора
    Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -22), BackgroundTransparency = 1, Text = "By shebx436",
    TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 11, Parent = Sidebar,
})

-- ═══════════════ КОНТЕНТ ═══════════════
local Content = New("Frame", {
    Size = UDim2.new(1, -176, 1, -43), Position = UDim2.new(0, 176, 0, 43), BackgroundTransparency = 1, Parent = Main,
})
local PageTitle = New("TextLabel", {
    Size = UDim2.new(1, -48, 0, 24), Position = UDim2.new(0, 24, 0, 14), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Content,
})
local PageSub = New("TextLabel", {
    Size = UDim2.new(1, -48, 0, 14), Position = UDim2.new(0, 24, 0, 40), BackgroundTransparency = 1, Text = "",
    TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Content,
})
local PagesHolder = New("Frame", {
    Size = UDim2.new(1, 0, 1, -66), Position = UDim2.new(0, 0, 0, 66), BackgroundTransparency = 1,
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
        Tween(t.Btn, 0.15, { BackgroundTransparency = on and 0 or 1 })
        Tween(t.Label, 0.15, { TextColor3 = on and Theme.Text or Theme.TextDim })
        Tween(t.Num, 0.15, { TextColor3 = on and Theme.Accent or Theme.TextDim })
        Tween(t.Marker, 0.15, { Size = UDim2.new(0, 3, 0, on and 18 or 0) })
        if on then PageTitle.Text, PageSub.Text = n, t.Sub end
    end
    CurrentTab = name
end

local function AddTab(name, glyph, order, sub)
    TabCount += 1
    local idx = TabCount
    local btn = New("TextButton", {
        Size = UDim2.new(1, -16, 0, 36), Position = UDim2.new(0, 8, 0, 14 + (idx - 1) * 40),
        BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 1, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "", Parent = Sidebar,
    })
    Corner(btn, 6)
    local marker = New("Frame", {
        Size = UDim2.new(0, 3, 0, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = btn,
    })
    Corner(marker, 2)
    local num = New("TextLabel", {
        Size = UDim2.new(0, 22, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = string.format("%02d", idx), TextColor3 = Theme.TextDim, Font = Enum.Font.Code, TextSize = 11, Parent = btn,
    })
    local lbl = New("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 42, 0, 0), BackgroundTransparency = 1,
        Text = name, TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })
    local dot = New("Frame", { -- «функция работает»
        Size = UDim2.new(0, 7, 0, 7), Position = UDim2.new(1, -16, 0.5, -3), BackgroundColor3 = Theme.Good,
        BorderSizePixel = 0, Visible = false, Parent = btn,
    })
    Corner(dot, 4)

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

    Tabs[name] = { Btn = btn, Label = lbl, Num = num, Marker = marker, Page = page, Sub = sub or "", Dot = dot, Index = idx }
    Connect(btn.MouseEnter, function()
        if CurrentTab ~= name then Tween(btn, 0.12, { BackgroundTransparency = 0.6 }) end
    end)
    Connect(btn.MouseLeave, function()
        if CurrentTab ~= name then Tween(btn, 0.12, { BackgroundTransparency = 1 }) end
    end)
    Connect(btn.MouseButton1Click, function() SelectTab(name) end)
    return page
end

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
        Text = "Привет, " .. LP.DisplayName, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -170, 0, 14), Position = UDim2.new(0, 80, 0, 42), BackgroundTransparency = 1,
        Text = "RightShift — скрыть / показать окно", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
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
    Connect(hit.MouseButton1Click, function()
        state = not state
        render()
        if callback then callback(state) end
        Notify(title, state and "Включено" or "Выключено")
    end)
end

local function AddSlider(page, title, min, max, default, callback)
    local card = Card(page, 62)
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
    local rows = math.ceil(#items / 2)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, rows * 88 - 8), BackgroundTransparency = 1, Parent = page,
    })
    local vals = {}
    for i, it in ipairs(items) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local tile = New("Frame", {
            Size = UDim2.new(0.5, -4, 0, 80), Position = UDim2.new(col * 0.5, col == 1 and 4 or 0, 0, row * 88),
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
        ChipText.Text = State.AutoFarm and "Фарм: пауза" or "Фарм выкл"
        ChipText.TextColor3 = State.AutoFarm and Theme.Text or Theme.TextDim
        ChipDot.BackgroundColor3 = State.AutoFarm and Theme.AccentHi or Theme.TextDim
        return
    end
    HUD.Visible = true
    local method = State.FarmMethod == "teleport" and "Teleport" or "Touch"
    local key = short .. "|" .. count .. "|" .. method .. "|" .. tostring(collecting)
    if key == lastUIKey then return end
    lastUIKey = key
    ChipText.Text = "Фарм " .. count .. "/" .. limit
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
    if ReturnHome then ReturnHome() end
    if RestoreCollisions then RestoreCollisions() end
    if RestoreFly then RestoreFly() end
    for _, p in pairs(Players:GetPlayers()) do ClearESP(p) end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = 16 end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    SG:Destroy()
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
AddSlider(PageSettings, "Масштаб окна, %", 60, 130, 100, function(v)
    BaseScale = FitScale() * (v / 100)
    MainScale.Scale = BaseScale
end)
AddButton(PageSettings, "Свернуть / показать  (RightShift)", Theme.Surface, function() Main.Visible = not Main.Visible end)
AddSection(PageSettings, "Сессия")
AddButton(PageSettings, "Выгрузить скрипт", Theme.Danger, Unload)

-- ═══════════════ СВОРАЧИВАНИЕ / ЗАКРЫТИЕ ═══════════════
local Pill = New("TextButton", {
    Size = UDim2.new(0, 46, 0, 46), Position = UDim2.new(0, 16, 0, 16),
    BorderSizePixel = 0, AutoButtonColor = false, Text = "", Visible = false, Parent = SG,
})
Corner(Pill, 10)
Stroke(Pill, Theme.Accent, 2)
BuildLogo(Pill, 10)

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
            if Alive then Main.Visible = false; Pill.Visible = true end
        end)
    end
end

Connect(MinBtn.MouseButton1Click, function() SetOpen(false) end)
do
    local dragging, moved, dragStart, startPos = false, false, nil, nil
    Connect(Pill.InputBegan, function(i)
        if IsPress(i) then
            dragging, moved, dragStart, startPos = true, false, i.Position, Pill.Position
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and IsMove(i) then
            local d = i.Position - dragStart
            if d.Magnitude > 5 then moved = true end
            if moved then
                local vp = SG.AbsoluteSize
                local x = math.clamp(startPos.X.Offset + d.X, 0, vp.X - Pill.AbsoluteSize.X)
                local y = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - Pill.AbsoluteSize.Y)
                Pill.Position = UDim2.new(0, x, 0, y)
            end
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if dragging and IsPress(i) then
            dragging = false
            if not moved then SetOpen(true) end
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
    local content = New("CanvasGroup", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 101, Parent = Intro,
    })
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
        "интерфейс", "карта и монеты", "роли и ESP", "автофарм",
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
    Notify("MM2 PRO HUB", "Загружен. RightShift: скрыть/показать")
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

local TpTarget, TpPhase, TpUntil, TpTries = nil, "away", 0, 0 -- режим Teleport: фаза "away" (за картой) / "grab" (у монеты)
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
local TP_DWELL = 0.12 -- сколько секунд стоим на монете (чтобы сервер успел засчитать касание)
local TP_GAP   = 0.08 -- пауза за картой между попытками

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
        CoinSel.Text = "Монеты: авто (" .. top.name .. ")"
        Notify("Монеты", "Найдено автоматически: " .. top.name)
    end
end

local function ResetCoinName()
    if CustomCoinName then
        CustomCoinName = nil
        RebuildCoins()
        CoinSel.Text = "Монеты: авто (по умолчанию coin / candy)"
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
                                LastTakenWhy = why .. (dup and " (дубль)" or "") .. (ours and "" or " (не наша)")
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
                FarmStatus.Text = string.format("%s   |   монета: %.0f, %.0f, %.0f   |   до неё: %.0f",
                    State.FarmMethod == "teleport" and (TpPhase == "grab" and "Телепорт к монете" or "За картой")
                        or (FarmPhase == "reach" and "Голова вверх" or "Лёжа под картой"),
                    tp.X, tp.Y, tp.Z, (tp - hrp.Position).Magnitude)
            elseif FarmMode == "warmup" and roundStart then
                FarmStatus.Text = string.format("Старт раунда: ждём %.0f с (лёжа под полом)",
                    math.max(0, State.FarmStartDelay - (now - roundStart)))
            elseif FarmMode == "collect" then
                FarmStatus.Text = "Раунд идёт, свободных монет нет"
            elseif sitOut then
                FarmStatus.Text = "Не в раунде (умер / в лобби): ждём следующий"
            elseif signal and not onMap then
                FarmStatus.Text = "Монеты есть, но ты не на карте (лобби): не фармим"
            elseif byRole then
                FarmStatus.Text = "Лобби: ждём выдачу ролей"
            else
                FarmStatus.Text = "Лобби: ждём появление монет"
            end
            local dbg = string.format("Монет найдено: %d   ·   Собрано: %d/%d   ·   Признак раунда: %s   ·   Ты на карте: %s   ·   Зачёт: %s",
                total, FarmCount, FARM_COIN_LIMIT, signal and "да" or "нет", (roundStart or onMap) and "да" or "нет", LastTakenWhy)
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
                FarmStatus.Text = "Статус: выключено"
            else
                FarmStatus.Text = "Мёртв / нет персонажа: фарм отключён"
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
        if FarmMode == "collect" and target and target:IsDescendantOf(workspace)
            and State.FarmMethod == "teleport" and HideY and math.abs(pos.Y - HideY) < 1.5 then
            -- Teleport: основное время сидим за картой (под полом), к монете — мгновенный прыжок и обратно
            local t = os.clock()
            local cp = target.Position
            local flat = Vector3.new(cp.X - pos.X, 0, cp.Z - pos.Z)
            if flat.Magnitude > 0.3 then FarmHeading = flat.Unit end
            if target ~= TpTarget then TpTarget, TpPhase, TpUntil, TpTries = target, "away", 0, 0 end
            local hidePos = Vector3.new(cp.X, HideY, cp.Z)
            if TpPhase == "away" and t >= TpUntil then
                TpPhase, TpUntil, TpTries = "grab", t + TP_DWELL, TpTries + 1
                ReachedTarget = target
                pos, FarmPitch = cp, math.pi / 2
                pcall(function() -- только если есть в эксплоите
                    if firetouchinterest then
                        firetouchinterest(hrp, target, 0)
                        firetouchinterest(hrp, target, 1)
                    end
                end)
            elseif TpPhase == "grab" then
                if t >= TpUntil then
                    TpPhase, TpUntil = "away", t + TP_GAP
                    pos, FarmPitch = hidePos, 0
                    if TpTries >= 3 then -- 3 касания, монета не исчезла: пропускаем
                        CoinSkip[target] = t + 4
                        FarmTarget, TpTarget = nil, nil
                    end
                else
                    pos = cp
                end
            else
                pos, FarmPitch = hidePos, 0
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
                    pos, FarmPitch = down, 0 -- Teleport: уходим под пол мгновенно, без полёта
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
                    Notify("Авто-подбор", "Пистолет: попытка " .. GunTries[gun])
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

-- ═══════════════ СТАРТ ═══════════════
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
        return false, "Неверный формат ключа"
    end
    if KEY_ENDINGS[k:sub(-6)] ~= true then return false, "Ключ недействителен" end
    return true, "Ключ принят"
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
    Text = "PRO HUB  ·  Активация", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11,
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
    Text = "КЛЮЧ ДОСТУПА", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 10,
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
    Text = "Вставь ключ из Telegram-бота", TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = Win,
})
local function SetStatus(text, color)
    Status.Text = text
    Status.TextColor3 = color or Theme.TextDim
end

local Go = New("TextButton", {
    Size = UDim2.new(1, -40, 0, 42), Position = UDim2.new(0, 20, 0, 198), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
    AutoButtonColor = false, Text = "Активировать", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 14, Parent = Win,
})
Corner(Go, 6)
Go.MouseEnter:Connect(function() Tween(Go, 0.12, { BackgroundTransparency = 0.15 }) end)
Go.MouseLeave:Connect(function() Tween(Go, 0.12, { BackgroundTransparency = 0 }) end)

local GetKey = New("TextButton", {
    Size = UDim2.new(1, -40, 0, 34), Position = UDim2.new(0, 20, 0, 250), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
    AutoButtonColor = false, Text = "Получить ключ (ссылка на бота)", TextColor3 = Theme.TextDim, Font = Enum.Font.GothamMedium,
    TextSize = 12, Parent = Win,
})
Corner(GetKey, 6)
Stroke(GetKey)
GetKey.MouseEnter:Connect(function() Tween(GetKey, 0.12, { BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text }) end)
GetKey.MouseLeave:Connect(function() Tween(GetKey, 0.12, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextDim }) end)
GetKey.MouseButton1Click:Connect(function()
    local ok = pcall(function() setclipboard(BOT_LINK) end)
    GetKey.Text = ok and "Ссылка скопирована: " .. BOT_LINK or BOT_LINK
    task.delay(3, function() if GetKey.Parent then GetKey.Text = "Получить ключ (ссылка на бота)" end end)
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
    if trimmed == "" then return SetStatus("Введи ключ", Theme.Danger) end
    if next(KEY_ENDINGS) == nil then
        return SetStatus("В скрипте нет окончаний ключей: возьми готовый файл у бота (команда /script)", Theme.Danger)
    end
    busy = true
    Go.Text = "Проверка…"
    task.spawn(function()
        local pok, ok, msg = pcall(VerifyKey, trimmed)
        busy = false
        Go.Text = "Активировать"
        if not pok then return SetStatus("Ошибка проверки: " .. tostring(ok), Theme.Danger) end
        if not ok then return SetStatus(tostring(msg), Theme.Danger) end
        SaveKey(trimmed)
        SetStatus("Ключ принят", Theme.Good)
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
        SetStatus("Проверяю сохранённый ключ…", Theme.TextDim)
        task.delay(0.5, function() if SG.Parent then Activate(saved) end end)
    end
end
