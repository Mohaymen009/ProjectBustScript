local a = game:GetService("UserInputService")
local b = game:GetService("Players")
local c = game:GetService("RunService")
local d = game:GetService("ReplicatedStorage")
local e = game:GetService("TextService")
local f = game:GetService("TweenService")

local g = b.LocalPlayer
local h = workspace.CurrentCamera

local i = {
    ToggleKey = Enum.KeyCode.C,
    MaxDistance = 1000,
    Sensitivity = 0.5,
    AimPart = "HumanoidRootPart",
    TeamCheck = true,
    VisibilityCheck = false,
    FOVEnabled = false,
    FOVSize = 250,
    FOVSides = 64,
    FOVColor = Color3.fromRGB(255, 255, 255),
    HighlightColor = Color3.fromRGB(0, 255, 0),
}

local j = false
local k = nil
local l = nil
local m = nil
local n = nil

local o = {
    BASE_SPEED = 25,
    BOOST_SPEED = 75,
    TOGGLE_KEY = Enum.KeyCode.V
}

local p = false
local q = o.BASE_SPEED

local function r(s)
    return i.TeamCheck and s.Team and s.Team == g.Team
end

local function t(u)
    if not i.VisibilityCheck then return true end
    local v = h.CFrame.Position
    local w = (u.Position - v).Unit
    local x = RaycastParams.new()
    x.FilterType = Enum.RaycastFilterType.Blacklist
    x.FilterDescendantsInstances = {g.Character}
    local y = workspace:Raycast(v, w * i.MaxDistance, x)
    return y and y.Instance:IsDescendantOf(u.Parent)
end

local function z()
    local A = nil
    local B = i.MaxDistance
    local C = a:GetMouseLocation()

    for _, D in pairs(b:GetPlayers()) do
        if D ~= g and D.Character and D.Character:FindFirstChild(i.AimPart) then
            if not r(D) and t(D.Character[i.AimPart]) then
                local E, F = h:WorldToScreenPoint(D.Character[i.AimPart].Position)
                
                if F then
                    local G = (Vector2.new(C.X, C.Y) - Vector2.new(E.X, E.Y)).Magnitude
                    
                    if i.FOVEnabled then
                        if G <= i.FOVSize / 2 and G < B then
                            A = D
                            B = G
                        end
                    else
                        if G < B then
                            A = D
                            B = G
                        end
                    end
                end
            end
        end
    end

    return A
end

local function H()
    l = Drawing.new("Circle")
    l.Thickness = 2
    l.NumSides = i.FOVSides
    l.Radius = i.FOVSize / 2
    l.Filled = false
    l.Visible = false
    l.ZIndex = 999
    l.Transparency = 1
    l.Color = i.FOVColor
end

local function I()
    if not l then return end
    l.Position = a:GetMouseLocation()
    l.Visible = i.FOVEnabled and j
end

local function J(D)
    if m then
        m:Destroy()
        m = nil
    end

    if D and D.Character then
        m = Instance.new("Highlight")
        m.FillColor = i.HighlightColor
        m.OutlineColor = i.HighlightColor
        m.Parent = D.Character
    end
end

local function K()
    if m then
        m:Destroy()
        m = nil
    end
end

local function L()
    n = Drawing.new("Text")
    n.Text = "Project Bust Script"
    n.Size = 24
    n.Center = true
    n.Outline = true
    n.OutlineColor = Color3.new(0, 0, 0)
    n.Color = Color3.new(1, 1, 1)
    n.Position = Vector2.new(h.ViewportSize.X / 2, 50)
    n.Visible = true
end

local function M()
    if not n then return end
    local N = tick() % 5 / 5
    n.Color = Color3.fromHSV(N, 1, 1)
end

H()
L()

local function O()
    j = not j
    if j then
        k = z()
        if k then
            J(k)
            print("Camlock enabled on player: " .. k.Name)
        else
            print("Camlock enabled, but no target found")
        end
    else
        K()
        k = nil
        print("Camlock disabled")
    end
end

local function P()
    p = not p
    q = p and o.BOOST_SPEED or o.BASE_SPEED
    print("Speed toggled: " .. (p and "ON" or "OFF"))
end

a.InputBegan:Connect(function(Q, R)
    if not R then
        if Q.KeyCode == i.ToggleKey then
            O()
        elseif Q.KeyCode == o.TOGGLE_KEY then
            P()
        end
    end
end)

c.RenderStepped:Connect(function(S)
    I()
    M()
    
    if j and k and k.Character and k.Character:FindFirstChild(i.AimPart) then
        local T = k.Character[i.AimPart]
        local U = T.Position
        
        local V = h.CFrame.Position
        local W = (U - V).Unit
        
        h.CFrame = CFrame.new(V, V + W)
    end

    if p then
        local X = Vector3.new()
        
        if a:IsKeyDown(Enum.KeyCode.W) then
            X = X + (h.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
        end
        if a:IsKeyDown(Enum.KeyCode.S) then
            X = X - (h.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
        end
        if a:IsKeyDown(Enum.KeyCode.A) then
            X = X - (h.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
        end
        if a:IsKeyDown(Enum.KeyCode.D) then
            X = X + (h.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
        end
        
        if X.Magnitude > 0 then
            X = X.Unit
            if g.Character and g.Character:FindFirstChild("HumanoidRootPart") then
                g.Character.HumanoidRootPart.CFrame = g.Character.HumanoidRootPart.CFrame + (X * q * S)
            end
        end
    end
end)

local Y = Instance.new("Folder")
Y.Name = "CamlockConfig"
Y.Parent = d

for Z, _ in pairs(i) do
    local aa = Instance.new(typeof(_) == "boolean" and "BoolValue" or "NumberValue")
    aa.Name = Z
    aa.Value = _
    aa.Parent = Y
end

local function ab(Z, _)
    i[Z] = _
    if Y:FindFirstChild(Z) then
        Y[Z].Value = _
    end
    
    if Z == "FOVSize" then
        l.Radius = _ / 2
    elseif Z == "FOVSides" then
        l.NumSides = _
    elseif Z == "FOVColor" then
        l.Color = _
    end
end
