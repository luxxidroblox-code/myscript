
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
    warn("[SannSunner] Detected something.")
    --[[warn(string.format(
        "[kacung adonis] Detected info:\n  source: %s\n  line: %s\n  args: %s\n  name: %s\n  is_vararg: %s",
        tostring(s), tostring(l), tostring(a), tostring(n), tostring(f)
    ))]]

    local origDebugInfo = hookfunction(REnv.debug.info, newcclosure(function(fn, fmt, ...)
        if fn == Detected and fmt == "slanf" then
            return s, l, a, n, f
        end
        return origDebugInfo(fn, fmt, ...)
    end))

    hookfunction(Detected, newcclosure(function(action, info, noCrash)
        return coroutine.yield(coroutine.running())
    end))

    return true
end

task.delay(0.5, function()
    local ok = hiadonis()
    if ok then
        print("adonis kontol")
    end
end)