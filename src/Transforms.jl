export AbstractTransform, Transform2D, World
export update, obj2world, world2obj, translate!, rotate!, scale!, parent!, deparent!, getcustomdata, transformfamily, transformparam

abstract type AbstractTransform{T<:Number} end
abstract type AbstractTransform2D{T} <: AbstractTransform{T} end

mutable struct Transform2D{T} <: AbstractTransform2D{T}
    parent::Optional{<:AbstractTransform2D{T}}
    children::Vector{AbstractTransform2D{T}}
    location::Vector2{T}
    rotation::T
    scale::Vector2{T}
    dirty::Bool
    obj2world::Matrix3{T}
    world2obj::Matrix3{T}
    customdata::Any
end # Transform2D
function Transform2D{T}(parent::AbstractTransform2D, location::Vector2, rotation::Number, scale::Vector2) where T
    parent!(Transform2D{T}(nothing, Vector(), Vector2{T}(location...), T(rotation), Vector2{T}(scale...), true, idmat(Matrix3{T}), idmat(Matrix3{T}), nothing), parent)
end
Transform2D{T}(parent::Nothing, location::Vector2, rotation::Number, scale::Vector2) where T = Transform2D{T}(nothing, Vector(), location, rotation, scale, true, idmat(Matrix3{T}), idmat(Matrix3{T}), nothing)
Transform2D{T}(location::Vector2, rotation::Number, scale::Vector2) where T = Transform2D{T}(nothing, location, rotation, scale)
Transform2D{T}(parent::Optional{AbstractTransform2D}) where T = Transform2D{T}(parent, Vector2(0, 0), T(0), Vector2(1, 1))
Transform2D{T}() where T = Transform2D{T}(nothing)

translate!(transform::AbstractTransform, offset)  = (transform.dirty = true; transform.location .+= offset)
scale!(    transform::AbstractTransform, scale)   = (transform.dirty = true; transform.scale = transform.scale .* scale)
rotate!(transform::AbstractTransform2D, rotation) = (transform.dirty = true; transform.rotation += rotation)

function parent!(child::AbstractTransform, parent::AbstractTransform)
    if child.parent != parent
        deparent!(child)
        push!(parent.children, child)
        child.parent = parent
        child.dirty  = true
    end
    child
end
function deparent!(child::AbstractTransform)
    if child.parent !== nothing
        deleteat!(child.parent.children, findfirst(curr->curr==child, child.parent.children))
        child.parent = nothing
        child.dirty  = true
    end
    child
end

function update(transform::Transform2D{T}, parentmat::Matrix3{T} = idmat(Matrix3{T}), forceupdate::Bool = false) where T
    if transform.dirty || forceupdate
        l = transform.location
        sx, sy = transform.scale
        cosr = cos(transform.rotation)
        sinr = sin(transform.rotation)
        
        transform.obj2world = parentmat * Matrix3{T}([
             sx*cosr sx*sinr  l[1];
            -sy*sinr sy*cosr  l[2];
                0       0       1
        ])
        transform.world2obj = inv(transform.obj2world)
        
        forceupdate     = true
        transform.dirty = false
    end
    @threads for child ∈ transform.children
        update(child, transform.obj2world, forceupdate)
    end
    nothing
end

obj2world(transform::AbstractTransform) = transform.obj2world
world2obj(transform::AbstractTransform) = transform.world2obj


getcustomdata(::Type, _) = nothing
getcustomdata(::Type{T}, inst::T) where T = inst
getcustomdata(T::Type, transform::AbstractTransform) = getcustomdata(T, transform.customdata)

transformfamily(::Type{<:Transform2D}) = Transform2D
transformparam( ::Type{<:AbstractTransform{T}}) where T = T