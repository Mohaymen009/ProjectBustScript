local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local Config = {
    ActivateKey = Enum.KeyCode.C, -- Activate camlock while holding C
    SpeedBoostKey = Enum.KeyCode.V, -- Toggle speed boost with V
    MaxDistance = 1000,
    Sensitivity = 0.5,
    AimPart = "HumanoidRootPart", -- Part to aim at
    TeamCheck = true, -- Check if target is on the same team
    VisibilityCheck = false, -- Check if target is visible
    SmoothAimEnabled = true, -- Smooth aiming
    FOVEnabled = false, -- Enable FOV circle
    FOVSize = 250, -- Size of FOV circle
    FOVSides = 64, -- Number of sides for FOV circle
    FOVColor = Color3.fromRGB(255, 255, 255), -- Color of FOV circle
    HighlightColor = Color3.fromRGB(0, 255, 0), -- Green highlight
}

local Enabled = false
local TargetPlayer = nil
local FOVCircle = nil
local Highlight = nil
local NameDisplay = nil

-- Speed boost configuration
local SpeedBoostSettings = {
    BASE_SPEED = 16,    -- Normal speed
    BOOST_SPEED = 100,  -- Speed when activated
}

local isSpeedEnabled = false
local currentSpeed = SpeedBoostSettings.BASE_SPEED

-- Variables for speed boost
local humanoidRootPart = nil
local humanoid = nil

-- Function to initialize character variables
local function InitializeCharacter()
    local character = LocalPlayer.Character
    if character then
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoid = character:WaitForChild("Humanoid")
    end
end

-- Initialize character on script start
InitializeCharacter()

-- Reinitialize character on respawn
LocalPlayer.CharacterAdded:Connect(function()
    InitializeCharacter()
end)

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

-- Function to highlight the target player
local function HighlightTarget(player)
    if Highlight then
        Highlight:Destroy()
        Highlight = nil
    end
    if NameDisplay then
        NameDisplay:Destroy()
        NameDisplay = nil
    end

    if player and player.Character then
        -- Create highlight
        Highlight = Instance.new("Highlight")
        Highlight.FillColor = Config.HighlightColor
        Highlight.OutlineColor = Config.HighlightColor
        Highlight.Parent = player.Character

        -- Create name display
        NameDisplay = Instance.new("BillboardGui")
        NameDisplay.Adornee = player.Character:FindFirstChild("Head")
        NameDisplay.Size = UDim2.new(0, 200, 0, 50)
        NameDisplay.StudsOffset = Vector3.new(0, 2, 0)
        NameDisplay.AlwaysOnTop = true

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Text = player.Name
        NameLabel.TextColor3 = Config.HighlightColor
        NameLabel.TextSize = 20
        NameLabel.Font = Enum.Font.SourceSansBold
        NameLabel.BackgroundTransparency = 1
        NameLabel.Size = UDim2.new(1, 0, 1, 0)
        NameLabel.Parent = NameDisplay

        NameDisplay.Parent = player.Character
    end
end

-- Input handling for camlock activation key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Config.ActivateKey then
        Enabled = true
        TargetPlayer = GetClosestPlayerToCursor()
        HighlightTarget(TargetPlayer)
        print("Camlock activated on player: " .. (TargetPlayer and TargetPlayer.Name or "None"))
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Config.ActivateKey then
        Enabled = false
        HighlightTarget(nil) -- Remove highlight and name display
        TargetPlayer = nil
        print("Camlock deactivated")
    end
end)

-- Main update loop for camlock
RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()
    
    if Enabled and TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild(Config.AimPart) then
        local targetPart = TargetPlayer.Character[Config.AimPart]
        local targetPos = targetPart.Position
        
        -- No prediction applied
        local cameraPos = Camera.CFrame.Position
        local newCameraLookVector = (targetPos - cameraPos).Unit
        local currentLookVector = Camera.CFrame.LookVector
        
        if Config.SmoothAimEnabled then
            local smoothLookVector = currentLookVector:Lerp(newCameraLookVector, Config.Sensitivity)
            Camera.CFrame = CFrame.new(cameraPos, cameraPos + smoothLookVector)
        else
            Camera.CFrame = CFrame.new(cameraPos, cameraPos + newCameraLookVector)
        end
    end
end)

-- Speed boost functionality
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Config.SpeedBoostKey then
        isSpeedEnabled = not isSpeedEnabled
        
        if isSpeedEnabled then
            -- Store current state before enabling speed
            humanoid.WalkSpeed = SpeedBoostSettings.BOOST_SPEED
            print("Speed boost enabled")
        else
            -- Restore original state
            humanoid.WalkSpeed = SpeedBoostSettings.BASE_SPEED
            print("Speed boost disabled")
        end
    end
end)

-- Movement loop for speed boost
RunService.RenderStepped:Connect(function(deltaTime)
    if isSpeedEnabled and humanoidRootPart then
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
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + (moveDirection * humanoid.WalkSpeed * deltaTime)
        end
    end
end)

-- Cleanup when script stops
game:BindToClose(function()
    if Highlight then
        Highlight:Destroy()
    end
    if NameDisplay then
        NameDisplay:Destroy()
    end
end)
