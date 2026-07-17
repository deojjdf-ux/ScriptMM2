-- [[ aDMin Script v14.0 — PRO AIMBOT (FOV + RAYCAST + SMART TARGET) + ENHANCED ESP ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 🛠️ HUD & CLIENT CUSTOMIZATION CONFIG
-- ==========================================
local Config = {
    Title = "=== aDMin Script v14.0 ===",
    SprintSpeed = 21,
    FlySpeed = 45,
    
    Aimbot = {
        Enabled = true,
        HoldToAim = true,
        AimKey = Enum.UserInputType.MouseButton2,
        AimKeyMobile = Enum.KeyCode.E,
        Smoothness = 1,
        TargetPart = "HumanoidRootPart",
        Prediction = true,
        PredictionFactor = 0.035,
        FOV = 200,
        ShowFOV = true,
        VisibleCheck = true
    },
    
    ESP = {
        Enabled = true,
        Boxes = true,
        Tracers = true,
        Names = true,
        Distance = true,
        HealthBar = true,
        HealthText = true,
        HeadDot = true,
        MaxDistance = 500,
        BoxType = "2D", -- "2D" или "Corner"
        TracerOrigin = "Bottom", -- "Bottom", "Mouse", "Center"
        TextSize = 13,
        TextFont = Drawing.Fonts.UI,
        BoxThickness = 1.5,
        TracerThickness = 1.2
    },
    
    HUD = {
        DefaultPosition = Vector2.new(20, 60),
        FontSize = 14,
        TextColor = Color3.fromRGB(155, 89, 182),
        Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        NotificationSize = 19
    },
    
    Colors = {
        Murderer = Color3.fromRGB(255, 50, 50),
        Sheriff = Color3.fromRGB(50, 150, 255),
        Hero = Color3.fromRGB(255, 215, 0),
        Innocent = Color3.fromRGB(0, 255, 100),
        Team = Color3.fromRGB(255, 255, 255),
        Friend = Color3.fromRGB(100, 255, 100)
    },
    
    Binds = {
        ESP = Enum.KeyCode.F5,
        Sprint = Enum.KeyCode.F6,
        SizeUp = Enum.KeyCode.N,
        SizeDown = Enum.KeyCode.M,
        ConsoleToggle = Enum.KeyCode.P
    }
}

-- Инициализация FOV Круга
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 30
FOVCircle.Radius = Config.Aimbot.FOV
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.5
FOVCircle.Visible = Config.Aimbot.ShowFOV
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

local flags = {
    esp = true,
    sprint = false,
    fly = false,
    noclip = false,
    hudVisible = true,
    spin = 0,
    freecam = false,
    bypass = false
}

local playerData = {}
local customBinds = {}
local lobbyPosition = nil
local currentMurderer = nil
local currentSheriff = nil
local activeNotifications = {}
local currentEmoteTrack = nil

local draggingHUD = false
local hudDragStart = Vector2.new(0, 0)
local hudStartPos = Vector2.new(0, 0)
local mNameStr = "Not Found"
local sNameStr = "Not Found"

local Vector2new, Vector3new, Color3fromRGB = Vector2.new, Vector3.new, Color3.fromRGB
local mathfloor, pairs, pcall, mathclamp = math.floor, pairs, pcall, math.clamp
local osclock = os.clock

local flyBV, flyBG

-- ==========================================
-- ENHANCED ESP SYSTEM
-- ==========================================
local function CreateESP(player)
    local espData = {
        Player = player,
        -- 2D Box
        BoxOutline = Drawing.new("Square"),
        BoxFill = Drawing.new("Square"),
        -- Corner Box
        CornerTL = Drawing.new("Line"),
        CornerTR = Drawing.new("Line"),
        CornerBL = Drawing.new("Line"),
        CornerBR = Drawing.new("Line"),
        -- Tracer
        Tracer = Drawing.new("Line"),
        -- Text
        NameText = Drawing.new("Text"),
        DistanceText = Drawing.new("Text"),
        WeaponText = Drawing.new("Text"),
        -- Health
        HealthBar = Drawing.new("Line"),
        HealthBarBg = Drawing.new("Line"),
        HealthText = Drawing.new("Text"),
        -- Head Dot
        HeadDot = Drawing.new("Circle"),
        -- Cache
        LastUpdate = 0,
        CachedColor = Config.Colors.Innocent
    }
    
    -- Настройка бокса
    espData.BoxOutline.Thickness = Config.ESP.BoxThickness
    espData.BoxOutline.Filled = false
    espData.BoxOutline.Visible = false
    
    espData.BoxFill.Thickness = 1
    espData.BoxFill.Filled = true
    espData.BoxFill.Transparency = 0.85
    espData.BoxFill.Visible = false
    
    -- Настройка корнеров
    for _, corner in pairs({espData.CornerTL, espData.CornerTR, espData.CornerBL, espData.CornerBR}) do
        corner.Thickness = 2.5
        corner.Visible = false
    end
    
    -- Настройка трассера
    espData.Tracer.Thickness = Config.ESP.TracerThickness
    espData.Tracer.Visible = false
    
    -- Настройка текста
    espData.NameText.Size = Config.ESP.TextSize
    espData.NameText.Center = true
    espData.NameText.Outline = true
    espData.NameText.Font = Config.ESP.TextFont
    espData.NameText.Visible = false
    
    espData.DistanceText.Size = Config.ESP.TextSize - 1
    espData.DistanceText.Center = true
    espData.DistanceText.Outline = true
    espData.DistanceText.Font = Config.ESP.TextFont
    espData.DistanceText.Visible = false
    
    espData.WeaponText.Size = Config.ESP.TextSize - 1
    espData.WeaponText.Center = true
    espData.WeaponText.Outline = true
    espData.WeaponText.Font = Config.ESP.TextFont
    espData.WeaponText.Visible = false
    
    -- Настройка хелсбара
    espData.HealthBar.Thickness = 2
    espData.HealthBar.Visible = false
    espData.HealthBarBg.Thickness = 2
    espData.HealthBarBg.Visible = false
    espData.HealthBarBg.Color = Color3fromRGB(0, 0, 0)
    espData.HealthBarBg.Transparency = 0.5
    
    espData.HealthText.Size = Config.ESP.TextSize - 2
    espData.HealthText.Center = true
    espData.HealthText.Outline = true
    espData.HealthText.Visible = false
    
    -- Настройка точки на голове
    espData.HeadDot.Radius = 3
    espData.HeadDot.Filled = true
    espData.HeadDot.Visible = false
    
    return espData
end

local function DestroyESP(espData)
    for _, drawing in pairs(espData) do
        if typeof(drawing) == "Instance" or (typeof(drawing) == "table" and drawing.Remove) then
            pcall(function() drawing:Remove() end)
        end
    end
end

local function GetPlayerColor(player)
    if currentMurderer == player then
        return Config.Colors.Murderer
    elseif currentSheriff == player then
        return Config.Colors.Sheriff
    elseif player.Team == LocalPlayer.Team and player.Team ~= nil then
        return Config.Colors.Team
    end
    return Config.Colors.Innocent
end

local function GetHealthColor(health)
    local maxHealth = 100
    local percentage = health / maxHealth
    
    if percentage > 0.6 then
        return Color3fromRGB(0, 255, 100) -- Зелёный
    elseif percentage > 0.3 then
        return Color3fromRGB(255, 255, 0) -- Жёлтый
    else
        return Color3fromRGB(255, 50, 50) -- Красный
    end
end

local function UpdateESP(espData)
    local player = espData.Player
    local character = player.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
        -- Скрыть все элементы
        for _, drawing in pairs(espData) do
            if typeof(drawing) == "table" and drawing.Visible ~= nil then
                drawing.Visible = false
            end
        end
        return
    end
    
    local hum = character.Humanoid
    local root = character.HumanoidRootPart
    local head = character:FindFirstChild("Head")
    
    if hum.Health <= 0 then
        for _, drawing in pairs(espData) do
            if typeof(drawing) == "table" and drawing.Visible ~= nil then
                drawing.Visible = false
            end
        end
        return
    end
    
    local rootPos = root.Position
    local camPos = Camera.CFrame.Position
    local distance = (camPos - rootPos).Magnitude
    
    -- Проверка дистанции
    if distance > Config.ESP.MaxDistance then
        for _, drawing in pairs(espData) do
            if typeof(drawing) == "table" and drawing.Visible ~= nil then
                drawing.Visible = false
            end
        end
        return
    end
    
    -- Получаем позиции для рендера
    local rootScreenPos, rootOnScreen = Camera:WorldToViewportPoint(rootPos)
    if not rootOnScreen or rootScreenPos.Z <= 0 then
        for _, drawing in pairs(espData) do
            if typeof(drawing) == "table" and drawing.Visible ~= nil then
                drawing.Visible = false
            end
        end
        return
    end
    
    local headScreenPos = Vector2new(rootScreenPos.X, rootScreenPos.Y)
    local legScreenPos = Vector2new(rootScreenPos.X, rootScreenPos.Y)
    
    if head then
        local headPos = head.Position + Vector3new(0, 0.5, 0)
        local headScreen, headOnScreen = Camera:WorldToViewportPoint(headPos)
        if headOnScreen then
            headScreenPos = Vector2new(headScreen.X, headScreen.Y)
        end
    end
    
    -- Размеры персонажа
    local characterHeight = (headScreenPos.Y - rootScreenPos.Y) * 2
    local boxWidth = characterHeight / 2.8
    local boxHeight = math.abs(rootScreenPos.Y - headScreenPos.Y) + characterHeight / 4
    
    local boxX = rootScreenPos.X - boxWidth / 2
    local boxY = headScreenPos.Y - characterHeight / 8
    local boxBottom = boxY + boxHeight
    
    local color = GetPlayerColor(player)
    local healthPercentage = hum.Health / hum.MaxHealth
    local healthColor = GetHealthColor(hum.Health)
    
    -- Обновляем кэш цвета
    espData.CachedColor = color
    
    -- 2D Box
    if Config.ESP.Boxes and Config.ESP.BoxType == "2D" then
        espData.BoxOutline.Size = Vector2new(boxWidth, boxHeight)
        espData.BoxOutline.Position = Vector2new(boxX, boxY)
        espData.BoxOutline.Color = color
        espData.BoxOutline.Visible = true
        
        espData.BoxFill.Size = Vector2new(boxWidth, boxHeight)
        espData.BoxFill.Position = Vector2new(boxX, boxY)
        espData.BoxFill.Color = color
        espData.BoxFill.Visible = true
    else
        espData.BoxOutline.Visible = false
        espData.BoxFill.Visible = false
    end
    
    -- Corner Box
    if Config.ESP.Boxes and Config.ESP.BoxType == "Corner" then
        local cornerLength = boxWidth * 0.3
        
        -- Top Left
        espData.CornerTL.From = Vector2new(boxX, boxY)
        espData.CornerTL.To = Vector2new(boxX, boxY + cornerLength)
        espData.CornerTL.Color = color
        espData.CornerTL.Visible = true
        
        -- Top Right
        espData.CornerTR.From = Vector2new(boxX + boxWidth, boxY)
        espData.CornerTR.To = Vector2new(boxX + boxWidth, boxY + cornerLength)
        espData.CornerTR.Color = color
        espData.CornerTR.Visible = true
        
        -- Bottom Left
        espData.CornerBL.From = Vector2new(boxX, boxBottom)
        espData.CornerBL.To = Vector2new(boxX, boxBottom - cornerLength)
        espData.CornerBL.Color = color
        espData.CornerBL.Visible = true
        
        -- Bottom Right
        espData.CornerBR.From = Vector2new(boxX + boxWidth, boxBottom)
        espData.CornerBR.To = Vector2new(boxX + boxWidth, boxBottom - cornerLength)
        espData.CornerBR.Color = color
        espData.CornerBR.Visible = true
        
        -- Верхние горизонтальные линии
        local topLine = Drawing.new("Line")
        topLine.From = Vector2new(boxX, boxY)
        topLine.To = Vector2new(boxX + cornerLength, boxY)
        topLine.Color = color
        topLine.Thickness = 2.5
        
        local topLine2 = Drawing.new("Line")
        topLine2.From = Vector2new(boxX + boxWidth - cornerLength, boxY)
        topLine2.To = Vector2new(boxX + boxWidth, boxY)
        topLine2.Color = color
        topLine2.Thickness = 2.5
    else
        espData.CornerTL.Visible = false
        espData.CornerTR.Visible = false
        espData.CornerBL.Visible = false
        espData.CornerBR.Visible = false
    end
    
    -- Tracer
    if Config.ESP.Tracers then
        local tracerOrigin
        
        if Config.ESP.TracerOrigin == "Bottom" then
            tracerOrigin = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        elseif Config.ESP.TracerOrigin == "Mouse" then
            tracerOrigin = UserInputService:GetMouseLocation()
        else -- Center
            tracerOrigin = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
        
        espData.Tracer.From = tracerOrigin
        espData.Tracer.To = Vector2new(rootScreenPos.X, rootScreenPos.Y)
        espData.Tracer.Color = color
        espData.Tracer.Transparency = 0.7
        espData.Tracer.Visible = true
    else
        espData.Tracer.Visible = false
    end
    
    -- Name
    if Config.ESP.Names then
        espData.NameText.Text = player.DisplayName
        espData.NameText.Position = Vector2new(rootScreenPos.X, headScreenPos.Y - characterHeight / 4 - 15)
        espData.NameText.Color = color
        espData.NameText.Visible = true
    else
        espData.NameText.Visible = false
    end
    
    -- Distance
    if Config.ESP.Distance then
        espData.DistanceText.Text = string.format("[%dm]", mathfloor(distance))
        espData.DistanceText.Position = Vector2new(rootScreenPos.X, headScreenPos.Y - characterHeight / 4 - 2)
        espData.DistanceText.Color = Color3fromRGB(255, 255, 255)
        espData.DistanceText.Visible = true
    else
        espData.DistanceText.Visible = false
    end
    
    -- Weapon Info
    local weapon = "None"
    if character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
        weapon = "🔪 Knife"
    elseif character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then
        weapon = "🔫 Gun"
    end
    
    if weapon ~= "None" then
        espData.WeaponText.Text = weapon
        espData.WeaponText.Position = Vector2new(rootScreenPos.X, boxBottom + 2)
        espData.WeaponText.Color = (weapon == "🔪 Knife" and Config.Colors.Murderer or Config.Colors.Sheriff)
        espData.WeaponText.Visible = true
    else
        espData.WeaponText.Visible = false
    end
    
    -- Health Bar
    if Config.ESP.HealthBar then
        local barX = boxX - 7
        local barY = boxY
        local barHeight = boxHeight
        local healthHeight = barHeight * healthPercentage
        
        -- Background
        espData.HealthBarBg.From = Vector2new(barX, barY)
        espData.HealthBarBg.To = Vector2new(barX, barY + barHeight)
        espData.HealthBarBg.Visible = true
        
        -- Health
        espData.HealthBar.From = Vector2new(barX, barY + barHeight - healthHeight)
        espData.HealthBar.To = Vector2new(barX, barY + barHeight)
        espData.HealthBar.Color = healthColor
        espData.HealthBar.Visible = true
    else
        espData.HealthBar.Visible = false
        espData.HealthBarBg.Visible = false
    end
    
    -- Health Text
    if Config.ESP.HealthText then
        espData.HealthText.Text = mathfloor(hum.Health) .. "HP"
        espData.HealthText.Position = Vector2new(rootScreenPos.X, boxBottom + 14)
        espData.HealthText.Color = healthColor
        espData.HealthText.Visible = true
    else
        espData.HealthText.Visible = false
    end
    
    -- Head Dot
    if Config.ESP.HeadDot and head then
        local headDotPos, headDotOnScreen = Camera:WorldToViewportPoint(head.Position)
        if headDotOnScreen then
            espData.HeadDot.Position = Vector2new(headDotPos.X, headDotPos.Y)
            espData.HeadDot.Color = color
            espData.HeadDot.Visible = true
        end
    else
        espData.HeadDot.Visible = false
    end
end

-- Helpers
local function FindKeyCode(keyName)
    local lowerName = string.lower(keyName)
    for _, enumItem in pairs(Enum.KeyCode:GetEnumItems()) do
        if string.lower(enumItem.Name) == lowerName then return enumItem end
    end
    return nil
end

local function GetPlayerByPartialName(name)
    name = string.lower(name)
    for _, player in pairs(Players:GetPlayers()) do
        if string.sub(string.lower(player.Name), 1, #name) == name or string.sub(string.lower(player.DisplayName), 1, #name) == name then
            return player
        end
    end
    return nil
end

-- ==========================================
-- INTERACTIVE DRAWING HUD
-- ==========================================
local HUD = Drawing.new("Text")
HUD.Size = Config.HUD.FontSize
HUD.Color = Config.HUD.TextColor
HUD.Outline = Config.HUD.Outline
HUD.OutlineColor = Config.HUD.OutlineColor
HUD.Position = Config.HUD.DefaultPosition
HUD.Visible = true

local fpsFrameCount = 0
local fpsLastUpdate = osclock()
local currentFps = 60

-- ==========================================
-- MINECRAFT STYLE COMMAND LINE UI
-- ==========================================
local parentUI
local success, _ = pcall(function() parentUI = game:GetService("CoreGui") end)
if not success or not parentUI then parentUI = LocalPlayer:WaitForChild("PlayerGui") end

local oldConsole = parentUI:FindFirstChild("aDMinConsole")
if oldConsole then oldConsole:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "aDMinConsole"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentUI

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 42)
MainFrame.Position = UDim2.new(0, 20, 1, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.35
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Config.HUD.TextColor
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = MainFrame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 1, 0)
TextBox.Position = UDim2.new(0, 10, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.Font = Enum.Font.Code
TextBox.TextSize = 16
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.Text = ""
TextBox.PlaceholderText = "Type command or press RAlt..."
TextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
TextBox.Parent = MainFrame

local SuggestionLabel = Instance.new("TextLabel")
SuggestionLabel.Size = UDim2.new(1, 0, 0, 26)
SuggestionLabel.Position = UDim2.new(0, 0, 0, -32)
SuggestionLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
SuggestionLabel.BackgroundTransparency = 0.4
SuggestionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
SuggestionLabel.Font = Enum.Font.Code
SuggestionLabel.TextSize = 14
SuggestionLabel.TextXAlignment = Enum.TextXAlignment.Left
SuggestionLabel.Visible = false
SuggestionLabel.Parent = MainFrame

local SuggestionCorner = Instance.new("UICorner")
SuggestionCorner.CornerRadius = UDim.new(0, 4)
SuggestionCorner.Parent = SuggestionLabel

local SuggestionStroke = Instance.new("UIStroke")
SuggestionStroke.Color = Config.HUD.TextColor
SuggestionStroke.Thickness = 1
SuggestionStroke.Parent = SuggestionLabel

local commandList = {
    "/esp", "/sprint", "/aimbot", "/speed", 
    "/prediction", "/smoothness", "/hudsize", 
    "/fly", "/noclip", "/tpgun", "/bind", "/clear", "/help",
    "/scb", "/scoreboard", "/tp", "/re", "/respawn", "/infyield", "/rj", "/rejoin",
    "/load", "/l", "/spin", "/time", "/freecam", "/bypass", "/fling", "/marder", "/sheriff", "/emote",
    "/fov", "/fovsize", "/visiblecheck", "/espbox", "/esptracer", "/esphealth", "/esphead"
}

local function GetSuggestion(inputText)
    if #inputText == 0 then return "" end
    local args = string.split(inputText, " ")
    local baseCmd = string.lower(args[1] or "")
    if #args == 1 then
        for _, cmd in ipairs(commandList) do
            if string.sub(cmd, 1, #baseCmd) == baseCmd then return cmd end
        end
    elseif #args == 2 then
        local checkOpts = {"/esp", "esp", "/sprint", "sprint", "/aimbot", "aimbot", "/prediction", "prediction", "/fly", "fly", "/noclip", "noclip", "/visiblecheck", "visiblecheck", "/fov", "fov", "/espbox", "espbox", "/esptracer", "esptracer", "/esphealth", "esphealth", "/esphead", "esphead"}
        if table.find(checkOpts, baseCmd) then
            local arg1 = string.lower(args[2] or "")
            local opts = {"on", "off"}
            for _, opt in ipairs(opts) do
                if string.sub(opt, 1, #arg1) == arg1 then return args[1] .. " " .. opt end
            end
        end
    end
    return ""
end

-- ==========================================
-- NOTIFICATION SYSTEM
-- ==========================================
local function CreateNotification(text, color)
    local notif = Drawing.new("Text")
    notif.Size = Config.HUD.NotificationSize
    notif.Color = color
    notif.Outline = true
    notif.OutlineColor = Color3fromRGB(0, 0, 0)
    notif.Center = true
    notif.Text = text
    notif.Visible = true
    
    table.insert(activeNotifications, notif)
    for i, n in pairs(activeNotifications) do
        n.Position = Vector2new(Camera.ViewportSize.X / 2, 120 + (i * 25))
    end
    
    task.spawn(function()
        task.wait(4)
        notif.Visible = false
        notif:Remove()
        local idx = table.find(activeNotifications, notif)
        if idx then
            table.remove(activeNotifications, idx)
            for i, n in pairs(activeNotifications) do
                n.Position = Vector2new(Camera.ViewportSize.X / 2, 120 + (i * 25))
            end
        end
    end)
end

-- ==========================================
-- RAYCAST FILTER (PRO)
-- ==========================================
local function IsVisible(targetPart)
    if not Config.Aimbot.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- ==========================================
-- SMART TARGET SELECTION (PRO FOV + VISIBLE CHECK)
-- ==========================================
local function GetAimbotTarget()
    local bestTarget = nil
    local closestDistance = Config.Aimbot.FOV
    local mousePos = Vector2new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local amIMurderer = (currentMurderer == LocalPlayer)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Config.Aimbot.TargetPart) then
            local char = player.Character
            local root = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                local vector, onScreen = Camera:WorldToViewportPoint(root.Position)
                local distanceToMouse = (Vector2new(vector.X, vector.Y) - mousePos).Magnitude
                
                if onScreen and distanceToMouse < closestDistance then
                    if IsVisible(char[Config.Aimbot.TargetPart]) then
                        if amIMurderer then
                            if currentSheriff == player then return char end
                        else
                            if currentMurderer == player then return char end
                        end
                        closestDistance = distanceToMouse
                        bestTarget = char
                    end
                end
            end
        end
    end
    return bestTarget
end

-- ==========================================
-- CORE CHEAT MECHANICS
-- ==========================================
local function toggleFly(state)
    flags.fly = state
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    if hum then hum.PlatformStand = state end
    
    if state and root and hum and hum.Health > 0 then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3new(0, 0, 0)
        flyBV.Parent = root
        
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3new(1e5, 1e5, 1e5)
        flyBG.CFrame = Camera.CFrame
        flyBG.Parent = root
    end
end

local function tpToGun()
    local gunDrop = workspace:FindFirstChild("GunDrop")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if gunDrop and root then
        root.CFrame = gunDrop.CFrame + Vector3new(0, 2, 0)
        CreateNotification("Teleported to Gun Drop!", Config.Colors.Hero)
    else
        CreateNotification("Gun Drop not found on the map!", Config.Colors.Murderer)
    end
end

-- ==========================================
-- COMMAND EXECUTION PROCESSOR
-- ==========================================
local function ExecuteCommand(inputText)
    inputText = string.gsub(inputText, "^/+", "")
    local args = string.split(inputText, " ")
    local cmd = string.lower(args[1] or "")
    
    if cmd == "time" then
        local realTime = os.date("%H:%M")
        CreateNotification("Текущее время: " .. realTime, Color3fromRGB(255, 255, 255))
        
    elseif cmd == "marder" or cmd == "murderer" then
        if currentMurderer then CreateNotification("🔪 Убийца: " .. currentMurderer.DisplayName, Config.Colors.Murderer)
        else CreateNotification("Убийца пока неизвестен!", Config.Colors.Hero) end
        
    elseif cmd == "sheriff" then
        if currentSheriff then CreateNotification("👮 Шериф: " .. currentSheriff.DisplayName, Config.Colors.Sheriff)
        else CreateNotification("Шериф неизвестен или пистолет брошен!", Config.Colors.Hero) end
        
    elseif cmd == "fov" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then Config.Aimbot.ShowFOV = true CreateNotification("FOV Circle: ON", Config.Colors.Hero)
        elseif opt == "off" then Config.Aimbot.ShowFOV = false CreateNotification("FOV Circle: OFF", Config.Colors.Hero)
        else Config.Aimbot.ShowFOV = not Config.Aimbot.ShowFOV CreateNotification("FOV Circle: " .. (Config.Aimbot.ShowFOV and "ON" or "OFF"), Config.Colors.Hero) end
        
    elseif cmd == "fovsize" then
        local val = tonumber(args[2])
        if val then
            Config.Aimbot.FOV = val
            FOVCircle.Radius = val
            CreateNotification("FOV Size: " .. val, Config.Colors.Hero)
        end
        
    elseif cmd == "visiblecheck" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then Config.Aimbot.VisibleCheck = true CreateNotification("Visible Check: ON", Config.Colors.Hero)
        elseif opt == "off" then Config.Aimbot.VisibleCheck = false CreateNotification("Visible Check: OFF", Config.Colors.Hero)
        else Config.Aimbot.VisibleCheck = not Config.Aimbot.VisibleCheck CreateNotification("Visible Check: " .. (Config.Aimbot.VisibleCheck and "ON" or "OFF"), Config.Colors.Hero) end
        
    elseif cmd == "espbox" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then Config.ESP.Boxes = true CreateNotification("ESP Boxes: ON", Config.Colors.Hero)
        elseif opt == "off" then Config.ESP.Boxes = false CreateNotification("ESP Boxes: OFF", Config.Colors.Hero)
        else Config.ESP.Boxes = not Config.ESP.Boxes CreateNotification("ESP Boxes: " .. (Config.ESP.Boxes and "ON" or "OFF"), Config.Colors.Hero) end
        
    elseif cmd == "esptracer" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then Config.ESP.Tracers = true CreateNotification("ESP Tracers: ON", Config.Colors.Hero)
        elseif opt == "off" then Config.ESP.Tracers = false CreateNotification("ESP Tracers: OFF", Config.Colors.Hero)
        else Config.ESP.Tracers = not Config.ESP.Tracers CreateNotification("ESP Tracers: " .. (Config.ESP.Tracers and "ON" or "OFF"), Config.Colors.Hero) end
        
    elseif cmd == "esphealth" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then Config.ESP.HealthBar = true Config.ESP.HealthText = true CreateNotification("ESP Health: ON", Config.Colors.Hero)
        elseif opt == "off" then Config.ESP.HealthBar = false Config.ESP.HealthText = false CreateNotification("ESP Health: OFF", Config.Colors.Hero)
        else 
            Config.ESP.HealthBar = not Config.ESP.HealthBar
            Config.ESP.HealthText = Config.ESP.HealthBar
            CreateNotification("ESP Health: " .. (Config.ESP.HealthBar and "ON" or "OFF"), Config.Colors.Hero)
        end
        
    elseif cmd == "esphead" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then Config.ESP.HeadDot = true CreateNotification("ESP Head Dot: ON", Config.Colors.Hero)
        elseif opt == "off" then Config.ESP.HeadDot = false CreateNotification("ESP Head Dot: OFF", Config.Colors.Hero)
        else Config.ESP.HeadDot = not Config.ESP.HeadDot CreateNotification("ESP Head Dot: " .. (Config.ESP.HeadDot and "ON" or "OFF"), Config.Colors.Hero) end
        
    elseif cmd == "spin" then
        local speed = tonumber(args[2])
        if speed == 0 or string.lower(args[2] or "") == "off" then flags.spin = 0 CreateNotification("Spin: OFF", Config.Colors.Hero)
        else flags.spin = speed or 20 CreateNotification("Spin: ON (" .. flags.spin .. ")", Config.Colors.Hero) end
        
    elseif cmd == "freecam" then
        flags.freecam = not flags.freecam
        if flags.freecam then
            Camera.CameraType = Enum.CameraType.Scriptable
            CreateNotification("FreeCam: ON", Config.Colors.Hero)
        else
            Camera.CameraType = Enum.CameraType.Custom
            local char = LocalPlayer.Character
            if char then Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid") end
            CreateNotification("FreeCam: OFF", Config.Colors.Hero)
        end
        
    elseif cmd == "fling" then
        local targetName = args[2]
        if targetName then
            local targetPlayer = GetPlayerByPartialName(targetName)
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and root then
                CreateNotification("Flinging " .. targetPlayer.DisplayName .. "...", Config.Colors.Murderer)
                local oldNoclip = flags.noclip
                flags.noclip = true
                local spinForce = Instance.new("BodyAngularVelocity")
                spinForce.AngularVelocity = Vector3new(0, 99999, 0)
                spinForce.MaxTorque = Vector3new(0, math.huge, 0)
                spinForce.Parent = root
                task.spawn(function()
                    local t = 0
                    while t < 1.2 do
                        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                        end
                        t = t + RunService.Heartbeat:Wait()
                    end
                    spinForce:Destroy()
                    flags.noclip = oldNoclip
                end)
            else CreateNotification("Player not found!", Config.Colors.Murderer) end
        end
        
    elseif cmd == "emote" then
        local arg = args[2]
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if arg == "stop" or arg == "off" then
            if currentEmoteTrack then currentEmoteTrack:Stop() currentEmoteTrack = nil end
        elseif arg and tonumber(arg) and hum then
            local animator = hum:FindFirstChildOfClass("Animator") or hum
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. arg
            if currentEmoteTrack then currentEmoteTrack:Stop() end
            pcall(function() currentEmoteTrack = animator:LoadAnimation(anim) currentEmoteTrack:Play() end)
        end
        
    elseif cmd == "esp" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then flags.esp = true elseif opt == "off" then flags.esp = false else flags.esp = not flags.esp end
        if not flags.esp then
            for _, data in pairs(playerData) do
                for _, drawing in pairs(data) do
                    if typeof(drawing) == "table" and drawing.Visible ~= nil then
                        drawing.Visible = false
                    end
                end
            end
        end
        CreateNotification("ESP: " .. (flags.esp and "ON" or "OFF"), Config.Colors.Hero)
        
    elseif cmd == "sprint" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then flags.sprint = true elseif opt == "off" then flags.sprint = false else flags.sprint = not flags.sprint end
        CreateNotification("Sprint: " .. (flags.sprint and "ON" or "OFF"), Config.Colors.Hero)
        
    elseif cmd == "fly" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then toggleFly(true) elseif opt == "off" then toggleFly(false) else toggleFly(not flags.fly) end
        CreateNotification("Fly Mode: " .. (flags.fly and "ON" or "OFF"), Config.Colors.Hero)
        
    elseif cmd == "noclip" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then flags.noclip = true elseif opt == "off" then flags.noclip = false else flags.noclip = not flags.noclip end
        CreateNotification("Noclip: " .. (flags.noclip and "ON" or "OFF"), Config.Colors.Hero)
        
    elseif cmd == "tpgun" then tpToGun()
        
    elseif cmd == "bind" then
        local keyName = args[2]
        local targetCmd = table.concat(args, " ", 3)
        if keyName and #targetCmd > 0 then
            local targetKeyCode = FindKeyCode(keyName)
            if targetKeyCode then customBinds[targetKeyCode] = targetCmd CreateNotification("Bound [" .. targetKeyCode.Name .. "]", Config.Colors.Innocent) end
        end
        
    elseif cmd == "aimbot" then
        local opt = string.lower(args[2] or "")
        if opt == "on" then Config.Aimbot.Enabled = true elseif opt == "off" then Config.Aimbot.Enabled = false else Config.Aimbot.Enabled = not Config.Aimbot.Enabled end
        CreateNotification("Aimbot: " .. (Config.Aimbot.Enabled and "ON" or "OFF"), Config.Colors.Hero)
        
    elseif cmd == "speed" then
        local val = tonumber(args[2])
        if val then Config.SprintSpeed = val end
        
    elseif cmd == "prediction" then
        Config.Aimbot.Prediction = not Config.Aimbot.Prediction
        CreateNotification("Prediction: " .. (Config.Aimbot.Prediction and "ON" or "OFF"), Config.Colors.Hero)
        
    elseif cmd == "smoothness" then
        local val = tonumber(args[2])
        if val then
            Config.Aimbot.Smoothness = mathclamp(val, 0.01, 1)
            CreateNotification("Smoothness: " .. Config.Aimbot.Smoothness, Config.Colors.Hero)
        end
        
    elseif cmd == "scb" or cmd == "scoreboard" then
        flags.hudVisible = not flags.hudVisible
        HUD.Visible = flags.hudVisible

    elseif cmd == "clear" then
        for _, notif in pairs(activeNotifications) do notif.Visible = false pcall(function() notif:Remove() end) end
        table.clear(activeNotifications)
    end
end

-- ==========================================
-- CONSOLE CORE TEXT EVENT HOOKS
-- ==========================================
local currentSuggestion = ""

TextBox:GetPropertyChangedSignal("Text"):Connect(function()
    local text = TextBox.Text
    currentSuggestion = GetSuggestion(text)
    if currentSuggestion ~= "" and string.lower(currentSuggestion) ~= string.lower(text) then
        SuggestionLabel.Text = " Suggestion: " .. currentSuggestion .. " [RAlt]"
        SuggestionLabel.Visible = true
    else
        SuggestionLabel.Visible = false
    end
end)

TextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local text = TextBox.Text
        if #text > 0 then ExecuteCommand(text) end
        TextBox.Text = ""
        MainFrame.Visible = false
    else
        MainFrame.Visible = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if UserInputService:GetFocusedTextBox() then
        if input.KeyCode == Enum.KeyCode.RightAlt and currentSuggestion ~= "" then
            TextBox.Text = currentSuggestion
            TextBox.CursorPosition = #TextBox.Text + 1
        end
        return 
    end

    if not gpe and customBinds[input.KeyCode] then ExecuteCommand(customBinds[input.KeyCode]) end
    
    if not gpe and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = UserInputService:GetMouseLocation()
        if flags.hudVisible and mousePos.X >= HUD.Position.X - 10 and mousePos.X <= HUD.Position.X + 220 and
           mousePos.Y >= HUD.Position.Y - 10 and mousePos.Y <= HUD.Position.Y + 160 then
            draggingHUD = true
            hudDragStart = mousePos
            hudStartPos = HUD.Position
        end
    end

    if input.KeyCode == Config.Binds.ConsoleToggle or input.KeyCode == Enum.KeyCode.Tilde or input.KeyCode == Enum.KeyCode.Backquote then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            task.defer(function()
                TextBox:CaptureFocus()
                TextBox.Text = "/"
                TextBox.CursorPosition = 2
            end)
        else
            TextBox:ReleaseFocus()
        end
    end

    if gpe then return end
    if input.KeyCode == Config.Binds.SizeUp then HUD.Size = math.min(35, HUD.Size + 1) 
    elseif input.KeyCode == Config.Binds.SizeDown then HUD.Size = math.max(10, HUD.Size - 1) 
    elseif input.KeyCode == Config.Binds.ESP then ExecuteCommand("esp")
    elseif input.KeyCode == Config.Binds.Sprint then ExecuteCommand("sprint") end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHUD = false end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingHUD and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = UserInputService:GetMouseLocation()
        HUD.Position = hudStartPos + (mousePos - hudDragStart)
    end
end)

-- Physics Triggers
local function UpdateLobbyPosition()
    local lobby = workspace:FindFirstChild("Lobby")
    if lobby then
        local spawnPart = lobby:FindFirstChildOfClass("SpawnLocation", true) or lobby:FindFirstChild("Spawn", true)
        if spawnPart then lobbyPosition = spawnPart.Position return end
        lobbyPosition = lobby:GetPivot().Position
        return
    end
    lobbyPosition = Vector3new(-108, 13, 16)
end
UpdateLobbyPosition()

local function IsInLobby(position)
    if lobbyPosition and position then return (position - lobbyPosition).Magnitude < 220 end
    return false
end

-- Physics Frame Runner
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if hum and hum.Health > 0 and root then
        if flags.spin > 0 then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(flags.spin), 0) end
        
        if flags.fly and flyBV and flyBG then
            flyBG.CFrame = Camera.CFrame
            local moveDir = Vector3new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3new(0, 1, 0) end
            
            if moveDir.Magnitude > 0 then flyBV.Velocity = moveDir.Unit * Config.FlySpeed else flyBV.Velocity = Vector3new(0, 0, 0) end
        else
            hum.WalkSpeed = flags.sprint and Config.SprintSpeed or 16
        end
    end
end)

-- FreeCam Camera Update Loop
RunService.RenderStepped:Connect(function()
    -- Обновление FOV круга
    FOVCircle.Position = Vector2new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Visible = Config.Aimbot.Enabled and Config.Aimbot.ShowFOV
    
    if flags.freecam then
        local camSpeed = 1.5
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then camSpeed = 3 end
        local moveDir = Vector3new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3new(0, 1, 0) end
        
        if moveDir.Magnitude > 0 then Camera.CFrame = Camera.CFrame + (moveDir.Unit * camSpeed) end
    end

    -- PRO AIMBOT (FOV + RAYCAST + SMART TARGET)
    if Config.Aimbot.Enabled and (not Config.Aimbot.HoldToAim or UserInputService:IsMouseButtonPressed(Config.Aimbot.AimKey) or UserInputService:IsKeyDown(Config.Aimbot.AimKeyMobile)) then
        local targetChar = GetAimbotTarget()
        if targetChar then
            local targetPart = targetChar[Config.Aimbot.TargetPart]
            local targetPos = targetPart.Position
            
            if Config.Aimbot.Prediction then
                targetPos = targetPos + (targetChar.HumanoidRootPart.AssemblyLinearVelocity * Config.Aimbot.PredictionFactor)
            end
            
            if Config.Aimbot.Smoothness >= 1 then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            else
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), Config.Aimbot.Smoothness)
            end
        end
    end

    -- ENHANCED ESP
    if flags.esp then
        for player, data in pairs(playerData) do
            if player ~= LocalPlayer then
                UpdateESP(data)
            end
        end
    else
        for _, data in pairs(playerData) do
            for _, drawing in pairs(data) do
                if typeof(drawing) == "table" and drawing.Visible ~= nil then
                    drawing.Visible = false
                end
            end
        end
    end

    -- Обновление HUD
    if flags.hudVisible then
        fpsFrameCount = fpsFrameCount + 1
        local now = osclock()
        
        if now - fpsLastUpdate >= 0.5 then
            currentFps = mathfloor(fpsFrameCount / (now - fpsLastUpdate))
            local ping = mathfloor(LocalPlayer:GetNetworkPing() * 1000)
            if ping <= 0 then ping = mathfloor(Stats.Network.ServerIn:GetRealwayPing()) end
            
            local dangerText = ""
            if currentMurderer and currentMurderer.Character and currentMurderer.Character:FindFirstChild("HumanoidRootPart") then
                local murdererRoot = currentMurderer.Character.HumanoidRootPart
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot and not IsInLobby(myRoot.Position) then
                    local dist = mathfloor((myRoot.Position - murdererRoot.Position).Magnitude)
                    if dist < 45 then dangerText = string.format("\n⚠️ WARNING: MURDERER NEARBY! [%dm]", dist) end
                end
            end
            
            local aimInfo = Config.Aimbot.Enabled and "ON" or "OFF"
            if Config.Aimbot.Enabled then
                if Config.Aimbot.Prediction then aimInfo = aimInfo .. " + PRED" end
                if Config.Aimbot.VisibleCheck then aimInfo = aimInfo .. " + VIS" end
            end
            
            HUD.Text = string.format(
                "%s\n" ..
                "FPS: %d | Ping: %dms | Time: %s\n" ..
                "HUD Size: %d (N + / M -)\n\n" ..
                "[F5] Enhanced ESP: %s\n" ..
                "[F6] Legit Sprint: %s\n" ..
                "✈️ Fly: %s | FreeCam: %s | Noclip: %s\n" ..
                "🎯 Pro Aim: %s | FOV: %d\n" ..
                "⌨️ Console: [ %s ] Key\n\n" ..
                "🩸 Murderer: %s\n" ..
                "👮 Sheriff: %s" ..
                "%s",
                Config.Title, currentFps, ping, os.date("%H:%M"), HUD.Size,
                flags.esp and "ON" or "OFF", flags.sprint and "ON" or "OFF",
                flags.fly and "ON" or "OFF", flags.freecam and "ON" or "OFF", flags.noclip and "ON" or "OFF",
                aimInfo, Config.Aimbot.FOV, Config.Binds.ConsoleToggle.Name, mNameStr, sNameStr, dangerText
            )
            fpsFrameCount, fpsLastUpdate = 0, now
        end
    end
end)

RunService.Stepped:Connect(function()
    if flags.noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- MM2 Round Scanner Loop
task.spawn(function()
    while task.wait(0.2) do
        local foundMurderer, foundSheriff = nil, nil
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") and IsInLobby(myChar.HumanoidRootPart.Position) then
            currentMurderer, currentSheriff = nil, nil
        end

        for _, player in pairs(Players:GetPlayers()) do
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                local hasKnife = char:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") or char:FindFirstChild("KnifeClassic") or player.Backpack:FindFirstChild("KnifeClassic")
                local hasGun = char:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") or char:FindFirstChild("GunClassic") or player.Backpack:FindFirstChild("GunClassic")
                
                if hasKnife then foundMurderer = player
                elseif hasGun then foundSheriff = player end
            end
        end

        if foundMurderer then
            mNameStr = foundMurderer.Name
            if foundMurderer ~= currentMurderer then
                currentMurderer = foundMurderer
                CreateNotification("⚠️ " .. foundMurderer.Name .. " IS THE MURDERER!", Config.Colors.Murderer)
            end
        else mNameStr = "Not Found" currentMurderer = nil end

        if foundSheriff then
            sNameStr = foundSheriff.Name
            if foundSheriff ~= currentSheriff then
                CreateNotification(currentSheriff and ("⭐ " .. foundSheriff.Name .. " got the gun!") or ("👮 " .. foundSheriff.Name .. " IS THE SHERIFF!"), Config.Colors.Sheriff)
                currentSheriff = foundSheriff
            end
        elseif workspace:FindFirstChild("GunDrop") then sNameStr = "Dropped! ⚠️" currentSheriff = nil
        else sNameStr = "Not Found" currentSheriff = nil end
    end
end)

workspace.ChildAdded:Connect(function(child) if child.Name == "Lobby" then task.wait(1) UpdateLobbyPosition() end end)

local function OnPlayerAdded(player)
    if player ~= LocalPlayer and not playerData[player] then
        playerData[player] = CreateESP(player)
    end
end

local function OnPlayerRemoving(player)
    if playerData[player] then
        DestroyESP(playerData[player])
        playerData[player] = nil
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)
for _, player in pairs(Players:GetPlayers()) do OnPlayerAdded(player) end
