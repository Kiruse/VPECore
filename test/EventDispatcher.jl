push!(LOAD_PATH, "$(@__DIR__)/../")

using Test
using VPECore

struct Dispatcher
    listeners::ListenersType
    
    Dispatcher() = new(ListenersType())
end
VPECore.eventlisteners(disp::Dispatcher) = disp.listeners

mutable struct Listener1
    truth::Bool
end

mutable struct Listener2
    val::Int
end

onbasic(_...) = error("Invalid listener call")
function onbasic(listener::Listener1, number::Integer)
    listener.truth = number == 420
end
function onbasic(listener::Listener2, number::Integer)
    listener.val += number + 42
end

function test_basic()
    disp = Dispatcher()
    
    listener1 = Listener1(false)
    listener2 = Listener2(69)
    
    hook!(onbasic, disp, :event, listener1)
    hook!(onbasic, disp, :event, listener2)
    emit(disp, :event, 420)
    
    @assert listener1.truth "Unexpected Listener1.truth value ($(listener1.truth))"
    @assert listener2.val == 531 "Unexpected Listener2.val value ($(listener2.val)), should be 531"
    true
end


function ononce(listener::Listener2)
    listener.val += 69
end

function test_once()
    disp = Dispatcher()
    
    listener1 = Listener2(42)
    listener2 = Listener2(420)
    
    hookonce!(ononce, disp, :event, listener1)
    hookonce!(ononce, disp, :event, listener2)
    emit(disp, :event)
    emit(disp, :event)
    
    @assert listener1.val == 111 "Unexpected listener2.val value ($(listener1.val)), should be 111"
    @assert listener2.val == 489 "Unexpected listener2.val value ($(listener2.val)), should be 489"
    true
end

@testset "EventDispatcher" begin
    @test test_basic()
    @test test_once()
end
