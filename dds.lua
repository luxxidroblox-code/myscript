local Rejoin_Handler = {}

local Teleport_Service = game:GetService("TeleportService")
local Players          = game:GetService("Players")
local Local_Player     = Players.LocalPlayer

function Rejoin_Handler.rejoin_server()
    local place_id = game.PlaceId
    local job_id   = game.JobId
    
    if not place_id or not job_id or job_id == "" then
        return false
    end
    
    local success, result = pcall(function()
        Teleport_Service:TeleportToPlaceInstance(place_id, job_id, Local_Player)
    end)
    
    if not success then
        warn("Rejoin failed: " .. tostring(result))
        return false
    end
    
    return true
end

return Rejoin_Handler
