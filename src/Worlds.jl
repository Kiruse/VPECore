export World

"""
The root of a scene graph. It stores both root transforms as well as arbitrary tickables. Tickables are `tick!`ed
whenever the world itself is `tick!`ed.

There are various events:
- :AddRoot, :RemoveRoot
- :DemoteRoot
- :AddChild, :RemoveChild

AddRoot and RemoveRoot should be self-explanatory. These events are emitted when adding or removing a transform from
the world's roots.

DemoteRoot is emitted when a root transform has been parented to another transform and consequentially removed from the
world's roots, but not the world itself.

AddChild and RemoveChild are emitted when a transform has been added to the world wholly anew or removed from it
entirely, respectively. They are *not* emitted when the transform is reparented within the same world.

All events receive only the transform in question. AddChild and RemoveChild do not receive the old and/or new parents as
this is not a concern of the World.

Developer's note: AddRoot and RemoveRoot are emitted directly within this file. The other events are emitted within Transforms.jl.
"""
struct World{T<:AbstractTransform} <: AbstractWorld{T}
    roots::Vector{T}
    tickables::Set
    listeners::ListenersType
end # World
World{T}() where T = World{T}(Vector(), Set(), ListenersType())
eventlisteners(world::World) = world.listeners
eventdispatcherness(::Type{World}) = IsEventDispatcher()

function Base.push!(world::World{T}, transform::T) where {T<:AbstractTransform}
    add_root(world, transform)
    transform.world = world
    emit(world, :AddRoot,    transform)
    world
end
function Base.delete!(world::World{T}, transform::T) where {T<:AbstractTransform}
    rem_root( world, transform)
    transform.world = nothing
    emit(world, :RemoveRoot, transform)
    world
end
add_root(world::World{T}, transform::T) where {T<:AbstractTransform} = push!(  world.roots, transform)
rem_root( world::World{T}, transform::T) where {T<:AbstractTransform} = delete!(world.roots, transform)

Base.push!(  world::World, tickable::T) where T = push_tickable(tickability(T), world, tickable)
Base.delete!(world::World, tickable::T) where T = del_tickable( tickability(T), world, tickable)
push_tickable(::Tickable, world::World, tickable) = (push!(world.tickables, tickable);   world)
del_tickable( ::Tickable, world::World, tickable) = (delete!(world.tickables, tickable); world)

function tick!(world::World, dt::AbstractFloat)
    @threads for root ∈ world.roots
        update!(root)
    end
    foreach(tickable->tick!(tickable, dt), world.tickables)
    world
end
