export Measure, Measure2, Measure3, AbstractMeasureInterpret, MeasureValue

abstract type AbstractMeasureInterpret end
struct AbsoluteMeasure <: AbstractMeasureInterpret end
struct RelativeMeasure <: AbstractMeasureInterpret end

struct MeasureValue{T<:Real, I<:AbstractMeasureInterpret}
    value::T
end

struct Measure{N, T}
    values::SVector{N, MeasureValue{T}}
end
Measure{N, T}(values::Vararg{MeasureValue{T}, N}) where {N, T} = Measure{N, T}(SVector{N, MeasureValue{T}}(values...))
Measure{N, T}(values::Vararg{MeasureValue{<:Real}, N}) where {N, T} = Measure{N, T}(SVector((MeasureValue{T, measurevalueinterpret(value)}(value.value) for value ∈ values)...))
function Measure{N}(values::Vararg{MeasureValue, N}) where N
    T = promote_type(measurevalueparam.(values)...)
    gen = (MeasureValue{T, measurevalueinterpret(value)}(value.value) for value ∈ values)
    Measure{N, T}(SVector{N, MeasureValue{T}}(gen...))
end

const Measure2{T} = Measure{2, T}
const Measure3{T} = Measure{3, T}

absolute(value) = MeasureValue{typeof(value), AbsoluteMeasure}(value)
relative(value) = MeasureValue{typeof(value), RelativeMeasure}(value)

resolvemeasure(value::MeasureValue{T, AbsoluteMeasure}, _::Real) where T = value.value
resolvemeasure(value::MeasureValue{T, RelativeMeasure}, parentmeasure::Real) where T = value.value * parentmeasure
resolvemeasure(measure::Measure{N}, parentmeasures) where N = tuple((resolvemeasure(measure.values[i], parentmeasures[i]) for i ∈ 1:N)...)

measurevalueparam(::MeasureValue{T}) where T = T
measurevalueinterpret(::MeasureValue{T, I}) where {T, I} = I

Base.length(measure::Measure{N}) where N = N
Base.getindex(measure::Measure, i) = measure.values[i]
Base.setindex!(measure::Measure{N, T}, v::MeasureValue{T}, i) where {N, T} = v
Base.firstindex(measure::Measure) = 1
Base.lastindex(measure::Measure{N}) where N = N

Base.show(io::IO, value::MeasureValue{T, AbsoluteMeasure}) where T = write(io, "absolute($(value.value))")
Base.show(io::IO, value::MeasureValue{T, RelativeMeasure}) where T = write(io, "relative($(value.value))")
function Base.show(io::IO, measure::Measure{N, T}) where {N, T}
    len = length(measure.values)
    write(io, "$T[")
    for (i, value) ∈ enumerate(measure.values)
        show(value)
        if i < len
            write(io, ", ")
        end
    end
    write(io, ']')
end

Base.convert(M::Type{Measure{N, T}}, measure::Measure{N}) where {N, T} = M(measure.values...)
Base.convert(M::Type{Measure{N, I}}, measure::Measure{N, F}) where {N, I<:Integer, F<:AbstractFloat} = M((MeasureValue{I, measurevalueinterpret(value)}(floor(I, value.value)) for value ∈ measure.values)...)
