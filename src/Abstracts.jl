export AbstractTransform, AbstractTransform2D, AbstractWorld

abstract type AbstractTransform{E, T<:Number} end
abstract type AbstractTransform2D{E, T} <: AbstractTransform{E, T} end
abstract type AbstractWorld{T} end
