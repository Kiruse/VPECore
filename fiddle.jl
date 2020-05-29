push!(LOAD_PATH, @__DIR__)

using VPECore
import VPECore: absolute, relative, resolvemeasure

measure = Measure2(absolute(42), relative(.5))
println(measure)
