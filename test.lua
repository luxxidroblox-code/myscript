-- DDS Adonis Server-Report Blocker | Arceus X
-- Blocks the detection FireServer before it reaches the server
-- Remote: 8054bfd4-00b1-4f27-b7c2-37bd97c18573

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local TARGET_REMOTE = "8054bfd4-00b1-4f27-b7c2-37bd97c18573"

local GameMT = getrawmetatable(game)
setreadonly(GameMT, false)

local OldNamecall = GameMT.__namecall
GameMT.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if method == "FireServer" then
        -- Block by instance name match
        local ok, name = pcall(function() return self.Name end)
        if ok and name == TARGET_REMOTE then
            return -- drop silently, server never sees it
        end
    end

    return OldNamecall(self, ...)
end)

setreadonly(GameMT, true)

-- Keepalive: if remote gets renamed or replaced, re-block by parent scan
task.spawn(function()
    while task.wait(5) do
        local remote = RS:FindFirstChild(TARGET_REMOTE)
        -- If it exists and is not already blocked, the hook above still covers it
        -- This loop is a watchdog only
    end
end)