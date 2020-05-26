export AbstractTransform, Transform2D, World
export obj2world, world2obj, translate!, rotate!, scale!, parent!, deparent!, getcustomdata, transformfamily, transformparam
export translationmatrix3, rotationmatrix3, scalematrix3, transformmatrix3

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
Transform2D{T}(parent::Optional{AbstractTransform2D{T}}) where T = Transform2D{T}(parent, Vector2(0, 0), T(0), Vector2(1, 1))
Transform2D{T}() where T = Transform2D{T}(nothing)
Transform2D() = Transform2D{Float64}()

@generate_properties Transform2D begin
    @set location = (self.dirty = true; self.location = value)
    @set rotation = (self.dirty = true; self.rotation = value)
    @set scale    = (self.dirty = true; self.scale    = value)
end

translate!(transform::AbstractTransform, offset)  = transform.location = transform.location .+ offset
scale!(    transform::AbstractTransform, scale)   = transform.scale = transform.scale .* scale
rotate!(transform::AbstractTransform2D, rotation) = transform.rotation += rotation

function change!(transform::Transform2D{T}, location::Vector2{T}, rotation::T, scale::Vector2{T}) where T
    transform.location = location
    transform.rotation = rotation
    transform.scale    = scale
    transform.dirty = true
    transform
end
function change!(transform::Transform2D{T}; location::Optional{Vector2{T}} = nothing, rotation::Optional{T} = nothing, scale::Optional{Vector2{T}} = nothing) where T
    if location !== nothing || rotation !== nothing || scale !== nothing
        transform.dirty = true
        
        if location !== nothing transform.location = location end
        if rotation !== nothing transform.rotation = rotation end
        if scale    !== nothing transform.scale    = scale    end
    end
end

function parent!(child::AbstractTransform, parent::AbstractTransform)
    if child == parent
        throw(ArgumentError("Cannot parent transform to itself"))
    end
    
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

function update!(transform::Transform2D{T}, parentmat::Matrix3{T} = idmat(Matrix3{T}), forceupdate::Bool = false) where T
    if transform.dirty || forceupdate
        transform.obj2world = parentmat * transformmatrix3(T, transform.location, transform.rotation, transform.scale)
        transform.world2obj = inv(transform.obj2world)
        
        forceupdate     = true
        transform.dirty = false
    end
    @threads for child ∈ transform.children
        update!(child, transform.obj2world, forceupdate)
    end
    transform
end

obj2world(transform::AbstractTransform) = transform.obj2world
world2obj(transform::AbstractTransform) = transform.world2obj

translationmatrix3(T::Type{<:Real}, location) = Matrix3{T}(1, 0, 0, 0, 1, 0, location[1], location[2], 1)
rotationmatrix3(   T::Type{<:Real}, rotation) = (sinr = sin(rotation); cosr = cos(rotation); Matrix3{T}(cosr, -sinr, 0, sinr, cosr, 0, 0, 0, 1))
scalematrix3(      T::Type{<:Real}, scale)    = Matrix3{T}(scale[1], 0, 0, 0, scale[2], 0, 0, 0, 1)

function transformmatrix3(T::Type{<:Real}, location, rotation, scale)
    lx, ly = location
    sx, sy = scale
    cosr = cos(rotation)
    sinr = sin(rotation)
    Matrix3{T}(sx*cosr, -sx*sinr, 0, sy*sinr, sy*cosr, 0, lx, ly, 1)
end


getcustomdata(::Type, _) = nothing
getcustomdata(::Type{T}, inst::T) where T = inst
getcustomdata(T::Type, transform::AbstractTransform) = getcustomdata(T, transform.customdata)

transformfamily(::Type{<:Transform2D}) = Transform2D
transformparam( ::Type{<:AbstractTransform{T}}) where T = T


function Base.show(io::IO, transform::AbstractTransform)
    write(io, "$(typeof(transform))(loc: $(transform.location), rot: $(transform.rotation), scale: $(transform.scale)")
    if transform.dirty
        write(io, ", dirty")
    end
    write(io, ")")
end
