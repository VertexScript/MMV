local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
-------------------------------------------------------------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Vortex UI | MMV",
    Icon = "door-open",
    Author = "by Uekiya",
    Folder = "MM2HubScript_U",
})

Window:Tag({
    Title = "V.1.2",
    Icon = "book-marked",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 30,
})
-------------------------------------------------------------------------------------------------------------------
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "cog",
    Locked = false,
})

local Keybind = SettingsTab:Keybind({
    Title = "GUI Keybind",
    Desc = "Keybind to Open / Close GUI",
    Value = "LeftControl",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

Window:SetToggleKey(Enum.KeyCode.LeftControl)
Window:Divider()
-------------------------------------------------------------------------------------------------------------------
local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "hat-glasses",
    Locked = false,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local Toggle = ESPTab:Toggle({
    Title = "Player ESP",
    Desc = "Allows you to see Players through walls",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local PlayerESPObjects = {}
        local CharacterConnections = {}
        local RefreshLoop = nil
        local PlayerAddedConnection = nil
        local PlayerRemovingConnection = nil
        
        local function GetRole(plr)
            if not plr.Character then return "Unknown" end
            local bp = plr:FindFirstChild("Backpack")
            local char = plr.Character
            if (bp and bp:FindFirstChild("Knife")) or char:FindFirstChild("Knife") then return "Murderer" end
            if (bp and bp:FindFirstChild("Gun")) or char:FindFirstChild("Gun") then return "Sheriff" end
            return "Innocent"
        end
        
        local function CreateESP(plr)
            if plr == LocalPlayer or not plr.Character then return end
            
            if PlayerESPObjects[plr] then
                PlayerESPObjects[plr]:Destroy()
                PlayerESPObjects[plr] = nil
            end
            
            local esp = Instance.new("Highlight")
            esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            esp.FillTransparency = 0.65
            esp.OutlineTransparency = 1
            esp.Parent = plr.Character
            
            PlayerESPObjects[plr] = esp
            
            local role = GetRole(plr)
            local colors = {Murderer = Color3.new(1, 0, 0), Sheriff = Color3.new(0, 0.4, 1), Innocent = Color3.new(0, 1, 0), Unknown = Color3.new(1, 1, 1)}
            esp.FillColor = colors[role]
            esp.OutlineColor = colors[role]
        end
        
        local function RemoveESP(plr)
            if PlayerESPObjects[plr] then
                PlayerESPObjects[plr]:Destroy()
                PlayerESPObjects[plr] = nil
            end
            if CharacterConnections[plr] then
                CharacterConnections[plr]:Disconnect()
                CharacterConnections[plr] = nil
            end
        end
        
        local function SetupCharacter(plr)
            if plr == LocalPlayer then return end
            
            if plr.Character then
                CreateESP(plr)
            end
            
            if CharacterConnections[plr] then
                CharacterConnections[plr]:Disconnect()
            end
            
            CharacterConnections[plr] = plr.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                CreateESP(plr)
                
                char.DescendantAdded:Connect(function(desc)
                    if desc:IsA("Accessory") or desc:IsA("Clothing") then
                        task.wait(0.1)
                        CreateESP(plr)
                    end
                end)
            end)
            
            if plr.Character then
                plr.Character.DescendantAdded:Connect(function(desc)
                    if desc:IsA("Accessory") or desc:IsA("Clothing") then
                        task.wait(0.1)
                        CreateESP(plr)
                    end
                end)
            end
        end
        
        if state then
            for _, plr in ipairs(Players:GetPlayers()) do
                SetupCharacter(plr)
            end
            
            PlayerAddedConnection = Players.PlayerAdded:Connect(SetupCharacter)
            
            PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(plr)
                RemoveESP(plr)
            end)
            
            RefreshLoop = task.spawn(function()
                while true do
                    task.wait(5)
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer then
                            CreateESP(plr)
                        end
                    end
                end
            end)
            
        else
            if RefreshLoop then
                task.cancel(RefreshLoop)
            end
            if PlayerAddedConnection then
                PlayerAddedConnection:Disconnect()
            end
            if PlayerRemovingConnection then
                PlayerRemovingConnection:Disconnect()
            end
            for plr, conn in pairs(CharacterConnections) do
                if conn then conn:Disconnect() end
            end
            
            for _, esp in pairs(PlayerESPObjects) do
                if esp then esp:Destroy() end
            end
            
            PlayerESPObjects = {}
            CharacterConnections = {}
        end
    end
})

local GunDropToggle = ESPTab:Toggle({
    Title = "Gun Drop ESP",
    Desc = "Highlights dropped gun (if there is one)",
    Icon = "bow-arrow",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local GunDropColor = Color3.fromRGB(0, 100, 0)
        local GunDrop = nil
        local GunHighlightAndIAmHigh = nil
        local DescendantAddedConnection = nil
        
        local function OnGunDropAdded(obj)
            if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                if GunHighlightAndIAmHigh then
                    GunHighlightAndIAmHigh:Destroy()
                end
                
                GunDrop = obj
                GunHighlightAndIAmHigh = Instance.new("Highlight")
                GunHighlightAndIAmHigh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                GunHighlightAndIAmHigh.FillTransparency = 0.5
                GunHighlightAndIAmHigh.OutlineTransparency = 1
                GunHighlightAndIAmHigh.FillColor = GunDropColor
                GunHighlightAndIAmHigh.OutlineColor = GunDropColor
                GunHighlightAndIAmHigh.Parent = obj
                
                obj.Destroying:Connect(function()
                    if GunHighlightAndIAmHigh then
                        GunHighlightAndIAmHigh:Destroy()
                        GunHighlightAndIAmHigh = nil
                        GunDrop = nil
                    end
                end)
            end
        end
        
        if state then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "GunDrop" and obj:IsA("BasePart") then
                    OnGunDropAdded(obj)
                    break
                end
            end
            
            DescendantAddedConnection = Workspace.DescendantAdded:Connect(OnGunDropAdded)
            
            getgenv().GunDropDescendantAddedConnection = DescendantAddedConnection
            
        else
            if getgenv().GunDropDescendantAddedConnection then
                getgenv().GunDropDescendantAddedConnection:Disconnect()
                getgenv().GunDropDescendantAddedConnection = nil
            end
            
            if GunHighlightAndIAmHigh then
                GunHighlightAndIAmHigh:Destroy()
                GunHighlightAndIAmHigh = nil
            end
            GunDrop = nil
        end
    end
})

local TrapESPToggle = ESPTab:Toggle({
    Title = "Allows you to see traps",
    Desc = "Self-Explanatory",
    Icon = "shield-check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local OriginalTransparencies = {}
        local DescendantAddedConnection = nil
        local DescendantRemovingConnection = nil
        
        local function onTrapAdded(trap)
            if trap.Name ~= "TrapVisual" or not trap:IsA("BasePart") then return end
            
            OriginalTransparencies[trap] = trap.Transparency
            trap.Transparency = 0
        end
        
        local function onTrapRemoving(trap)
            OriginalTransparencies[trap] = nil
        end
        
        if state then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "TrapVisual" and obj:IsA("BasePart") then
                    onTrapAdded(obj)
                end
            end
            
            DescendantAddedConnection = Workspace.DescendantAdded:Connect(onTrapAdded)
            DescendantRemovingConnection = Workspace.DescendantRemoving:Connect(onTrapRemoving)
            
            TrapESPToggle.DescendantAddedConnection = DescendantAddedConnection
            TrapESPToggle.DescendantRemovingConnection = DescendantRemovingConnection
            TrapESPToggle.OriginalTransparencies = OriginalTransparencies
        else
            if TrapESPToggle.DescendantAddedConnection then
                TrapESPToggle.DescendantAddedConnection:Disconnect()
            end
            if TrapESPToggle.DescendantRemovingConnection then
                TrapESPToggle.DescendantRemovingConnection:Disconnect()
            end
            
            if TrapESPToggle.OriginalTransparencies then
                for trap, transparency in pairs(TrapESPToggle.OriginalTransparencies) do
                    if trap and trap.Parent then
                        trap.Transparency = transparency
                    end
                end
            end
            
            TrapESPToggle.DescendantAddedConnection = nil
            TrapESPToggle.DescendantRemovingConnection = nil
            TrapESPToggle.OriginalTransparencies = {}
        end
    end
})

local NameESPToggle = ESPTab:Toggle({
    Title = "Player Names ESP",
    Desc = "Shows username and display name above players",
    Icon = "app-window",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local NameESPObjects = {}
        local Connection = nil
        
        if state then
            Connection = RunService.RenderStepped:Connect(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local head = plr.Character:FindFirstChild("Head")
                        if head then
                            local esp = NameESPObjects[plr]
                            if not esp then
                                esp = Instance.new("BillboardGui")
                                esp.Size = UDim2.new(0, 200, 0, 40)
                                esp.AlwaysOnTop = true
                                esp.StudsOffset = Vector3.new(0, 2.5, 0)
                                
                                local label = Instance.new("TextLabel")
                                label.Size = UDim2.new(1, 0, 1, 0)
                                label.BackgroundTransparency = 1
                                label.TextStrokeTransparency = 0
                                label.TextSize = 14
                                label.Font = Enum.Font.GothamBold
                                label.TextColor3 = Color3.new(1, 1, 1)
                                label.Parent = esp
                                
                                NameESPObjects[plr] = esp
                            end
                            
                            local displayName = plr.DisplayName ~= plr.Name and " (" .. plr.DisplayName .. ")" or ""
                            esp.TextLabel.Text = plr.Name .. displayName
                            esp.Parent = head
                        end
                    end
                end
            end)
            
            getgenv().NameESPConnection = Connection
            getgenv().NameESPObjects = NameESPObjects
            
        else
            if getgenv().NameESPConnection then
                getgenv().NameESPConnection:Disconnect()
                getgenv().NameESPConnection = nil
            end
            if getgenv().NameESPObjects then
                for _, esp in pairs(getgenv().NameESPObjects) do
                    if esp then esp:Destroy() end
                end
                getgenv().NameESPObjects = {}
            end
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local MiscTab = Window:Tab({
    Title = "Miscellaneous",
    Icon = "server",
    Locked = false,
})

local CoinKeybind = MiscTab:Keybind({
    Title = "Coin Collect",
    Desc = "Teleports coins to you to instantly fill your coin bag",
    Value = "C",
    Callback = function(v)
        local character = LocalPlayer.Character
        if not character then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
                obj.CFrame = hrp.CFrame
            end
        end
    end
})

MiscTab:Divider()

local TeleportLobby = MiscTab:Button({
    Title = "Teleport to Lobby",
    Desc = "Teleports you to the Lobby",
    Locked = false,
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        
        local spawnsModel = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Spawns" and obj:IsA("Model") then
                spawnsModel = obj
                break
            end
        end
        
        if not spawnsModel then
            return
        end
        
        local spawnPoints = {}
        for _, obj in ipairs(spawnsModel:GetDescendants()) do
            if obj.Name == "Spawn" and obj:IsA("BasePart") then
                table.insert(spawnPoints, obj)
            end
        end
        
        if #spawnPoints > 0 then
            local randomSpawn = spawnPoints[math.random(1, #spawnPoints)]
            hrp.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
        else
        end
    end
})

local TeleportMap = MiscTab:Button({
    Title = "Teleport to Map",
    Desc = "Teleports you to the map",
    Locked = false,
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        
        local spawnsModel = nil
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Spawns" and obj:IsA("Model") then
                local hasSpawnLocation = false
                
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("SpawnLocation") then
                        hasSpawnLocation = true
                        break
                    end
                end
                
                if not hasSpawnLocation then
                    spawnsModel = obj
                    break
                end
            end
        end
        
        if not spawnsModel then
            return
        end
        
        local spawnPoints = {}
        for _, obj in ipairs(spawnsModel:GetDescendants()) do
            if obj.Name == "Spawn" and obj:IsA("BasePart") then
                table.insert(spawnPoints, obj)
            end
        end
        
        if #spawnPoints > 0 then
            local randomSpawn = spawnPoints[math.random(1, #spawnPoints)]
            hrp.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
        else
        end
    end
})

MiscTab:Divider()

local BarrierRemoverButton = MiscTab:Button({
    Title = "Remove Barriers",
    Desc = "Removes any invisible walls / barriers",
    Locked = false,
    Callback = function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "GlitchProof" then
                obj:Destroy()
            end
            
            if obj:IsA("BasePart") and obj.Transparency == 1 and not obj:IsA("TrussPart") then
                local hasVisibleDecal = false
                
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        if child.Texture ~= "" then
                            hasVisibleDecal = true
                            break
                        end
                    end
                end
                
                if not hasVisibleDecal then
                    obj.CanCollide = false
                end
            end
        end
    end
})

local RemoveBarrierAutomaticToggle = MiscTab:Toggle({
    Title = "Automatic Remove Barriers",
    Desc = "Removes barriers / invisible walls automatically",
    Icon = "brick-wall-shield",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local DescendantAddedConnection = nil
        
        local function ProcessObject(obj)
            if obj.Name == "GlitchProof" then
                obj:Destroy()
                return
            end
            
            if obj:IsA("BasePart") and obj.Transparency == 1 and not obj:IsA("TrussPart") then
                local hasVisibleDecal = false
                
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        if child.Texture ~= "" then
                            hasVisibleDecal = true
                            break
                        end
                    end
                end
                
                if not hasVisibleDecal then
                    obj.CanCollide = false
                end
            end
        end
        
        if state then
            for _, obj in pairs(Workspace:GetDescendants()) do
                ProcessObject(obj)
            end

            DescendantAddedConnection = Workspace.DescendantAdded:Connect(ProcessObject)
            
            RemoveBarrierAutomaticToggle.Connection = DescendantAddedConnection
        else
            if RemoveBarrierAutomaticToggle.Connection then
                RemoveBarrierAutomaticToggle.Connection:Disconnect()
                RemoveBarrierAutomaticToggle.Connection = nil
            end
        end
    end
})

MiscTab:Divider()

local TryhardToolsEnabled = false

local function giveTools()
    local ReplicateToy = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("ReplicateToy")
    ReplicateToy:InvokeServer("GGSign")
    ReplicateToy:InvokeServer("GoldBomb")
end

local TryhardToolsToggle = MiscTab:Toggle({
    Title = "Get GG Sign + Golden Bomb (every respawn)",
    Desc = "You must own Golden Bomb for this to work",
    Icon = "wrench",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        TryhardToolsEnabled = state
        if state then
            giveTools()
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    if TryhardToolsEnabled then
        task.wait(1)
        giveTools()
    end
end)
-------------------------------------------------------------------------------------------------------------------
local InnocentTab = Window:Tab({
    Title = "Innocent",
    Icon = "smile-plus",
    Locked = false,
})

local GrabGunKeybind = InnocentTab:Keybind({
    Title = "Grab Gun",
    Desc = "Instantly grabs the gun and gives it to you",
    Value = "G",
    Callback = function()
        for _, item in pairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("knife") then
                return
            end
        end
        
        local gunDrop = Workspace:FindFirstChild("GunDrop", true)
        if not gunDrop then
            return
        end
        
        for _, part in pairs(gunDrop:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            elseif part.Name:lower():find("fire") or part.Name:lower():find("flame") then
                part:Destroy()
            end
        end
        
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            gunDrop:PivotTo(humanoidRootPart.CFrame)
        end
    end
})

local GrabGunToggle = InnocentTab:Toggle({
    Title = "Auto Grab Gun",
    Desc = "Automatically grabs the gun when it drops",
    Icon = "circle-star",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            getgenv().AutoGrabGunConnection = Workspace.DescendantAdded:Connect(function(obj)
                if obj.Name == "GunDrop" then
                    for _, item in pairs(LocalPlayer.Character:GetChildren()) do
                        if item:IsA("Tool") and item.Name:lower():find("knife") then
                            return
                        end
                    end
                    
                    task.wait(0.1)
                    
                    for _, part in pairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        elseif part.Name:lower():find("fire") or part.Name:lower():find("flame") then
                            part:Destroy()
                        end
                    end
                    
                    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        obj:PivotTo(humanoidRootPart.CFrame)
                    end
                end
            end)
            
            local existingGun = Workspace:FindFirstChild("GunDrop", true)
            if existingGun then
                getgenv().AutoGrabGunConnection:Fire(existingGun)
            end
        else
            if getgenv().AutoGrabGunConnection then
                getgenv().AutoGrabGunConnection:Disconnect()
                getgenv().AutoGrabGunConnection = nil
            end
        end
    end
})

InnocentTab:Divider()

local InvisibleKeybind = InnocentTab:Keybind({
    Title = "Turn Invisible",
    Desc = "Turns you Invisible (can't shoot as sheriff and can't kill as murderer)",
    Value = "Y",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if getgenv().InvisOn then
            getgenv().InvisOn = false
            
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Transparency = 0
                end
            end
            
            if workspace:FindFirstChild("invischair") then
                workspace.invischair:Destroy()
            end
            
        else
            getgenv().InvisOn = true
            
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.Transparency = 0.5
                end
            end
            
            local savedpos = hrp.CFrame
            
            char:MoveTo(Vector3.new(-25.95, 84, 3537.55))
            task.wait(0.15)
            
            local Seat = Instance.new("Seat", workspace)
            Seat.Anchored = false
            Seat.CanCollide = false
            Seat.Name = "invischair"
            Seat.Transparency = 1
            Seat.Position = Vector3.new(-25.95, 84, 3537.55)
            
            local Weld = Instance.new("Weld", Seat)
            Weld.Part0 = Seat
            Weld.Part1 = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            
            Seat.CFrame = savedpos
        end
    end
})

InnocentTab:Divider()

local SpeedGlitchToggle = InnocentTab:Toggle({
    Title = "Speed Glitch Toggle",
    Desc = "Toggles speed glitching",
    Icon = "sport-shoe",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        local function setupSpeedGlitch(char)
            if not char then return end
            
            local humanoid = char:WaitForChild("Humanoid")
            local originalSpeed = humanoid.WalkSpeed
            local currentTween = nil
            
            getgenv().OriginalWalkSpeed = originalSpeed
            
            if getgenv().SpeedGlitchConnection then
                getgenv().SpeedGlitchConnection:Disconnect()
            end
            
            getgenv().SpeedGlitchConnection = humanoid.StateChanged:Connect(function(oldState, newState)
                local hasTool = false
                for _, item in pairs(char:GetChildren()) do
                    if item:IsA("Tool") then
                        hasTool = true
                        break
                    end
                end
                
                if not hasTool then
                    humanoid.WalkSpeed = originalSpeed
                    if currentTween then
                        currentTween:Cancel()
                        currentTween = nil
                    end
                    return
                end
                
                if humanoid:GetState() == Enum.HumanoidStateType.Climbing then return end
                
                if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                    local baseSpeed = (getgenv().SpeedGlitchSpeed or 0) + originalSpeed
                    
                    local moveDir = humanoid.MoveDirection
                    local isJumpingStraight = moveDir.Magnitude < 0.1
                    local targetSpeed = isJumpingStraight and (baseSpeed * 0.3) or baseSpeed
                    
                    if currentTween then
                        currentTween:Cancel()
                    end
                    
                    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tweenGoal = {WalkSpeed = targetSpeed}
                    currentTween = game:GetService("TweenService"):Create(humanoid, tweenInfo, tweenGoal)
                    currentTween:Play()
                end
                
                if newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.Landed then
                    humanoid.WalkSpeed = originalSpeed
                    if currentTween then
                        currentTween:Cancel()
                        currentTween = nil
                    end
                end
            end)
        end
        
        if state then
            if LocalPlayer.Character then
                setupSpeedGlitch(LocalPlayer.Character)
            end
            
            getgenv().SpeedGlitchCharConnection = LocalPlayer.CharacterAdded:Connect(setupSpeedGlitch)
        else
            if getgenv().SpeedGlitchConnection then
                getgenv().SpeedGlitchConnection:Disconnect()
                getgenv().SpeedGlitchConnection = nil
            end
            if getgenv().SpeedGlitchCharConnection then
                getgenv().SpeedGlitchCharConnection:Disconnect()
                getgenv().SpeedGlitchCharConnection = nil
            end
            
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid and getgenv().OriginalWalkSpeed then
                    humanoid.WalkSpeed = getgenv().OriginalWalkSpeed
                end
            end
        end
    end
})

local SpeedGlitchSlider = InnocentTab:Slider({
    Title = "Speed Glitch - Speed",
    Desc = "For some reason you have to adjust the speed before it starts working 😭",
    Step = 1,
    Value = {
        Min = 10,
        Max = 100,
        Default = 50,
    },
    Callback = function(value)
        getgenv().SpeedGlitchSpeed = value
    end
})
-------------------------------------------------------------------------------------------------------------------
local SheriffTab = Window:Tab({
    Title = "Sheriff",
    Icon = "crosshair",
    Locked = false,
})

local SilentAimKeybind = SheriffTab:Keybind({
Title = "Silent Aim",
Desc = "Shoots the Murderer",
Value = "E",
Callback = function(Value)
local char = LocalPlayer.Character

if not char or not char:FindFirstChild("Gun") then return end
   
   local myHRP = char:FindFirstChild("HumanoidRootPart")
   if not myHRP then return end
   
   local targetPlayer = nil
   local targetHRP = nil
   
   for _, player in ipairs(Players:GetPlayers()) do
       if player ~= LocalPlayer and player.Character then
           local hasKnife = player.Character:FindFirstChild("Knife") or 
                           (player.Backpack and player.Backpack:FindFirstChild("Knife"))
           
           if hasKnife then
               local hrp = player.Character:FindFirstChild("HumanoidRootPart")
               if hrp then
                   targetPlayer = player
                   targetHRP = hrp
                   break
               end
           end
       end
   end
   
   if not targetPlayer then return end
   
   local rayParams = RaycastParams.new()
   rayParams.FilterType = Enum.RaycastFilterType.Exclude
   rayParams.FilterDescendantsInstances = {char}
   
   local result = workspace:Raycast(myHRP.Position, (targetHRP.Position - myHRP.Position).Unit * 1000, rayParams)
   
   if not result or not result.Instance:IsDescendantOf(targetPlayer.Character) then return end
   
   local gun = char:FindFirstChild("Gun")
   if gun then
       local shootRemote = gun:FindFirstChild("Shoot")
       if shootRemote then
           local args = {
               CFrame.new(myHRP.Position, targetHRP.Position),
               CFrame.new(targetHRP.Position)
           }
           shootRemote:FireServer(unpack(args))
       end
   end
end,
})

local TriggerbotToggle = SheriffTab:Toggle({
    Title = "Triggerbot",
    Desc = "Shoots for you whenever your crosshair is on the murderer",
    Icon = "plus",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        if state then
            getgenv().TriggerbotActive = true
            task.spawn(function()
                while getgenv().TriggerbotActive do
                    local char = LocalPlayer.Character
                    if not char or not char:FindFirstChild("Gun") then task.wait() continue end
                    
                    local myHRP = char:FindFirstChild("HumanoidRootPart")
                    if not myHRP then task.wait() continue end
                    
                    local mouse = LocalPlayer:GetMouse()
                    local target = mouse.Target
                    if not target then task.wait() continue end
                    
                    local targetModel = target:FindFirstAncestorOfClass("Model")
                    if not targetModel then task.wait() continue end
                    
                    local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
                    if not targetPlayer or targetPlayer == LocalPlayer then task.wait() continue end
                    
                    local hasKnife = targetModel:FindFirstChild("Knife") or 
                                    (targetPlayer.Backpack and targetPlayer.Backpack:FindFirstChild("Knife"))
                    if not hasKnife then task.wait() continue end
                    
                    local targetHRP = targetModel:FindFirstChild("HumanoidRootPart")
                    if not targetHRP then task.wait() continue end
                    
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances = {char}
                    
                    local direction = (targetHRP.Position - myHRP.Position).Unit * 1000
                    local result = workspace:Raycast(myHRP.Position, direction, rayParams)
                    
                    if not result or not result.Instance:IsDescendantOf(targetModel) then task.wait() continue end
                    
                    local gun = char:FindFirstChild("Gun")
                    if not gun then task.wait() continue end
                    
                    local shootRemote = gun:FindFirstChild("Shoot")
                    if not shootRemote then task.wait() continue end
                    
                    local args = {
                        CFrame.new(myHRP.Position, targetHRP.Position),
                        CFrame.new(targetHRP.Position)
                    }
                    shootRemote:FireServer(unpack(args))
                    
                    task.wait(0.01)
                end
            end)
        else
            getgenv().TriggerbotActive = false
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local MurdererTab = Window:Tab({
    Title = "Murderer",
    Icon = "target",
    Locked = false,
})
-------------------------------------------------------------------------------------------------------------------
