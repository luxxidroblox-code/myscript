-- Adonis v280 Full Bypass
-- Targets: Anti.Detected dispatch table + AntiSpeed loop
-- Method: rawset poison (no newcclosure, no hookfunction surface)
-- Safe against LogService string scan and newcclosure patch (#2089)

local function waitForLoad()
    -- Anti module loads after AllModulesLoaded fires
    -- Give it 3s to settle before we walk gc
    task.wait(3)
end

local function findAndPoisonDetected()
    -- Walk gc for the Anti.Detected dispatch table
    -- Structure: { kick=fn, crash=fn, kill=fn, log=fn }
    -- v_u_39 = v_u_37.Detected, stored as upvalue in every detector closure
    for _, obj in getgc(true) do
        if type(obj) ~= "table" then continue end
        local hasKick  = rawget(obj, "kick")
        local hasCrash = rawget(obj, "crash")
        local hasKill  = rawget(obj, "kill")
        local hasLog   = rawget(obj, "log")
        if hasKick and hasCrash and hasKill and hasLog then
            rawset(obj, "kick",  function() end)
            rawset(obj, "crash", function() end)
            rawset(obj, "kill",  function() end)
            rawset(obj, "log",   function() end)
            return true
        end
    end
    return false
end

local function killAntiSpeedLoop()
    -- AntiSpeed loop is registered under "AntiSpeed" key in StartLoop
    -- Walk gc for the loop table: { AntiSpeed = thread/fn, ... }
    -- Kill by finding the scheduler table and clearing the entry
    for _, obj in getgc(true) do
        if type(obj) ~= "table" then continue end
        if rawget(obj, "AntiSpeed") ~= nil then
            rawset(obj, "AntiSpeed", nil)
            return true
        end
    end
    return false
end

local function spoofGetRealPhysicsFPS()
    -- Patch at C closure level so localized workspace ref is covered
    -- Adonis captures workspace via v137(v7) at load — hookfunction
    -- at the C level catches that reference if executor supports it
    local ok, ws = pcall(function()
        return cloneref(game:GetService("Workspace"))
    end)
    if not ok then return false end

    local orig = ws.GetRealPhysicsFPS
    if not orig then return false end

    local hookOk = pcall(hookfunction, orig, newcclosure(function()
        return 60
    end))
    return hookOk
end

local function nukeTamperConnections()
    -- v_u_131 is the script.Changed connection used by tamper check
    -- Disconnecting it increments v_u_137 counter toward crash
    -- Do NOT touch it — leave tamper loop alive, only poison Detected
    -- This function is intentionally a no-op: touching v_u_131 = death
end

-- ── Execute ──────────────────────────────────────────────────────────

waitForLoad()

local detectedPoisoned = findAndPoisonDetected()
local speedLoopKilled  = killAntiSpeedLoop()
local fpsSpoofed       = spoofGetRealPhysicsFPS()

-- Retry if gc walk missed on first pass (modules still loading)
if not detectedPoisoned then
    task.wait(2)
    detectedPoisoned = findAndPoisonDetected()
end

if not speedLoopKilled then
    task.wait(1)
    speedLoopKilled = killAntiSpeedLoop()
end

-- Keepalive: re-poison every 30s in case Adonis re-initializes dispatch
task.spawn(function()
    while task.wait(30) do
        findAndPoisonDetected()
        killAntiSpeedLoop()
    end
end)