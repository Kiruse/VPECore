export EventDispatcher, ListenersType
export hook!, hookonce!, unhook!, emit

const ListenersType = Dict{Symbol, Vector}

abstract type EventDispatcherness end
struct IsEventDispatcher <: EventDispatcherness end
struct NoEventDispatcher <: EventDispatcherness end

struct EventDispatcher
    listeners::ListenersType
end
EventDispatcher() = EventDispatcher(Dict())

@generated function eventdispatcherness(::Type{T}) where T
    if hassignature(eventlisteners, T)
        :(IsEventDispatcher())
    else
        :(NoEventDispatcher())
    end
end
eventdispatcherness(::Type{EventDispatcher}) = IsEventDispatcher()

eventlisteners(disp::EventDispatcher) = disp.listeners

"""
Hook the specified listener. Whether the same listener may be hooked (and called) more than once depends on the
implementation.
"""
function hook!(listener, disp, sym::Symbol, args...; kwargs...)
    listeners = eventlisteners(disp)
    if !haskey(listeners, sym)
        listeners[sym] = Any[]
    end
    push!(listeners[sym], (listener, args, kwargs))
    disp
end

"""
Hook the specified listener for a single call. Afterwards, automaticaly `unhook!`.
"""
function hookonce!(listener, disp, sym::Symbol, largs...; lkwargs...)
    wrapper = (args...; kwargs...) -> begin
        unhook!(disp, sym, wrapper)
        listener(args...; kwargs...)
    end
    hook!((wrapper, largs, lkwargs), disp, sym)
end

"""
Remove a previously registered hooked event listener.
As anonymous functions are unique `unhook` cannot be used with the `unhook!(<...>) do <...>` syntax.
"""
function unhook!(disp, sym::Symbol, listener)
    listeners = eventlisteners(disp)
    if haskey(listeners, sym)
        idx = findfirst((curr)->curr[1] == listener, listeners[sym])
        if idx != nothing
            deleteat!(listeners[sym], idx)
        end
    end
    disp
end

"""
Emit an event on the given dispatcher with provided args and keyword args.
"""
emit(disp, sym::Symbol, args...; kwargs...) = emit(eventdispatcherness(typeof(disp)), disp, sym, args...; kwargs...)

emit(::NoEventDispatcher, disp, sym::Symbol, args...; kwargs...) = nothing

function emit(::IsEventDispatcher, disp, sym::Symbol, args...; kwargs...)
    listeners = eventlisteners(disp)
    results = Vector(undef, length(listeners))
    if haskey(listeners, sym)
        for (listener, largs, lkwargs) ∈ listeners[sym]
            push!(results, listener(largs..., args...; lkwargs..., kwargs...))
        end
    end
    results
end
