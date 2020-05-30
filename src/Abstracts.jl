export AbstractTransform, AbstractTransform2D, AbstractWorld

abstract type AbstractTransform{T<:Number} end
abstract type AbstractTransform2D{T} <: AbstractTransform{T} end
abstract type AbstractWorld{T<:AbstractTransform} end