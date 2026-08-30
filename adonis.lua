local function unfreezeTable(t)
    if type(t) == "table" then
        pcall(function()
            if setreadonly    then setreadonly(t, false)  end
            if table.unfreeze then table.unfreeze(t)      end
            if make_writeable then make_writeable(t)      end
        end)
        for _, v in pairs(t) do
            if type(v) == "table" then unfreezeTable(v) end
        end
    end
end

local function hiadonis()
    local Detected = filtergc("function", {
        Constants      = { " - On Xbox", " - On mobile", "_" },
        IgnoreExecutor = true,
    }, true)
    if not Detected then
        warn("[projectsion] filtergc miss — Adonis not loaded or constants changed")
        return false
    end

    local s, l, a, n, f = debug.info(Detected, "slanf")
    warn("[projectsion] Detected located.")

    local targetDebug = (typeof(REnv) == "table" and REnv.debug) or debug
    local origDebugInfo
    if targetDebug and targetDebug.info then
        origDebugInfo = hookfunction(targetDebug.info, newcclosure(function(fn, fmt, ...)
            if fn == Detected and fmt == "slanf" then return s, l, a, n, f end
            return origDebugInfo(fn, fmt, ...)
        end))
    end

    hookfunction(Detected, newcclosure(function(...)
        return coroutine.yield(coroutine.running())
    end))

    local Kill = filtergc("function", {
        Constants = { "Kill", "Variables", "Process" }, IgnoreExecutor = true,
    }, true)
    if Kill then
        warn("[projectsion] Kill located.")
        hookfunction(Kill, newcclosure(function(...) end))
    end

    local Log = filtergc("function", {
        Constants = { "Log", "Logs", "LogMessage" }, IgnoreExecutor = true,
    }, true)
    if Log then
        warn("[projectsion] Log located.")
        hookfunction(Log, newcclosure(function(...) end))
    end

    setthreadidentity(2)
    for _, v in getgc(true) do
        if typeof(v) == "table" then
            unfreezeTable(v)
            local dk = rawget(v, "Detected")
            local kk = rawget(v, "Kill")
            local lk = rawget(v, "Log")
            if dk ~= nil then
                pcall(rawset, v, "Detected", function() return false end)
            end
            if typeof(dk) == "function" and dk ~= Detected then
                pcall(hookfunction, dk, function(...) return true end)
            end
            if typeof(kk) == "function" and kk ~= Kill then
                pcall(hookfunction, kk, function(...) end)
            end
            if typeof(lk) == "function" and lk ~= Log then
                pcall(hookfunction, lk, function(...) end)
            end
        end
    end
    setthreadidentity(7)
    return true
end

task.delay(1.5, function()
    local ok = hiadonis()
    if not ok then
        task.delay(3, function()
            local retry = hiadonis()
            warn("[projectsion] Adonis bypass " .. (retry and "active (retry)." or "failed — check constants."))
        end)
    else
        warn("[projectsion] Adonis bypass active.")
    end
end)