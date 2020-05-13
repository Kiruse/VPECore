export Tickability, Tickable, NotTickable, tickability

abstract type Tickability end
struct Tickable <: Tickability end
struct NotTickable <: Tickability end

@generated function tickability(::Type{T}) where T
    if hassignature(tick!, T, AbstractFloat)
        :(Tickable())
    else
        :(NotTickable())
    end
end
