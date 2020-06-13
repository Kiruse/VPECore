export requirekey, requirekeys, requiretype, requiretypes, getentry, requirebool, requireint, requirefloat, requirestring

function requirekey(dict::Dict{K}, key::K) where K
    if !haskey(dict, key)
        throw(FormatError("Key \"$key\" not found"))
    end
    true
end
function requirekeys(dict::Dict{K1}, keys::Vararg{K2} where {K2<:K1}) where K1
    for key ∈ keys
        requirekey(dict, key)
    end
    true
end
function requiretype(dict::Dict{K}, key::K, ::Type{T}) where {K, T}
    requirekey(dict, key)
    if !isa(dict[key], T)
        throw(FormatError("$(dict[key]) ($key) is not a $T"))
    end
    true
end
function requiretypes(dict::Dict{K1}, pairs::Vararg{Pair{K2, <:Type} where {K2<:K1}}) where K1
    for pair ∈ pairs
        requiretype(dict, pair.first, pair.second)
    end
    true
end

function getentry(dict::Dict{K}, key::K, default = nothing) where K
    if !haskey(dict, key)
        default
    else
        dict[key]
    end
end

function requirebool(dict::Dict{K}, key::K) where K
    requiretype(dict, key, Bool)
    dict[key]::Bool
end
function requireint(dict::Dict{K}, key::K) where K
    requiretype(dict, key, Integer)
    dict[key]::Integer
end
function requirefloat(dict::Dict{K}, key::K) where K
    requiretype(dict, key, AbstractFloat)
    dict[key]::AbstractFloat
end
function requirestring(dict::Dict{K}, key::K) where K
    requiretype(dict, key, AbstractString)
    dict[key]::AbstractString
end
