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

print(teleportToPad("m0tar_EQmmO5G9laX2R"))