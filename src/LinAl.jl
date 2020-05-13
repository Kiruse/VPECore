export Vector2, Vector3, Vector4, Matrix2, Matrix3, Matrix4
export idmat

const Vector2{T} = SVector{2, T}
const Vector3{T} = SVector{3, T}
const Vector4{T} = SVector{4, T}
const Matrix2{T} = SMatrix{2, 2, T}
const Matrix3{T} = SMatrix{3, 3, T}
const Matrix4{T} = SMatrix{4, 4, T}
const Optional{T} = Union{Nothing, T}

idmat(T::Type{<:SMatrix{D, D}}) where D = T(I)
