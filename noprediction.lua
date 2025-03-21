local a=game:GetService"UserInputService"
local b=game:GetService"Players"
local c=game:GetService"RunService"
game:GetService"ReplicatedStorage"

local d=b.LocalPlayer
local e=workspace.CurrentCamera


local f={
ActivateKey=Enum.KeyCode.C,
SpeedBoostKey=Enum.KeyCode.V,
MaxDistance=1000,
Sensitivity=0.5,
AimPart="HumanoidRootPart",
TeamCheck=true,
VisibilityCheck=false,
SmoothAimEnabled=true,
FOVEnabled=false,
FOVSize=250,
FOVSides=64,
FOVColor=Color3.fromRGB(255,255,255),
HighlightColor=Color3.fromRGB(0,255,0),
}

local g=false
local h
local i
local j
local k


local l={
BASE_SPEED=16,
BOOST_SPEED=100,
}

local m=false local n=
l.BASE_SPEED


local o
local p


local function InitializeCharacter()
local q=d.Character
if q then
o=q:WaitForChild"HumanoidRootPart"
p=q:WaitForChild"Humanoid"
end
end


InitializeCharacter()


d.CharacterAdded:Connect(function()
InitializeCharacter()
end)


local function IsTeamMate(q)
return f.TeamCheck and q.Team and q.Team==d.Team
end


local function IsVisible(q)
if not f.VisibilityCheck then return true end
local r=e.CFrame.Position
local s=(q.Position-r).Unit
local t=RaycastParams.new()
t.FilterType=Enum.RaycastFilterType.Blacklist
t.FilterDescendantsInstances={d.Character}
local u=workspace:Raycast(r,s*f.MaxDistance,t)
return u and u.Instance:IsDescendantOf(q.Parent)
end


local function GetClosestPlayerToCursor()
local q
local r=f.MaxDistance
local s=a:GetMouseLocation()

for t,u in pairs(b:GetPlayers())do
if u~=d and u.Character and u.Character:FindFirstChild(f.AimPart)then
if not IsTeamMate(u)and IsVisible(u.Character[f.AimPart])then
local v,w=e:WorldToScreenPoint(u.Character[f.AimPart].Position)

if w then
local x=(Vector2.new(s.X,s.Y)-Vector2.new(v.X,v.Y)).Magnitude

if f.FOVEnabled then
if x<=f.FOVSize/2 and x<r then
q=u
r=x
end
else
if x<r then
q=u
r=x
end
end
end
end
end
end

return q
end















local function UpdateFOVCircle()
if not i then return end
i.Position=a:GetMouseLocation()
i.Visible=f.FOVEnabled and g
end


local function HighlightTarget(q)
if j then
j:Destroy()
j=nil
end
if k then
k:Destroy()
k=nil
end

if q and q.Character then

j=Instance.new"Highlight"
j.FillColor=f.HighlightColor
j.OutlineColor=f.HighlightColor
j.Parent=q.Character


k=Instance.new"BillboardGui"
k.Adornee=q.Character:FindFirstChild"Head"
k.Size=UDim2.new(0,200,0,50)
k.StudsOffset=Vector3.new(0,2,0)
k.AlwaysOnTop=true

local r=Instance.new"TextLabel"
r.Text=q.Name
r.TextColor3=f.HighlightColor
r.TextSize=20
r.Font=Enum.Font.SourceSansBold
r.BackgroundTransparency=1
r.Size=UDim2.new(1,0,1,0)
r.Parent=k

k.Parent=q.Character
end
end


a.InputBegan:Connect(function(q,r)
if not r and q.KeyCode==f.ActivateKey then
g=true
h=GetClosestPlayerToCursor()
HighlightTarget(h)
print("Camlock activated on player: "..(h and h.Name or"None"))
end
end)

a.InputEnded:Connect(function(q,r)
if not r and q.KeyCode==f.ActivateKey then
g=false
HighlightTarget(nil)
h=nil
print"Camlock deactivated"
end
end)


c.RenderStepped:Connect(function()
UpdateFOVCircle()

if g and h and h.Character and h.Character:FindFirstChild(f.AimPart)then
local q=h.Character[f.AimPart]
local r=q.Position


local s=e.CFrame.Position
local t=(r-s).Unit
local u=e.CFrame.LookVector

if f.SmoothAimEnabled then
local v=u:Lerp(t,f.Sensitivity)
e.CFrame=CFrame.new(s,s+v)
else
e.CFrame=CFrame.new(s,s+t)
end
end
end)


a.InputBegan:Connect(function(q,r)
if not r and q.KeyCode==f.SpeedBoostKey then
m=not m

if m then

p.WalkSpeed=l.BOOST_SPEED
print"Speed boost enabled"
else

p.WalkSpeed=l.BASE_SPEED
print"Speed boost disabled"
end
end
end)


c.RenderStepped:Connect(function(q)
if m and o then
local r=Vector3.new()


if a:IsKeyDown(Enum.KeyCode.W)then
r=r+(workspace.CurrentCamera.CFrame.LookVector*Vector3.new(1,0,1)).Unit
end
if a:IsKeyDown(Enum.KeyCode.S)then
r=r-(workspace.CurrentCamera.CFrame.LookVector*Vector3.new(1,0,1)).Unit
end
if a:IsKeyDown(Enum.KeyCode.A)then
r=r-(workspace.CurrentCamera.CFrame.RightVector*Vector3.new(1,0,1)).Unit
end
if a:IsKeyDown(Enum.KeyCode.D)then
r=r+(workspace.CurrentCamera.CFrame.RightVector*Vector3.new(1,0,1)).Unit
end


if r.Magnitude>0 then
r=r.Unit
o.CFrame=o.CFrame+(r*p.WalkSpeed*q)
end
end
end)


game:BindToClose(function()
if j then
j:Destroy()
end
if k then
k:Destroy()
end
end)
