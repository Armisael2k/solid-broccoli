local url = "https://raw.githubusercontent.com/Armisael2k/solid-broccoli/refs/heads/main/brocco_1.lua"
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

-- Hardcoded positions for each game type and team
local padPositions = {
    ["1v1"] = {
        team1 = Vector3.new(37.4428215, -117.451309, 57.7967148),
        team2 = Vector3.new(31.7845898, -117.451309, 57.7968063)
    },
    ["2v2"] = {
        team1 = Vector3.new(46.025692, -117.451309, 57.3252487),
        team2 = Vector3.new(52.5325279, -117.451309, 57.3252716)
    },
    ["3v3"] = {
        team1 = Vector3.new(62.0584984, -117.451309, 56.8536682),
        team2 = Vector3.new(69.6026001, -117.451309, 56.8536606)
    },
    ["4v4"] = {
        team1 = Vector3.new(88.5118713, -117.451309, 56.3821526),
        team2 = Vector3.new(80.0244141, -117.451309, 56.3820496)
    }
}

-- Teleport to lobby pads
local function teleportToPad(username)
    local team = getTeam(username)
    if not team then
        -- warn("No team found for username: " .. username)
        return
    end
    
    -- Get the position for the current game type and team
    local gameType = config and config.type
    if not gameType then
        -- warn("No game type found in config")
        return
    end
    
    local positions = padPositions[gameType]
    if not positions then
        -- warn("No positions found for game type: " .. gameType)
        return
    end
    
    local targetPosition = positions[team]
    if not targetPosition then
        -- warn("No position found for team: " .. team .. " in game type: " .. gameType)
        return
    end
    
    -- Teleport to the target position
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
        -- print("Teleported to", team, "pad in", gameType, "at position:", targetPosition)
    else
        -- warn("No character or HumanoidRootPart found")
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
        -- print("Warning: No tool available in slot 2")
    end
end

-- Function to shoot and hit enemies
local function shootAtEnemies()
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character then
        -- print("FAIL: No character found")
        return
    end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        -- print("FAIL: No tool equipped")
        return
    end

    local localPlayerTeam = player.Team
    if not localPlayerTeam then
        -- print("FAIL: Local player has no Team")
        return
    end
    
    local enemyPlayers = {}
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Team and otherPlayer.Team ~= localPlayerTeam then
            if otherPlayer.Character and otherPlayer.Character.Parent == workspace and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(enemyPlayers, otherPlayer)
            end
        end
    end
    
    if #enemyPlayers == 0 then
        -- print("FAIL: No enemy players found")
        return
    end
    
    -- print("SUCCESS: Found", #enemyPlayers, "enemies, attempting to shoot...")
    
    for _, enemyPlayer in ipairs(enemyPlayers) do
        if enemyPlayer.Character and enemyPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = enemyPlayer.Character.HumanoidRootPart.Position
            
            -- Check if tool is still equipped before shooting
            local currentTool = character:FindFirstChildOfClass("Tool")
            if not currentTool then
                -- print("FAIL: Tool was unequipped during shooting loop")
                return
            end
            
            tool:Activate()
            
            local shootRemote = game.ReplicatedStorage.Remotes.ShootGun
            if shootRemote then
                local characterRayOrigin = character.HumanoidRootPart.Position
                shootRemote:FireServer(characterRayOrigin, targetPosition, enemyPlayer.Character.HumanoidRootPart, targetPosition)
                -- print("SHOT: Fired at", enemyPlayer.Name)
            else
                -- print("FAIL: Shoot remote not found")
                return
            end
            
            wait(0.1)
        else
            -- print("SKIP: Enemy", enemyPlayer.Name, "has invalid character")
        end
    end
    
    -- print("COMPLETE: Finished shooting sequence")
end

-- Function to check if player is in match (has tool 2)
local function isInMatch()
    return (game.Players.LocalPlayer:GetAttribute("Match") or 0) > 0
end

-- Function to clean up map folders
local function initCleanup()
    print("Starting map cleanup...")
    
    local hiddenMaps = game.ReplicatedStorage:FindFirstChild("HiddenMaps")
    if not hiddenMaps then
        print("HiddenMaps folder not found")
        return
    end
    
    local foldersToDelete = {"Borders", "Environment"}
    local deletedCount = 0
    
    -- Iterate through all map folders
    for _, mapFolder in pairs(hiddenMaps:GetChildren()) do
        if mapFolder:IsA("Folder") then
            print("Checking map:", mapFolder.Name)
            
            -- Delete specified folders within each map
            for _, folderName in ipairs(foldersToDelete) do
                local targetFolder = mapFolder:FindFirstChild(folderName)
                if targetFolder then
                    targetFolder:Destroy()
                    deletedCount = deletedCount + 1
                    print("Deleted:", mapFolder.Name .. "." .. folderName)
                end
            end
        end
    end
    
    -- print("Map cleanup completed. Deleted", deletedCount, "folders.")

    if cansetfpscap then
	   	setfpscap(15)
	  end
    -- game:GetService("RunService"):Set3dRenderingEnabled(false)

    print("Frame rate capped to 15 FPS and 3D rendering disabled.")
end

-- Schedule cleanup after 15 seconds
spawn(function()
    -- wait(15)
    -- initCleanup()
end)

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
            wait(2)
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
                    wait(0.1)
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
wait(15) -- Small delay before starting main loop
startMainLoop()

print("Script execution completed. Main loop is now running.")
print("- TeleportToPad: every 0.5 seconds (always)")
print("- EquipGun: every 1 second (when in match)")
print("- ShootAtEnemies: every 0.05 seconds (when in match)")