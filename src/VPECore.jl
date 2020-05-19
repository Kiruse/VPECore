module VPECore
using Base.Threads
using LinearAlgebra
using StaticArrays

export tick!, update!, change!

include("./SigUtils.jl")

include("./AABBs.jl")
include("./EventDispatcher.jl")
include("./LinAl.jl")
include("./LoopUtils.jl")
include("./Tickability.jl")
include("./Transforms.jl")
include("./Worlds.jl")

end # module VPECore
