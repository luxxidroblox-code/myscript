-- DDS Full Adonis Bypass | Arceus X
-- Layer 1: Server report blocker
-- Layer 2: GetRealPhysicsFPS spoof
-- Layer 3: __namecall kick intercept
-- Layer 4: __index instance detector bypass

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local TARGET_REMOTE = "8054bfd4-00b1-4f27-b7c2-37bd97c18573"

local GameMT = getrawmetatable(game)
setreadonly(GameMT, false)

-- Layer 1 + 3 + 4: unified __namecall and __index hook
local OldNamecall = GameMT.__namecall
local OldIndex = GameMT.__index

GameMT.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- Block detection FireServer report
    if method == "FireServer" then
        local ok, name = pcall(function() return self.Name end)
        if ok and name == TARGET_REMOTE then
            return
        end
    end

    -- Block Kick on LocalPlayer (client-side fallback)
    if method == "Kick" and self == LocalPlayer then
        return
    end

    return OldNamecall(self, ...)
end)

-- Layer 4: __index instance detector bypass
GameMT.__index = newcclosure(function(self, key)
    local ok, result = pcall(OldIndex, self, key)
    if not ok then
        return nil
    end
    return result
end)

setreadonly(GameMT, true)

-- Layer 2: GetRealPhysicsFPS spoof
local wsOk = pcall(function()
    local wsMT = getrawmetatable(workspace)
    setreadonly(wsMT, false)
    local OldWsNamecall = wsMT.__namecall
    wsMT.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "GetRealPhysicsFPS" then
            return 60
        end
        return OldWsNamecall(self, ...)
    end)
    setreadonly(wsMT, true)
end)

-- Fallback FPS spoof via hookfunction if workspace MT failed
if not wsOk then
    pcall(function()
        hookfunction(workspace.GetRealPhysicsFPS, newcclosure(function()
            return 60
        end))
    end)
end

-- Layer 2b: gcinfo spoof (blocks GC spoof detection in Adonis mainloop)
pcall(function()
    hookfunction(gcinfo, newcclosure(function()
        return collectgarbage("count")
    end))
end)

-- Keepalive: re-assert setreadonly in case something resets it
task.spawn(function()
    while task.wait(10) do
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            -- hooks are already set, just keep readonly off
            -- so our hooks stay writable if Adonis tries to freeze
        end)
    end
end)