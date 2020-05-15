export AABB
export bounds

struct AABB{N, T<:Real}
    min::SVector{N, T}
    max::SVector{N, T}
end
AABB{T}(xmin, ymin, zmin, xmax, ymax, zmax) where T = AABB{3, T}(Vector3{T}(xmin, ymin, zmin), Vector3{T}(xmax, ymax, zmax))
AABB{T}(xmin, ymin, xmax, ymax) where T = AABB{2, T}(Vector2{T}(xmin, ymin), Vector2{T}(xmax, ymax))
AABB(comps::Vararg{<:Real}) = (comps = promote(comps...); AABB{typeof(comps[1])}(comps...))

function bounds(::Type{SVector{D, T}}, verts) where {D, T<:Real}
    if isempty(verts) return nothing end
    
    currmin = MVector{D, T}((typemax(T) for _ ∈ 1:D)...)
    currmax = MVector{D, T}((typemin(T) for _ ∈ 1:D)...)
    for vert ∈ verts
        for i ∈ 1:D
            currmin[i] = min(currmin[i], vert[i])
            currmax[i] = max(currmax[i], vert[i])
        end
    end
    AABB(SVector(currmin), SVector(currmax))
end
bounds(verts::AbstractArray{T}) where {D, T<:SVector{D, <:Real}} = bounds(T, verts)
bounds(verts::Vararg{T})        where {D, T<:SVector{D, <:Real}} = bounds(T, verts)
