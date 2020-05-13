export frameloop

function frameloop(callback)
    t0 = time_ns()
    dt = 0.0
    while callback(dt) != false
        t1 = time_ns()
        dt = max(t1 - t0, 0) / 1e9 # In the extremely rare event time_ns wraps back around to 0 after 5.8 years
        t0 = t1
    end
end
