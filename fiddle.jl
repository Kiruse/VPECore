push!(LOAD_PATH, @__DIR__)

using VPECore

mutable struct MyTimer
    time::Float64
end
MyTimer() = MyTimer(0)
VPECore.tick!(timer::MyTimer, dt::AbstractFloat) = timer.time += dt

world = World{Transform2D{Float64}}()
timer = MyTimer()
push!(world, timer)

t_start = time()
frameloop() do dt
    tick!(world, dt)
    time() - t_start < 5
end
