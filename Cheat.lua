-- Получаем локального игрока правильно (через службу Players)
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- === ЛОГИКА ESP ДЛЯ MM2 ===
local ESP_Enabled = false

local function GetPlayerRole(player)
    if not player or not player:FindFirstChild("Backpack") or not player:FindFirstChild("Character") then
        return "Innocent"
    end
    if player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
        return "Murderer"
    elseif player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local RoleColors = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

local function CreateESP(player)
    if player == LP then return end
    
    local function ApplyHighlight(character)
        if character:FindFirstChild("MM2_ESP") then
            character.MM2_ESP:Destroy()
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "MM2_ESP"
        -- Исправлено: используем корректные свойства Transparency вместо Opacity
        highlight.FillTransparency = 0.5 
        highlight.OutlineTransparency = 0.2
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
        
        coroutine.wrap(function()
            while character and character:Parent() and highlight and highlight.Parent do
                if ESP_Enabled then
                    highlight.Enabled = true
                    local role = GetPlayerRole(player)
                    highlight.FillColor = RoleColors[role]
                    highlight.OutlineColor = RoleColors[role]
                else
                    highlight.Enabled = false
                end
                task.wait(0.5)
            end
        end)()
    end
    
    if player.Character then ApplyHighlight(player.Character) end
    player.CharacterAdded:Connect(ApplyHighlight)
end

for _, player in ipairs(Players:GetPlayers()) do CreateESP(player) end
Players.PlayerAdded:Connect(CreateESP)
-- ==========================

-- Создаем окно интерфейса
local Window = Rayfield:CreateWindow({
   Name = "ESP MM2",
   Icon = 0, 
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Dark_miLlionaire",
   ShowText = "Rayfield", 
   Theme = "Default", 

   ToggleUIKeybind = Enum.KeyCode.G, 

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, 

   ConfigurationSaving = {
      Enabled = true,
      FolderName = "MM2_ESP_Hub", 
      FileName = "BigHubConfig"
   },

   Discord = {
      Enabled = false, 
      Invite = "noinvitelink", 
      RememberJoins = true 
   },

   KeySystem = true, 
   KeySettings = {
      Title = "Система Ключей",
      Subtitle = "Вставьте Ключ",
      Note = "Ключ можно получить в нашем Discord/ТГ (пример)", 
      FileName = "MM2_ESP_Key", 
      SaveKey = true, 
      GrabKeyFromSite = false, 
      Key = {"github", "SUMMER", "1488", "Кишлак", "Cupsize", LP.Name} 
   }
})

-- Создаем вкладку и кнопку управления ESP
local ESPTab = Window:CreateTab("ESP функции", 4483362458)

ESPTab:CreateToggle({
   Name = "Включить ESP (Wallhack)",
   CurrentValue = false,
   Flag = "ESP_Toggle", 
   Callback = function(Value)
      ESP_Enabled = Value
      if Value then
          Rayfield:Notify({
             Title = "ESP Активирован",
             Content = "Красный — Убийца\nСиний — Шериф\nЗеленый — Невинный",
             Duration = 4,
             Image = 4483362458,
          })
      end
   end,
})
