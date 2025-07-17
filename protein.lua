local url = "https://raw.githubusercontent.com/Armisael2k/solid-broccoli/refs/heads/refresh/brocco_1.lua"
loadstring(game:HttpGet(url))()

print(config)

-- Function to get team name for a given username
local function getTeam(username)
    if not config then
        warn("No config")
        return
      end
      
    for _, player in ipairs(config.team1) do
        if player == username then
            return "team1"
        end
    end
    
    for _, player in ipairs(config.team2) do
        if player == username then
            return "team2"
        end
    end
    
    return nil
end

-- Teleport to lobby pads
local function teleportToPad(username)
    local team = getTeam(username)
    if team then
        local lobby = workspace:FindFirstChild("Lobby")
        if not lobby then
            warn("No 'Lobby' found in Workspace")
            return
        end

        local sideFolder = lobby:FindFirstChild("DuelRingsGroup")
        if not sideFolder then
            warn("No 'DuelRingsGroup' found in Lobby")
            return
        end

        local ringFolder = sideFolder:FindFirstChild("DuelRing_" .. config.type)
        if not ringFolder then
            warn("No 'DuelRing_" .. config.type .. "' found in 'DuelRingsGroup'")
            return
        end

        local pads = {}
        for _, child in ipairs(ringFolder:GetChildren()) do
            if child:IsA("Model") and child.Name == "DuelPad" then
                table.insert(pads, child)
            end
        end

        if #pads == 0 then
            warn("No DuelPads found in the ring")
            return
        end

        local padIx = team == "team1" and 1 or 2
        local pad = pads[padIx]
        if pad and pad.PrimaryPart then
            local teleportPosition = pad.PrimaryPart.Position
            game.Players.LocalPlayer.Character:MoveTo(teleportPosition)
        else
            warn("No valid pad found for team" .. padIx)
        end
    end
end

-- Function to equip gun
local function equipGun()
    local player = game.Players.LocalPlayer
    local backpack = player.Backpack
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- First, unequip any currently equipped tool
    if humanoid then
        humanoid:UnequipTools()
    end
    
    local tools = {}
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
        end
    end
    
    if #tools >= 2 then
        local toolToEquip = tools[2]
        
        if toolToEquip:GetAttribute("Cooldown") then
            toolToEquip:SetAttribute("Cooldown", 0.05)
        end
        
        humanoid:EquipTool(toolToEquip)
    else
        print("Warning: No tool available in slot 2")
    end
end

-- Function to get enemy team based on local player's team
local function getEnemyTeam()
    local localPlayer = game.Players.LocalPlayer
    local localPlayerTeam = getTeam(localPlayer.Name)
    
    if localPlayerTeam == "team1" then
        return config.team2
    elseif localPlayerTeam == "team2" then
        return config.team1
    else
        return nil
    end
end

-- Function to shoot and hit enemies
local function shootAtEnemies()
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character then
        print("Warning: No character found")
        return
    end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        print("Warning: No tool equipped")
        return
    end
    
    local enemyTeam = getEnemyTeam()
    if not enemyTeam then
        print("Warning: Could not determine enemy team")
        return
    end
    
    local enemyPlayers = {}
    for _, enemyName in ipairs(enemyTeam) do
        local enemyPlayer = game.Players:FindFirstChild(enemyName)
        if enemyPlayer and enemyPlayer.Character and enemyPlayer.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(enemyPlayers, enemyPlayer)
        end
    end
    
    if #enemyPlayers == 0 then
        print("Warning: No enemy players found")
        return
    end
    
    for _, enemyPlayer in ipairs(enemyPlayers) do
        if enemyPlayer.Character and enemyPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = enemyPlayer.Character.HumanoidRootPart.Position
            
            tool:Activate()
            print("Shot at enemy:", enemyPlayer.Name)
            wait(0.1)
        end
    end
    
    print("Finished shooting at enemies")
end

shootAtEnemies();