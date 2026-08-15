-- DDS Full Adonis Bypass v3 | Arceus X
-- Fix: indexInstance detector via namecall self-identity spoof

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TARGET_REMOTE = "8054bfd4-00b1-4f27-b7c2-37bd97c18573"

local GameMT = getrawmetatable(game)
setreadonly(GameMT, false)

local OldNamecall = GameMT.__namecall
local OldIndex = GameMT.__index

GameMT.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if method == "GetFullName" and self == script then
        return "PlayerGui.UIScript"
    end

    if method == "FireServer" then
        local ok, name = pcall(function() return self.Name end)
        if ok and name == TARGET_REMOTE then
            return
        end
    end

    if method == "Kick" and self == LocalPlayer then
        return
    end

    -- namecallInstance bypass: wrap call in pcall to suppress identity check throw
    local ok, result = pcall(OldNamecall, self, ...)
    if not ok then
        -- Adonis proxy threw on this namecall — swallow it
        return nil
    end
    return result
end)

GameMT.__index = newcclosure(function(self, key)
    local ok, result = pcall(OldIndex, self, key)
    if not ok then return nil end
    return result
end)

setreadonly(GameMT, true)

-- GetRealPhysicsFPS spoof
pcall(function()
    local wsMT = getrawmetatable(workspace)
    setreadonly(wsMT, false)
    local OldWsNamecall = wsMT.__namecall
    wsMT.__namecall = newcclosure(function(self, ...)
        if getnamecallmethod() == "GetRealPhysicsFPS" then return 60 end
        return OldWsNamecall(self, ...)
    end)
    setreadonly(wsMT, true)
end)

-- gcinfo spoof
pcall(function()
    hookfunction(gcinfo, newcclosure(function()
        return collectgarbage("count")
    end))
end)

-- Keepalive
task.spawn(function()
    while task.wait(10) do
        pcall(function() setreadonly(getrawmetatable(game), false) end)
    end
end)