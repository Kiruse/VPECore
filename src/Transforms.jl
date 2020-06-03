######################################################################
# Abstract scene graph through transforms.
# A transform may be associated with arbitrary "customdata" in order to link back to a higher level abstraction.
# TODO: 

export Transform2D
export obj2world, world2obj, translate!, rotate!, scale!, parent!, deparent!
export transformof, transformfamily, transformchaintype, transformparam
export translationmatrix3, rotationmatrix3, scalematrix3, transformmatrix3

mutable struct Transform2D{E, T} <: AbstractTransform2D{E, T}
    world::Optional{<:AbstractWorld{<:E}}
    parent::Optional{E}
    children::Vector{E}
    location::Vector2{T}
    rotation::T
    scale::Vector2{T}
    dirty::Bool
    obj2world::Matrix3{T}
    world2obj::Matrix3{T}
end # Transform2D
function Transform2D{E, T}(parent::E, location::Vector2, rotation::Number, scale::Vector2) where {E, T}
    parent!(Transform2D{E, T}(nothing, nothing, Vector(), Vector2{T}(location...), T(rotation), Vector2{T}(scale...), true, idmat(Matrix3{T}), idmat(Matrix3{T})), parent)
end
Transform2D{E, T}(parent::Nothing, location::Vector2, rotation::Number, scale::Vector2) where {E, T} = Transform2D{E, T}(nothing, nothing, Vector(), location, rotation, scale, true, idmat(Matrix3{T}), idmat(Matrix3{T}))
Transform2D{E, T}(location::Vector2, rotation::Number, scale::Vector2) where {E, T} = Transform2D{E, T}(nothing, location, rotation, scale)
Transform2D{E, T}(parent::Optional{AbstractTransform2D{E, T}}) where {E, T} = Transform2D{E, T}(parent, Vector2(0, 0), T(0), Vector2(1, 1))
Transform2D{E, T}() where {E, T} = Transform2D{E, T}(nothing)

@generate_properties Transform2D begin
    @set location = (self.dirty = true; self.location = value)
    @set rotation = (self.dirty = true; self.rotation = value)
    @set scale    = (self.dirty = true; self.scale    = value)
end

translate!(transform::AbstractTransform, offset)  = transform.location = transform.location .+ offset
scale!(    transform::AbstractTransform, scale)   = transform.scale = transform.scale .* scale
rotate!(transform::AbstractTransform2D, rotation) = transform.rotation += rotation

function change!(transform::Transform2D{E, T}, location::Vector2{T}, rotation::T, scale::Vector2{T}) where {E, T}
    transform.location = location
    transform.rotation = rotation
    transform.scale    = scale
    transform.dirty = true
    transform
end
function change!(transform::Transform2D{E, T}; location::Optional{Vector2{T}} = nothing, rotation::Optional{T} = nothing, scale::Optional{Vector2{T}} = nothing) where {E, T}
    if location !== nothing || rotation !== nothing || scale !== nothing
        transform.dirty = true
        
        if location !== nothing transform.location = location end
        if rotation !== nothing transform.rotation = rotation end
        if scale    !== nothing transform.scale    = scale    end
    end
end

parent!(child, parent) = do_parent!(child, parent)
function do_parent!(child, parent)
    childtf  = transformof(child)
    parenttf = transformof(parent)
    
    oldworld = childtf.world
    emitevents = childtf.world != parenttf.world
    
    res = parent_internal!(child, parent)
    if res
        if childtf.world !== nothing && childtf ∈ childtf.world.roots
            rem_root(childtf.world, child)
            emit(childtf.world, :DemoteRoot, child)
        elseif emitevents
            emit(oldworld, :RemoveChild, child)
            emit(childtf.world, :AddChild, child)
            for child ∈ childtf.children
                setworld!(child, childtf.world)
            end
        end
    end
    child
end
function parent_internal!(child, parent)
    if child == parent
        throw(ArgumentError("Cannot parent transform to itself"))
    end
    
    childtf  = transformof(child)
    parenttf = transformof(parent)
    
    if childtf.parent != parent
        deparent_internal!(child)
        push!(parenttf.children, child)
        childtf.parent = parent
        childtf.world  = parenttf.world
        childtf.dirty  = true
        true
    else
        false
    end
end
deparent!(child) = do_deparent!(child)
function do_deparent!(child)
    tf = transformof(child)
    if tf.parent !== nothing
        oldworld = child.world
        deparent_internal!(child)
        emit(oldworld, :RemoveChild, child)
        foreach(unworld!, tf.children)
    end
    child
end
function deparent_internal!(child)
    childtf = transformof(child)
    
    if childtf.parent !== nothing
        deleteat!(childtf.parent.children, findfirst(curr->curr==child, childtf.parent.children))
        childtf.parent = nothing
        childtf.dirty  = true
    end
    
    child
end
function setworld!(elem, world::AbstractWorld)
    transform = transformof(elem)
    transform.world = world
    emit(world, :AddChild, elem)
    for child ∈ transform.children
        setworld!(child, world)
    end
end
function unworld!(elem)
    transform = transformof(elem)
    world = transform.world
    transform.world = nothing
    emit(world, :RemoveChild, elem)
    foreach(unworld!, transform.children)
end

function update!(transform::Transform2D{E, T}, parentmat::Matrix3{T} = idmat(Matrix3{T}), forceupdate::Bool = false) where {E, T}
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

obj2world(x) = obj2world(transformof(x))
world2obj(x) = world2obj(transformof(x))
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


transformof(x) = nothing
transformof(x::AbstractTransform) = x
transformfamily(::Type{<:Transform2D}) = Transform2D
transformchaintype(::Type{<:AbstractTransform{E}}) where E = E
transformparam(::Type{<:AbstractTransform{E, T}}) where {E, T} = T


function Base.show(io::IO, transform::AbstractTransform)
    write(io, "$(typeof(transform))(loc: $(transform.location), rot: $(transform.rotation), scale: $(transform.scale)")
    if transform.dirty
        write(io, ", dirty")
    end
    write(io, ")")
end
