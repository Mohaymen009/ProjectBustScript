local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local Config = {
    ToggleKey = Enum.KeyCode.C,  -- Keybind set to C
    MaxDistance = 1000,
    Sensitivity = 0.5,
    AimPart = "HumanoidRootPart",
    TeamCheck = true,
    VisibilityCheck = false,
    FOVEnabled = false,
    FOVSize = 250,
    FOVSides = 64,
    FOVColor = Color3.fromRGB(255, 255, 255),
    HighlightColor = Color3.fromRGB(0, 255, 0),  -- Highlight color (green)
}

local Enabled = false
local TargetPlayer = nil
local FOVCircle = nil
local HighlightInstance = nil  -- To store the highlight object
local RainbowText = nil  -- To store the rainbow text

-- Speed toggle configuration
local SpeedToggleConfig = {
    BASE_SPEED = 25,    -- Normal speed
    BOOST_SPEED = 75,   -- Speed when activated
    TOGGLE_KEY = Enum.KeyCode.V
}

local isSpeedEnabled = false
local currentSpeed = SpeedToggleConfig.BASE_SPEED

-- Function to check if a player is on the same team
local function IsTeamMate(player)
    return Config.TeamCheck and player.Team and player.Team == LocalPlayer.Team
end

-- Function to check if a player is visible
local function IsVisible(part)
    if not Config.VisibilityCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local raycastResult = workspace:Raycast(origin, direction * Config.MaxDistance, raycastParams)
    return raycastResult and raycastResult.Instance:IsDescendantOf(part.Parent)
end

-- Function to get the closest player to the cursor
local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = Config.MaxDistance
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Config.AimPart) then
            if not IsTeamMate(player) and IsVisible(player.Character[Config.AimPart]) then
                local screenPos, onScreen = Camera:WorldToScreenPoint(player.Character[Config.AimPart].Position)
                
                if onScreen then
                    local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    
                    if Config.FOVEnabled then
                        if distance <= Config.FOVSize / 2 and distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    else
                        if distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Function to create the FOV circle
local function CreateFOVCircle()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = Config.FOVSides
    FOVCircle.Radius = Config.FOVSize / 2
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.ZIndex = 999
    FOVCircle.Transparency = 1
    FOVCircle.Color = Config.FOVColor
end

-- Function to update the FOV circle
local function UpdateFOVCircle()
    if not FOVCircle then return end
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Visible = Config.FOVEnabled and Enabled
end

-- Function to highlight the target
local function HighlightTarget(player)
    if HighlightInstance then
        HighlightInstance:Destroy()  -- Remove existing highlight
        HighlightInstance = nil
    end

    if player and player.Character then
        HighlightInstance = Instance.new("Highlight")
        HighlightInstance.FillColor = Config.HighlightColor
        HighlightInstance.OutlineColor = Config.HighlightColor
        HighlightInstance.Parent = player.Character
    end
end

-- Function to unhighlight the target
local function UnhighlightTarget()
    if HighlightInstance then
        HighlightInstance:Destroy()
        HighlightInstance = nil
    end
end

-- Function to create rainbow text
local function CreateRainbowText()
    RainbowText = Drawing.new("Text")
    RainbowText.Text = "Project Bust Script"
    RainbowText.Size = 24
    RainbowText.Center = true
    RainbowText.Outline = true
    RainbowText.OutlineColor = Color3.new(0, 0, 0)
    RainbowText.Color = Color3.new(1, 1, 1)
    RainbowText.Position = Vector2.new(Camera.ViewportSize.X / 2, 50)
    RainbowText.Visible = true
end

-- Function to update rainbow text color
local function UpdateRainbowText()
    if not RainbowText then return end
    local hue = tick() % 5 / 5
    RainbowText.Color = Color3.fromHSV(hue, 1, 1)
end

-- Create the FOV circle
CreateFOVCircle()

-- Create the rainbow text
CreateRainbowText()

-- Toggle function
local function ToggleCamlock()
    Enabled = not Enabled
    if Enabled then
        TargetPlayer = GetClosestPlayerToCursor()
        if TargetPlayer then
            HighlightTarget(TargetPlayer)  -- Highlight the target
            print("Camlock enabled on player: " .. TargetPlayer.Name)
        else
            print("Camlock enabled, but no target found")
        end
    else
        UnhighlightTarget()  -- Unhighlight the target
        TargetPlayer = nil
        print("Camlock disabled")
    end
end

-- Speed toggle function
local function ToggleSpeed()
    isSpeedEnabled = not isSpeedEnabled
    currentSpeed = isSpeedEnabled and SpeedToggleConfig.BOOST_SPEED or SpeedToggleConfig.BASE_SPEED
    print("Speed toggled: " .. (isSpeedEnabled and "ON" or "OFF"))
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Config.ToggleKey then
            ToggleCamlock()
        elseif input.KeyCode == SpeedToggleConfig.TOGGLE_KEY then
            ToggleSpeed()
        end
    end
end)

-- Main update loop
RunService.RenderStepped:Connect(function(deltaTime)
    UpdateFOVCircle()
    UpdateRainbowText()
    
    if Enabled and TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild(Config.AimPart) then
        local targetPart = TargetPlayer.Character[Config.AimPart]
        local targetPos = targetPart.Position
        
        local cameraPos = Camera.CFrame.Position
        local newCameraLookVector = (targetPos - cameraPos).Unit
        
        -- Directly set the camera to look at the target
        Camera.CFrame = CFrame.new(cameraPos, cameraPos + newCameraLookVector)
    end

    -- Speed toggle movement
    if isSpeedEnabled then
        local moveDirection = Vector3.new()
        
        -- Get input direction
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + (workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - (workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - (workspace.CurrentCamera.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + (workspace.CurrentCamera.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
        end
        
        -- Apply movement
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + (moveDirection * currentSpeed * deltaTime)
            end
        end
    end
end)

-- Expose configuration to ReplicatedStorage for easy adjustment
local ConfigValues = Instance.new("Folder")
ConfigValues.Name = "CamlockConfig"
ConfigValues.Parent = ReplicatedStorage

for key, value in pairs(Config) do
    local valueObject = Instance.new(typeof(value) == "boolean" and "BoolValue" or "NumberValue")
    valueObject.Name = key
    valueObject.Value = value
    valueObject.Parent = ConfigValues
end

-- Function to update configuration
local function UpdateConfig(key, value)
    Config[key] = value
    if ConfigValues:FindFirstChild(key) then
        ConfigValues[key].Value = value
    end
    
    if key == "FOVSize" then
        FOVCircle.Radius = value / 2
    elseif key == "FOVSides" then
        FOVCircle.NumSides = value
    elseif key == "FOVColor" then
        FOVCircle.Color = value
    end
end

-- Example usage:
-- UpdateConfig("Sensitivity", 0.7)
-- UpdateConfig("FOVSize", 300)
