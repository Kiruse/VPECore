push!(LOAD_PATH, "$(@__DIR__)/..")
using Test
using VPECore

const TransformT = Transform2D{Transform2D, Float64}

function test_transform2d_scenegraph()
    parent = TransformT()
    c1 = TransformT(parent)
    c2 = TransformT(parent)
    c1_1 = TransformT(c1)
    c1_2 = TransformT(c1)
    
    @assert parent.parent == nothing
    @assert length(parent.children) == 2
    @assert c1 ∈ parent.children && c2 ∈ parent.children
    
    @assert c1.parent == parent
    @assert length(c1.children) == 2
    @assert c1_1 ∈ c1.children && c1_2 ∈ c1.children
    
    @assert c2.parent == parent
    @assert length(c2.children) == 0
    
    @assert c1_1.parent == c1
    @assert length(c1_1.children) == 0
    
    @assert c1_2.parent == c1
    @assert length(c1_2.children) == 0
    
    return true
end

function test_transform2d_update()
    world  = World{TransformT}()
    parent = TransformT(Vector2(10, 10), deg2rad(45), Vector2(2, 2))
    c1   = TransformT(parent, Vector2(5,  0),           0, Vector2(1, 1))
    c1_1 = TransformT(c1,     Vector2(0, -5),           0, Vector2(1, 1))
    c1_2 = TransformT(c1,     Vector2(5,  0), deg2rad(45), Vector2(1, 1))
    push!(world, parent)
    tick!(world, 0.0)
    
    trig45 = cos(deg2rad(45))
    expected_parent_mat = Matrix3([
         2trig45 2trig45 10;
        -2trig45 2trig45 10;
               0       0   1
    ])
    @assert isapprox(parent.obj2world, expected_parent_mat, atol=1e-5)
    
    expected_c1_mat = Matrix3([
        1 0 5;
        0 1 0;
        0 0 1
    ])
    expected_c1_mat = expected_parent_mat * expected_c1_mat
    @assert isapprox(c1.obj2world, expected_c1_mat, atol=1e-5)
    
    expected_c1_1_mat = Matrix3([
        1 0  0;
        0 1 -5;
        0 0  1
    ])
    expected_c1_1_mat = expected_c1_mat * expected_c1_1_mat
    @assert isapprox(c1_1.obj2world, expected_c1_1_mat, atol=1e-5)
    
    expected_c1_2_mat = Matrix3([
         trig45 trig45 5;
        -trig45 trig45 0;
              0      0 1
    ])
    expected_c1_2_mat = expected_c1_mat * expected_c1_2_mat
    @assert isapprox(c1_2.obj2world, expected_c1_2_mat, atol=1e-5)
    
    return true
end

function test_transform2d_transform()
    t1 = TransformT()
    rad45 = deg2rad(45)
    translate!(t1, Vector2(50, 0))
    rotate!(   t1, deg2rad(45))
    scale!(    t1, Vector2(1.5, 1.5))
    @assert isapprox(t1.location, Vector2{Float64}(50, 0), atol=1e-5)
    @assert isapprox(t1.rotation, rad45, atol=1e-5)
    @assert isapprox(t1.scale,    Vector2{Float64}(1.5, 1.5), atol=1e-5)
    
    update!(t1)
    sinr = sin(deg2rad(45))
    cosr = cos(deg2rad(45))
    expected = Matrix3{Float64}(1, 0, 0, 0, 1, 0, 50, 0, 1) * Matrix3{Float64}(cosr, -sinr, 0, sinr, cosr, 0, 0, 0, 1) * Matrix3{Float64}(1.5, 0, 0, 0, 1.5, 0, 0, 0, 1)
    @assert isapprox(t1.obj2world, expected, atol=1e-5)
    return true
end

@testset "VPECore Transform" begin
    @test test_transform2d_scenegraph()
    @test test_transform2d_update()
    @test test_transform2d_transform()
end
