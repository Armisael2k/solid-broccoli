local url = "https://raw.githubusercontent.com/Armisael2k/solid-broccoli/refs/heads/refresh/brocco_1.lua"
loadstring(game:HttpGet(url))()

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
    else
      warn("No team found for username: " .. username)
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

-- Function to shoot and hit enemies
local function shootAtEnemies()
    print("DEBUG: shootAtEnemies function called")
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character then
        print("DEBUG: No character found")
        return
    end
    print("DEBUG: Character found:", character.Name)
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        print("DEBUG: No tool equipped")
        return
    end
    print("DEBUG: Tool equipped:", tool.Name)

    local localPlayerTeam = player.Team
    if not localPlayerTeam then
        print("DEBUG: Local player has no Team")
        return
    end
    print("DEBUG: Local player team:", localPlayerTeam.Name)
    
    print("DEBUG: Searching for enemy players...")
    local enemyPlayers = {}
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        print("DEBUG: Checking player:", otherPlayer.Name)
        print("  - Player team:", otherPlayer.Team and otherPlayer.Team.Name or "No team")
        print("  - Same player?", otherPlayer == player)
        print("  - Has team?", otherPlayer.Team ~= nil)
        print("  - Different team?", otherPlayer.Team and otherPlayer.Team ~= localPlayerTeam)
        
        if otherPlayer ~= player and otherPlayer.Team and otherPlayer.Team ~= localPlayerTeam then
            print("  - This is an enemy! Checking character...")
            print("  - Has character?", otherPlayer.Character ~= nil)
            print("  - Character parent is workspace?", otherPlayer.Character and otherPlayer.Character.Parent == workspace)
            print("  - Has HumanoidRootPart?", otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") ~= nil)
            
            if otherPlayer.Character and otherPlayer.Character.Parent == workspace and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(enemyPlayers, otherPlayer)
                print("  - Enemy added to list!")
            else
                print("  - Enemy has invalid character")
            end
        else
            print("  - Not an enemy")
        end
    end
    
    print("DEBUG: Total enemy players found:", #enemyPlayers)
    
    if #enemyPlayers == 0 then
        print("DEBUG: No enemy players found")
        return
    end
    
    print("Found", #enemyPlayers, "enemy players. Starting to shoot...")
    
    for _, enemyPlayer in ipairs(enemyPlayers) do
        print("DEBUG: Processing enemy:", enemyPlayer.Name)
        if enemyPlayer.Character and enemyPlayer.Character:FindFirstChild("HumanoidRootPart") then
            print("Targeting enemy:", enemyPlayer.Name)
            
            local targetPosition = enemyPlayer.Character.HumanoidRootPart.Position
            print("DEBUG: Target position:", targetPosition)
            
            tool:Activate()
            print("DEBUG: Tool activated")
            
            local shootRemote = game.ReplicatedStorage.Remotes.ShootGun
            if shootRemote then
                local characterRayOrigin = character.HumanoidRootPart.Position
                print("DEBUG: Firing remote - Origin:", characterRayOrigin, "Target:", targetPosition)
                shootRemote:FireServer(characterRayOrigin, targetPosition, enemyPlayer.Character.HumanoidRootPart, targetPosition)
                print("DEBUG: Remote fired successfully")
            else
                print("DEBUG: Shoot remote not found in ReplicatedStorage.Remotes")
            end
            
            print("Shot at enemy:", enemyPlayer.Name)
            wait(0.1)
        else
            print("DEBUG: Enemy", enemyPlayer.Name, "has invalid character or HumanoidRootPart")
        end
    end
    
    print("Finished shooting at enemies")
end

-- Function to check if player is in match (has tool 2)
local function isInMatch()
    return (game.Players.LocalPlayer:GetAttribute("Match") or 0) > 0
end

-- Main game loop
local function startMainLoop()
    print("Starting main game loop...")
    
    -- Loop for teleportToPad (runs always, every 0.5 seconds)
    spawn(function()
        while true do
            local localPlayer = game.Players.LocalPlayer
            if localPlayer and localPlayer.Name then
                teleportToPad(localPlayer.Name)
            end
            wait(0.5)
        end
    end)
    
    -- Loop for equipGun (checks isInMatch internally, every 1 second)
    spawn(function()
        while true do
            if isInMatch() then
                equipGun()
            end
            wait(1)
        end
    end)
    
    -- Loop for shootAtEnemies (checks isInMatch internally, every 0.05 seconds)
    spawn(function()
        while true do
            if isInMatch() then
                local player = game.Players.LocalPlayer
                local seasonLevel = player:GetAttribute("SeasonLevel") or 0
                
                if seasonLevel <= 15 then
                    shootAtEnemies()
                    wait(0.05)
                else
                    wait(10) -- Wait longer when season level is too high
                end
            else
                wait(0.5) -- Wait longer when not in match to save resources
            end
        end
    end)
end

-- Start the main loop
startMainLoop()

print("Script execution completed. Main loop is now running.")
print("- TeleportToPad: every 0.5 seconds (always)")
print("- EquipGun: every 1 second (when in match)")
print("- ShootAtEnemies: every 0.05 seconds (when in match)")