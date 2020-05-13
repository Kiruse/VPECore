export World

struct World{T<:AbstractTransform}
    roots::Vector{T}
    tickables::Set
end # World
World{T}() where T = World{T}(Vector(), Set())

Base.push!(  world::World{T}, transform::T) where {T<:AbstractTransform} = (push!(  world.roots, transform); world)
Base.delete!(world::World{T}, transform::T) where {T<:AbstractTransform} = (delete!(world.roots, transform); world)

Base.push!(  world::World, tickable::T)  where T = push_tickable(tickability(T), world, tickable)
Base.delete!(world::World, tickable::T)  where T = del_tickable( tickability(T), world, tickable)
push_tickable(::Tickable, world::World, tickable) = (push!(world.tickables, tickable); world)
del_tickable( ::Tickable, world::World, tickable) = (delete!(world.tickables, tickable); world)

function tick!(world::World, dt::AbstractFloat)
    @threads for root ∈ world.roots
        update(root)
    end
    foreach(tickable->tick!(tickable, dt), world.tickables)
    world
end
