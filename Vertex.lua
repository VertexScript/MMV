local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
-------------------------------------------------------------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Vertex UI | MMV",
    Icon = "door-open",
    Author = "by Uekiya",
    Folder = "MM2HubScript_U",
})

Window:Tag({
    Title = "V.1.7",
    Icon = "book-marked",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 30,
})

local Event = game:GetService("ReplicatedStorage").ChatMessage
firesignal(Event.OnClientEvent, 
    {
        text = "[Private] Vertex Loaded. ™"
    }
)
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
local FadeEvent = Remotes:WaitForChild("Fade")
local DataChangedEvent = Remotes:WaitForChild("PlayerDataChanged")
local RoundEndEvent = Remotes:WaitForChild("RoundEndFade")
local RoundStartEvent = Remotes:WaitForChild("TeleportToPart")

local function GetToolType(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if backpack then
        if backpack:FindFirstChild("Gun") then return "Gun" end
        if backpack:FindFirstChild("Knife") then return "Knife" end
    end
    
    if character then
        if character:FindFirstChild("Gun") then return "Gun" end
        if character:FindFirstChild("Knife") then return "Knife" end
    end
    
    return nil
end

local function GetRoleColor(player, playerRoles)
    for id, data in pairs(playerRoles) do
        if data and typeof(data) == "table" then
            if tostring(id) == tostring(player.UserId) or id == player.Name then
                local colors = {
                    Murderer = Color3.new(1, 0, 0),
                    Sheriff = Color3.new(0, 0.5, 1),
                    Innocent = Color3.new(0, 1, 0)
                }
                return colors[data.Role] or colors.Innocent
            end
        end
    end
    
    local toolType = GetToolType(player)
    if toolType == "Gun" then return Color3.new(0, 0.5, 1) end
    if toolType == "Knife" then return Color3.new(1, 0, 0) end
    
    return Color3.new(0, 1, 0)
end

local function CleanupESP(envPrefix)
    local connections = {
        "RemoteConnection", "DataConnection", "RoundEndConnection", 
        "RoundStartConnection", "PlayerAdded", "PlayerRemoving"
    }
    
    for _, name in ipairs(connections) do
        local conn = getgenv()[envPrefix .. name]
        if conn then
            conn:Disconnect()
            getgenv()[envPrefix .. name] = nil
        end
    end
    
    local loop = getgenv()[envPrefix .. "RefreshLoop"]
    if loop then
        task.cancel(loop)
        getgenv()[envPrefix .. "RefreshLoop"] = nil
    end
    
    local charConns = getgenv()[envPrefix .. "Connections"]
    if charConns then
        for _, conn in pairs(charConns) do
            if conn then conn:Disconnect() end
        end
        getgenv()[envPrefix .. "Connections"] = {}
    end
    
    local objects = getgenv()[envPrefix .. "Objects"]
    if objects then
        for _, obj in pairs(objects) do
            if obj then obj:Destroy() end
        end
        getgenv()[envPrefix .. "Objects"] = {}
    end
    
    local rolesKey = envPrefix:gsub("ESP", "") .. "Roles"
    getgenv()[rolesKey] = {}
end

local PlayerESPToggle = ESPTab:Toggle({
    Title = "Player ESP",
    Desc = "Allows you to see Players through walls",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if not state then
            CleanupESP("PlayerESP")
            return
        end
        
        getgenv().PlayerESPObjects = {}
        getgenv().PlayerESPConnections = {}
        getgenv().PlayerRoles = {}
        
        local function UpdateESPColor(player, esp)
            if not esp then return end
            local color = GetRoleColor(player, getgenv().PlayerRoles)
            esp.FillColor = color
            esp.OutlineColor = color
        end
        
        local function CreateESP(player)
            if player == LocalPlayer or not player.Character then return end
            
            if getgenv().PlayerESPObjects[player] then
                getgenv().PlayerESPObjects[player]:Destroy()
            end
            
            local esp = Instance.new("Highlight")
            esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            esp.FillTransparency = 0.65
            esp.OutlineTransparency = 0.3
            esp.Parent = player.Character
            
            UpdateESPColor(player, esp)
            getgenv().PlayerESPObjects[player] = esp
        end
        
        local function SetupPlayer(player)
            if player == LocalPlayer then return end
            
            if player.Character then
                CreateESP(player)
            end
            
            getgenv().PlayerESPConnections[player] = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                CreateESP(player)
            end)
        end
        
        getgenv().PlayerESPRemoteConnection = FadeEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then
                getgenv().PlayerRoles = data
            end
        end)
        
        getgenv().PlayerESPDataConnection = DataChangedEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then
                getgenv().PlayerRoles = data
                for plr, esp in pairs(getgenv().PlayerESPObjects) do
                    UpdateESPColor(plr, esp)
                end
            end
        end)
        
        getgenv().PlayerESPRoundEndConnection = RoundEndEvent.OnClientEvent:Connect(function()
            getgenv().PlayerRoles = {}
            for _, esp in pairs(getgenv().PlayerESPObjects) do
                if esp then
                    esp.FillColor = Color3.new(0, 1, 0)
                    esp.OutlineColor = Color3.new(0, 1, 0)
                end
            end
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            SetupPlayer(player)
        end
        
        getgenv().PlayerESPPlayerAdded = Players.PlayerAdded:Connect(SetupPlayer)
        getgenv().PlayerESPPlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            if getgenv().PlayerESPObjects[player] then
                getgenv().PlayerESPObjects[player]:Destroy()
                getgenv().PlayerESPObjects[player] = nil
            end
            if getgenv().PlayerESPConnections[player] then
                getgenv().PlayerESPConnections[player]:Disconnect()
                getgenv().PlayerESPConnections[player] = nil
            end
        end)
        
        getgenv().PlayerESPRefreshLoop = task.spawn(function()
            while true do
                task.wait(1)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        if not getgenv().PlayerESPObjects[player] then
                            CreateESP(player)
                        else
                            UpdateESPColor(player, getgenv().PlayerESPObjects[player])
                        end
                    end
                end
            end
        end)
    end
})

local NameESPToggle = ESPTab:Toggle({
    Title = "Player Names ESP",
    Desc = "Shows username and display name above players",
    Icon = "app-window",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if not state then
            CleanupESP("NameESP")
            return
        end
        
        getgenv().NameESPObjects = {}
        getgenv().NameESPConnections = {}
        getgenv().NameRoles = {}
        
        local function UpdateNameColor(player, esp)
            if not esp then return end
            local label = esp:FindFirstChildOfClass("TextLabel")
            if label then
                label.TextColor3 = GetRoleColor(player, getgenv().NameRoles)
            end
        end
        
        local function CreateNameESP(player)
            if player == LocalPlayer or not player.Character then return end
            
            local head = player.Character:FindFirstChild("Head")
            if not head then return end
            
            if getgenv().NameESPObjects[player] then
                getgenv().NameESPObjects[player]:Destroy()
            end
            
            local esp = Instance.new("BillboardGui")
            esp.Size = UDim2.new(0, 200, 0, 40)
            esp.AlwaysOnTop = true
            esp.StudsOffset = Vector3.new(0, 2.5, 0)
            esp.Adornee = head
            esp.Parent = head
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = 0
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.TextColor3 = GetRoleColor(player, getgenv().NameRoles)
            
            local displaySuffix = player.DisplayName ~= player.Name and " (" .. player.DisplayName .. ")" or ""
            label.Text = player.Name .. displaySuffix
            label.Parent = esp
            
            getgenv().NameESPObjects[player] = esp
        end
        
        local function SetupPlayer(player)
            if player == LocalPlayer then return end
            
            if player.Character then
                CreateNameESP(player)
            end
            
            getgenv().NameESPConnections[player] = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                CreateNameESP(player)
            end)
        end
        
        getgenv().NameESPRemoteConnection = FadeEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then
                getgenv().NameRoles = data
            end
        end)
        
        getgenv().NameESPDataConnection = DataChangedEvent.OnClientEvent:Connect(function(data)
            if typeof(data) == "table" then
                getgenv().NameRoles = data
                for plr, esp in pairs(getgenv().NameESPObjects) do
                    UpdateNameColor(plr, esp)
                end
            end
        end)
        
        getgenv().NameESPRoundEndConnection = RoundEndEvent.OnClientEvent:Connect(function()
            getgenv().NameRoles = {}
            for _, esp in pairs(getgenv().NameESPObjects) do
                local label = esp and esp:FindFirstChildOfClass("TextLabel")
                if label then
                    label.TextColor3 = Color3.new(0, 1, 0)
                end
            end
        end)
        
        getgenv().NameESPRoundStartConnection = RoundStartEvent.OnClientEvent:Connect(function()
            getgenv().NameRoles = {}
            for plr, esp in pairs(getgenv().NameESPObjects) do
                UpdateNameColor(plr, esp)
            end
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            SetupPlayer(player)
        end
        
        getgenv().NameESPPlayerAdded = Players.PlayerAdded:Connect(SetupPlayer)
        getgenv().NameESPPlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            if getgenv().NameESPObjects[player] then
                getgenv().NameESPObjects[player]:Destroy()
                getgenv().NameESPObjects[player] = nil
            end
            if getgenv().NameESPConnections[player] then
                getgenv().NameESPConnections[player]:Disconnect()
                getgenv().NameESPConnections[player] = nil
            end
        end)
        
        getgenv().NameESPRefreshLoop = task.spawn(function()
            while true do
                task.wait(1)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        if not getgenv().NameESPObjects[player] then
                            CreateNameESP(player)
                        else
                            UpdateNameColor(player, getgenv().NameESPObjects[player])
                        end
                    end
                end
            end
        end)
    end
})

ESPTab:Divider()

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
        if not getgenv().BarrierModifiedParts then
            getgenv().BarrierModifiedParts = {}
        end
        
        local function IsWall(obj)
            return math.abs(obj.CFrame.UpVector.Y) < 0.5
        end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            task.spawn(function()
                if obj:IsA("BasePart") and not obj:IsA("TrussPart") then
                    if obj.Name == "GlitchProof" then
                        if not getgenv().BarrierModifiedParts[obj] then
                            getgenv().BarrierModifiedParts[obj] = obj.CanCollide
                        end
                        obj.CanCollide = false
                    elseif obj.Transparency == 1 and IsWall(obj) then
                        if not getgenv().BarrierModifiedParts[obj] then
                            getgenv().BarrierModifiedParts[obj] = obj.CanCollide
                        end
                        obj.CanCollide = false
                    end
                end
            end)
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
        if not getgenv().BarrierModifiedParts then
            getgenv().BarrierModifiedParts = {}
        end
        
        local function IsWall(obj)
            return math.abs(obj.CFrame.UpVector.Y) < 0.5
        end
        
        local function ProcessObject(obj)
            task.spawn(function()
                if obj:IsA("BasePart") and not obj:IsA("TrussPart") then
                    if obj.Name == "GlitchProof" then
                        if not getgenv().BarrierModifiedParts[obj] then
                            getgenv().BarrierModifiedParts[obj] = obj.CanCollide
                        end
                        obj.CanCollide = false
                        return
                    end
                    
                    if obj.Transparency == 1 and IsWall(obj) then
                        if not getgenv().BarrierModifiedParts[obj] then
                            getgenv().BarrierModifiedParts[obj] = obj.CanCollide
                        end
                        obj.CanCollide = false
                    end
                end
            end)
        end
        
        if state then
            if getgenv().BarrierDescendantConnection then
                getgenv().BarrierDescendantConnection:Disconnect()
                getgenv().BarrierDescendantConnection = nil
            end
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                ProcessObject(obj)
            end

            getgenv().BarrierDescendantConnection = Workspace.DescendantAdded:Connect(ProcessObject)
        else
            if getgenv().BarrierDescendantConnection then
                getgenv().BarrierDescendantConnection:Disconnect()
                getgenv().BarrierDescendantConnection = nil
            end
            
            for part, originalCollisionState in pairs(getgenv().BarrierModifiedParts) do
                if part and part.Parent then
                    part.CanCollide = originalCollisionState
                end
            end
            
            getgenv().BarrierModifiedParts = {}
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

MiscTab:Divider()

local OutfitToggle = MiscTab:Toggle({
    Title = "Outfits Toggle",
    Desc = "Toggles outfit GUI in KMM, might work when Season 2 comes out",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            getgenv().OutfitGUIToggleActive = true
            
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local LocalPlayer = Players.LocalPlayer
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            
            local gameTopbar = PlayerGui:WaitForChild("GameTopbar")
            local originalScript = gameTopbar:FindFirstChild("CatalogV4")
            if originalScript and originalScript:IsA("LocalScript") then
                originalScript.Disabled = true
                getgenv().OriginalCatalogScript = originalScript
            end
            
            task.wait(0.2)
            
            local function SetupButton()
                local container = gameTopbar:FindFirstChild("Container")
                if not container then return end
                
                local avatar = container:FindFirstChild("Avatar")
                if not avatar then return end
                
                avatar.Visible = true
                
                local button = avatar:FindFirstChild("Container") and avatar.Container:FindFirstChild("Button")
                if button and not getgenv().OutfitButtonConnection then
                    getgenv().OutfitButtonConnection = button.Activated:Connect(function()
                        if not getgenv().OutfitGUIToggleActive then return end
                        
                        local catalogGUI = PlayerGui:FindFirstChild("CatalogGUI")
                        if not catalogGUI then return end
                        
                        local newState = not catalogGUI.Enabled
                        catalogGUI.Enabled = newState
                        
                        if newState then
                            getgenv().OutfitWasOpened = true
                            
                            local CatalogCreator = ReplicatedStorage:FindFirstChild("CatalogAvatarCreator")
                            if CatalogCreator then
                                local Events = CatalogCreator:FindFirstChild("Events")
                                if Events then
                                    local openCatalog = Events:FindFirstChild("ClientToggleOpenCatalog")
                                    if openCatalog then
                                        openCatalog:Fire(true)
                                    end
                                end
                                local toggleUI = CatalogCreator:FindFirstChild("ClientToggleUIVisible")
                                if toggleUI then
                                    toggleUI:Fire(true)
                                end
                            end
                        else
                            getgenv().OutfitWasOpened = false
                        end
                    end)
                end
            end
            
            SetupButton()
            
            getgenv().OutfitLoop = task.spawn(function()
                while getgenv().OutfitGUIToggleActive do
                    local container = gameTopbar:FindFirstChild("Container")
                    if container then
                        local avatar = container:FindFirstChild("Avatar")
                        if avatar then
                            avatar.Visible = true
                        end
                    end
                    
                    if getgenv().OutfitWasOpened then
                        local catalogGUI = PlayerGui:FindFirstChild("CatalogGUI")
                        if catalogGUI and not catalogGUI.Enabled then
                            catalogGUI.Enabled = true
                        end
                    end
                    
                    task.wait(0.05)
                end
            end)
            
        else
            getgenv().OutfitGUIToggleActive = false
            getgenv().OutfitWasOpened = false
            
            if getgenv().OriginalCatalogScript then
                getgenv().OriginalCatalogScript.Disabled = false
                getgenv().OriginalCatalogScript = nil
            end
            
            if getgenv().OutfitButtonConnection then
                getgenv().OutfitButtonConnection:Disconnect()
                getgenv().OutfitButtonConnection = nil
            end
            
            if getgenv().OutfitLoop then
                task.cancel(getgenv().OutfitLoop)
                getgenv().OutfitLoop = nil
            end
            
            local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if PlayerGui then
                local catalogGUI = PlayerGui:FindFirstChild("CatalogGUI")
                if catalogGUI then
                    catalogGUI.Enabled = false
                end
            end
        end
    end
})
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
    Desc = "Adjust the speed so it'll start working'",
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

InnocentTab:Divider()

local EasierGlitchingToggle = InnocentTab:Toggle({
    Title = "Easy Glitching",
    Desc = "Helps you glitch through walls more easily",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            local SpamThreshold = 1
            local TeleportDistance = 1.2
            local WallDistance = 0.4
            local CooldownTime = 0
            
            getgenv().GlitchingActive = true
            getgenv().GlitchingCooldown = false
            getgenv().GlitchingTools = {}
            
            local lastEquipTime = 0
            local lastTool = nil
            
            local function CheckWallInFront()
                local character = LocalPlayer.Character
                if not character then return false end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return false end
                
                local lookVector = hrp.CFrame.LookVector
                local horizontalDir = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
                
                local rayOrigin = hrp.Position
                local rayDirection = horizontalDir * WallDistance
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                return result ~= nil
            end
            
            local function TeleportForward()
                local character = LocalPlayer.Character
                if not character then return end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local lookVector = hrp.CFrame.LookVector
                local horizontalDir = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
                local forward = horizontalDir * TeleportDistance
                
                hrp.Position = hrp.Position + forward
            end
            
            local function OnToolEquipped(tool)
                if not getgenv().GlitchingActive or getgenv().GlitchingCooldown then return end
                
                local currentTime = tick()
                
                if lastTool == tool and (currentTime - lastEquipTime) < SpamThreshold then
                    if CheckWallInFront() then
                        TeleportForward()
                        
                        getgenv().GlitchingCooldown = true
                        task.delay(CooldownTime, function()
                            getgenv().GlitchingCooldown = false
                        end)
                    end
                end
                
                lastEquipTime = currentTime
                lastTool = tool
            end
            
            local function SetupTool(tool)
                if not tool:IsA("Tool") then return end
                if getgenv().GlitchingTools[tool] then return end
                
                getgenv().GlitchingTools[tool] = true
                tool.Equipped:Connect(function()
                    OnToolEquipped(tool)
                end)
            end
            
            local function OnCharacterAdded(character)
                getgenv().GlitchingTools = {}
                
                local backpack = LocalPlayer:WaitForChild("Backpack")
                
                for _, tool in ipairs(backpack:GetChildren()) do
                    SetupTool(tool)
                end
                
                backpack.ChildAdded:Connect(SetupTool)
                
                character.ChildAdded:Connect(function(child)
                    if child:IsA("Tool") then
                        SetupTool(child)
                    end
                end)
            end
            
            if LocalPlayer.Character then
                OnCharacterAdded(LocalPlayer.Character)
            end
            
            getgenv().GlitchingCharacterAdded = LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
            
        else
            getgenv().GlitchingActive = false
            getgenv().GlitchingTools = {}
            
            if getgenv().GlitchingCharacterAdded then
                getgenv().GlitchingCharacterAdded:Disconnect()
                getgenv().GlitchingCharacterAdded = nil
            end
        end
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
        if not char then return end
        
        local gun = char:FindFirstChild("Gun")
        if not gun then return end
        
        local originCF
        local gunServer = gun:FindFirstChild("GunServer")
        if gunServer then
            local attachment = gunServer:FindFirstChild("GunRaycastAttachment1") or gunServer:FindFirstChild("RaycastAttachment")
            if attachment then
                originCF = attachment.WorldCFrame
            end
        end
        
        if not originCF then
            local handle = gun:FindFirstChild("Handle") or gun:FindFirstChild("Gun")
            if handle and handle:IsA("BasePart") then
                originCF = handle.CFrame
            end
        end
        
        if not originCF then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            originCF = hrp.CFrame
        end
        
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
        
        local result = workspace:Raycast(originCF.Position, (targetHRP.Position - originCF.Position).Unit * 1000, rayParams)
        
        if not result or not result.Instance:IsDescendantOf(targetPlayer.Character) then return end
        
        local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("Fire")
        if shootRemote then
            local args = {
                CFrame.new(originCF.Position, targetHRP.Position),
                CFrame.new(targetHRP.Position)
            }
            shootRemote:FireServer(unpack(args))
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
                    if not char then task.wait() continue end
                    
                    local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")
                    if not gun then task.wait() continue end
                    
                    local originCF
                    local gunServer = gun:FindFirstChild("GunServer")
                    if gunServer then
                        local attachment = gunServer:FindFirstChild("GunRaycastAttachment1") or gunServer:FindFirstChild("RaycastAttachment")
                        if attachment then
                            originCF = attachment.WorldCFrame
                        end
                    end
                    
                    if not originCF then
                        local handle = gun:FindFirstChild("Handle") or gun:FindFirstChild("Gun")
                        if handle and handle:IsA("BasePart") then
                            originCF = handle.CFrame
                        end
                    end
                    
                    if not originCF then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if not hrp then task.wait() continue end
                        originCF = hrp.CFrame
                    end
                    
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
                    
                    local direction = (targetHRP.Position - originCF.Position).Unit * 1000
                    local result = workspace:Raycast(originCF.Position, direction, rayParams)
                    
                    if not result or not result.Instance:IsDescendantOf(targetModel) then task.wait() continue end
                    
                    local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("Fire")
                    if not shootRemote then task.wait() continue end
                    
                    local args = {
                        CFrame.new(originCF.Position, targetHRP.Position),
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

local SelectedPlayer = nil

local function GetPlayerList()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    if #names == 0 then
        names = {"No players"}
    end
    return names
end

local PlayerDropdown = MurdererTab:Dropdown({
    Title = "Player Dropdown",
    Desc = "Select a player to trap",
    Values = GetPlayerList(),
    Value = GetPlayerList()[1] or "No players",
    Multi = false,
    AllowNone = false,
    Callback = function(option)
        SelectedPlayer = Players:FindFirstChild(option)
    end
})

task.spawn(function()
    while true do
        task.wait(5)
        local newList = GetPlayerList()
        PlayerDropdown:Refresh(newList)
        
        if SelectedPlayer and not SelectedPlayer.Parent then
            SelectedPlayer = nil
        end
    end
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    PlayerDropdown:Refresh(GetPlayerList())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    PlayerDropdown:Refresh(GetPlayerList())
    if SelectedPlayer and not SelectedPlayer.Parent then
        SelectedPlayer = nil
    end
end)

local TrapPlayerButton = MurdererTab:Button({
    Title = "Trap selected Player",
    Desc = "Traps / Freezes the selected player for a few seconds",
    Locked = false,
    Callback = function()
        if not SelectedPlayer or SelectedPlayer == "No players" then
            WindUI:Notify({
                Title = "No player selected",
                Content = "Please select a player from the dropdown",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        if not SelectedPlayer.Character then
            WindUI:Notify({
                Title = "Player not spawned",
                Content = "Selected player has no character",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        local targetHRP = SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            WindUI:Notify({
                Title = "Cannot trap",
                Content = "Player has no HumanoidRootPart",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        local args = {
            targetHRP.CFrame
        }
        
        local trap = LocalPlayer.Character:FindFirstChild("Trap")
        if trap then
            local activate = trap:FindFirstChild("Activate")
            if activate then
                activate:FireServer(unpack(args))
            end
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local MapTab = Window:Tab({
    Title = "Map",
    Icon = "map",
    Locked = false,
})

local LockdownRFButton = MapTab:Button({
    Title = "Initiate Lockdown",
    Desc = "Research Facility map only",
    Locked = false,
    Callback = function()
        local interact = Workspace:WaitForChild("ResearchFacility"):WaitForChild("Interactive"):WaitForChild("SirenSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then
            interact:FireServer()
        end
    end
})

local CloneRFButton = MapTab:Button({
    Title = "Close Cloning Machine",
    Desc = "Research Facility map only",
    Locked = false,
    Callback = function()
        local interact = Workspace:WaitForChild("ResearchFacility"):WaitForChild("Interactive"):WaitForChild("CloningSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then
            interact:FireServer()
        end
    end
})

local GarageButton = MapTab:Button({
    Title = "Open / Close Garage",
    Desc = "Research Facility map only",
    Locked = false,
    Callback = function()
        local interact = Workspace:WaitForChild("ResearchFacility"):WaitForChild("Interactive"):WaitForChild("GarageSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then
            interact:FireServer()
        end
    end
})

MapTab:Divider()

local BankVaultButton = MapTab:Button({
    Title = "Open Bank Vault",
    Desc = "Bank 2 map only",
    Locked = false,
    Callback = function()
        local interact = workspace:WaitForChild("Bank2"):WaitForChild("Interactive"):WaitForChild("VaultSystem"):WaitForChild("InteractiveBox"):WaitForChild("Interact")
        if interact then
            interact:FireServer()
        end
    end
})
-------------------------------------------------------------------------------------------------------------------
local VotingTab = Window:Tab({
    Title = "Voting",
    Icon = "map-pin-check",
    Locked = false,
})

local MapDropdown = VotingTab:Dropdown({
    Title = "Maps you can Vote for",
    Desc = "Allows you to select a map to vote for",
    Values = {},
    Value = nil,
    Multi = false,
    AllowNone = true,
    Callback = function(option) 
        getgenv().SelectedMap = option
    end
})

local function GetAvailableMaps()
    local maps = {}
    local regularLobby = Workspace:FindFirstChild("RegularLobby")
    
    if regularLobby then
        for i = 1, 3 do
            local votePad = regularLobby:FindFirstChild("VotePad" .. i)
            if votePad then
                local voteInfoGui = votePad:FindFirstChild("VoteInfoGui")
                if voteInfoGui then
                    local container = voteInfoGui:FindFirstChild("Container")
                    if container then
                        local mapNameLabel = container:FindFirstChild("MapName")
                        if mapNameLabel and mapNameLabel:IsA("TextLabel") and mapNameLabel.Text ~= "" then
                            table.insert(maps, mapNameLabel.Text)
                        end
                    end
                end
            end
        end
    end
    
    return maps
end

getgenv().MapToPad = {}

local function UpdateMaps()
    getgenv().MapToPad = {}
    local regularLobby = Workspace:FindFirstChild("RegularLobby")
    
    if regularLobby then
        for i = 1, 3 do
            local votePad = regularLobby:FindFirstChild("VotePad" .. i)
            if votePad then
                local voteInfoGui = votePad:FindFirstChild("VoteInfoGui")
                if voteInfoGui then
                    local container = voteInfoGui:FindFirstChild("Container")
                    if container then
                        local mapNameLabel = container:FindFirstChild("MapName")
                        if mapNameLabel and mapNameLabel:IsA("TextLabel") and mapNameLabel.Text ~= "" then
                            getgenv().MapToPad[mapNameLabel.Text] = votePad
                        end
                    end
                end
            end
        end
    end
    
    local maps = {}
    for mapName, _ in pairs(getgenv().MapToPad) do
        table.insert(maps, mapName)
    end
    
    MapDropdown.Values = maps
    if MapDropdown.SetValues then
        MapDropdown.SetValues(maps)
    end
end

UpdateMaps()

task.spawn(function()
    while true do
        task.wait(5)
        UpdateMaps()
    end
end)

local VoteButton = VotingTab:Button({
    Title = "Vote for Selected Map",
    Desc = "Votes for the Map you selected, then resets.",
    Locked = false,
    Callback = function()
        local selectedMap = getgenv().SelectedMap
        if not selectedMap then return end
        
        local votePad = getgenv().MapToPad[selectedMap]
        if not votePad then 
            UpdateMaps()
            votePad = getgenv().MapToPad[selectedMap]
            if not votePad then return end
        end
        
        local pad = votePad:FindFirstChild("Pad")
        if pad and pad:IsA("BasePart") then
            local character = game.Players.LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = pad.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
        
        getgenv().SelectedMap = nil
        MapDropdown.Value = nil
    end
})
-------------------------------------------------------------------------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().CurrentSheriffInput = ""
getgenv().CurrentMurdererInput = ""
getgenv().CurrentMapInput = ""

local AdminTab = Window:Tab({
    Title = "Admin",
    Icon = "sparkles",
    Locked = false,
})

local SheriffInput = AdminTab:Input({
    Title = "Sheriff Input",
    Icon = "ellipsis",
    Placeholder = "Enter Username",
    Callback = function(input)
        if not input or input:match("^%s*$") then 
            return 
        end
        getgenv().CurrentSheriffInput = input
        task.spawn(function()
            pcall(function()
                local TextChatService = game:GetService("TextChatService")
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/sheriff " .. input)
            end)
        end)
    end
})

local AutoSheriffInputToggle = AdminTab:Toggle({
    Title = "Auto Sheriff Input",
    Desc = "Automatically makes the inputted player sheriff every round.",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            if getgenv().CurrentSheriffInput and getgenv().CurrentSheriffInput ~= "" then
                task.spawn(function()
                    pcall(function()
                        local TextChatService = game:GetService("TextChatService")
                        local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                        channel:SendAsync("/sheriff " .. getgenv().CurrentSheriffInput)
                    end)
                end)
            end
            local Event = game:GetService("ReplicatedStorage").Remotes.Gameplay.RoundEndFade
            getgenv().AutoSheriffInputConnection = Event.OnClientEvent:Connect(function()
                if getgenv().CurrentSheriffInput and getgenv().CurrentSheriffInput ~= "" then
                    task.spawn(function()
                        pcall(function()
                            local TextChatService = game:GetService("TextChatService")
                            local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                            channel:SendAsync("/sheriff " .. getgenv().CurrentSheriffInput)
                        end)
                    end)
                end
            end)
        else
            if getgenv().AutoSheriffInputConnection then
                getgenv().AutoSheriffInputConnection:Disconnect()
                getgenv().AutoSheriffInputConnection = nil
            end
        end
    end
})

local MurdererInput = AdminTab:Input({
    Title = "Murderer Input",
    Icon = "ellipsis",
    Placeholder = "Enter Username",
    Callback = function(input)
        if not input or input:match("^%s*$") then 
            return 
        end
        getgenv().CurrentMurdererInput = input
        task.spawn(function()
            pcall(function()
                local TextChatService = game:GetService("TextChatService")
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/murderer " .. input)
            end)
        end)
    end
})

local AutoMurdererInputToggle = AdminTab:Toggle({
    Title = "Auto Murderer Input",
    Desc = "Automatically makes the inputted player murderer every round.",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            if getgenv().CurrentMurdererInput and getgenv().CurrentMurdererInput ~= "" then
                task.spawn(function()
                    pcall(function()
                        local TextChatService = game:GetService("TextChatService")
                        local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                        channel:SendAsync("/murderer " .. getgenv().CurrentMurdererInput)
                    end)
                end)
            end
            local Event = game:GetService("ReplicatedStorage").Remotes.Gameplay.RoundEndFade
            getgenv().AutoMurdererInputConnection = Event.OnClientEvent:Connect(function()
                if getgenv().CurrentMurdererInput and getgenv().CurrentMurdererInput ~= "" then
                    task.spawn(function()
                        pcall(function()
                            local TextChatService = game:GetService("TextChatService")
                            local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                            channel:SendAsync("/murderer " .. getgenv().CurrentMurdererInput)
                        end)
                    end)
                end
            end)
        else
            if getgenv().AutoMurdererInputConnection then
                getgenv().AutoMurdererInputConnection:Disconnect()
                getgenv().AutoMurdererInputConnection = nil
            end
        end
    end
})

AdminTab:Divider()

local MapInput = AdminTab:Input({
    Title = "Map Input",
    Icon = "map",
    Placeholder = "Enter Map Name",
    Callback = function(input)
        if not input or input:match("^%s*$") then 
            return 
        end
        getgenv().CurrentMapInput = input
        task.spawn(function()
            pcall(function()
                local TextChatService = game:GetService("TextChatService")
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/map " .. input)
            end)
        end)
    end
})

local SetMapButton = AdminTab:Button({
    Title = "Set Map",
    Desc = "Sets the Map via Input",
    Callback = function()
        if not getgenv().CurrentMapInput or getgenv().CurrentMapInput == "" then
            return
        end
        task.spawn(function()
            pcall(function()
                local TextChatService = game:GetService("TextChatService")
                local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                channel:SendAsync("/map " .. getgenv().CurrentMapInput)
            end)
        end)
    end
})

local AutoMapToggle = AdminTab:Toggle({
    Title = "Automatically Vote Map",
    Desc = "Automatically votes for the entered map every round.",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            if getgenv().CurrentMapInput and getgenv().CurrentMapInput ~= "" then
                task.spawn(function()
                    pcall(function()
                        local TextChatService = game:GetService("TextChatService")
                        local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                        channel:SendAsync("/map " .. getgenv().CurrentMapInput)
                    end)
                end)
            end
            local Event = game:GetService("ReplicatedStorage").Remotes.Gameplay.RoundEndFade
            getgenv().AutoMapConnection = Event.OnClientEvent:Connect(function()
                if getgenv().CurrentMapInput and getgenv().CurrentMapInput ~= "" then
                    task.spawn(function()
                        pcall(function()
                            local TextChatService = game:GetService("TextChatService")
                            local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
                            channel:SendAsync("/map " .. getgenv().CurrentMapInput)
                        end)
                    end)
                end
            end)
        else
            if getgenv().AutoMapConnection then
                getgenv().AutoMapConnection:Disconnect()
                getgenv().AutoMapConnection = nil
            end
        end
    end
})

AdminTab:Divider()
-------------------------------------------------------------------------------------------------------------------
