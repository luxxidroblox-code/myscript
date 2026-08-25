local function hiadonis()
    local Detected = filtergc("function", {
        Constants = { " - On Xbox", " - On mobile", "_" },
        IgnoreExecutor = true,
    }, true)

    if not Detected then
        warn("[kacung adonis] filtergc miss Adonis not loaded yet or constants changed")
        return false
    end

    local s, l, a, n, f = debug.info(Detected, "slanf")
    warn("[projectsion] Detected something.")

    local targetDebug = (typeof(REnv) == "table" and REnv.debug) or debug
    local origDebugInfo
    
    if targetDebug and targetDebug.info then
        origDebugInfo = hookfunction(targetDebug.info, newcclosure(function(fn, fmt, ...)
            if fn == Detected and fmt == "slanf" then
                return s, l, a, n, f
            end
            return origDebugInfo(fn, fmt, ...)
        end))
    end

    hookfunction(Detected, newcclosure(function(...)
        return coroutine.yield(coroutine.running())
    end))

    return true
end

task.delay(0.5, function()
    local ok = hiadonis()
    if ok then
        print("adonis bypass applied successfully")
    end
end)
