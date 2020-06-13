push!(LOAD_PATH, "$(@__DIR__)/../")

using Test
using VPECore


@testset "DictUtils" begin
    dict = Dict{String, Any}(
        "bool" => false,
        "int" => 42,
        "float" => 69.69,
        "string" => "lie",
        )
    
    @test                    requirekeys(dict, "bool", "int", "float", "string")
    @test_throws FormatError requirekey( dict, "nonexistent")
    @test                    requiretypes(dict, "bool" => Bool, "int" => Int, "float" => AbstractFloat, "string" => String)
    @test_throws FormatError requiretype( dict, "bool", AbstractFloat)
    
    @test getentry(dict, "bool",   true)    == false
    @test getentry(dict, "int",    420)     == 42
    @test getentry(dict, "float",  420)     == 69.69
    @test getentry(dict, "string", "cake")  == "lie"
    @test getentry(dict, "nonexistent", 42) == 42
    
    @test                    requirebool(  dict, "bool") == false
    @test_throws FormatError requirebool(  dict, "int")
    @test                    requireint(   dict, "int") == 42
    @test_throws FormatError requireint(   dict, "string")
    @test                    requirefloat( dict, "float") == 69.69
    @test_throws FormatError requirefloat( dict, "string")
    @test                    requirestring(dict, "string") == "lie"
    @test_throws FormatError requirestring(dict, "float")
end
