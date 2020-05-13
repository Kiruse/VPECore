export hassignature

function hassignature(fn, argtypes::Vararg{<:Type})
    sig = Tuple{typeof(fn), argtypes...}
    for method ∈ methods(fn)
        if sig <: method.sig
            return true
        end
    end
    return false
end
