module VPECore
using Base.Threads
using LinearAlgebra
using StaticArrays
using GetSetProp

export tick!, update!, change!

include("./Errors.jl")
include("./Abstracts.jl")
include("./SigUtils.jl")
include("./EventDispatcher.jl")

include("./AABBs.jl")
include("./DictUtils.jl")
include("./LinAl.jl")
include("./LoopUtils.jl")
include("./Measures.jl")
include("./Tickability.jl")
include("./Transforms.jl")
include("./Worlds.jl")

end # module VPECore
