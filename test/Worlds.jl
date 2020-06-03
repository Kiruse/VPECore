push!(LOAD_PATH, "$(@__DIR__)/..")
using Test
using VPECore
using StaticArrays

const TransformT = Transform2D{Transform2D, Float64}

struct Abstraction
    transform::Transform2D{Abstraction, Float64}
end
Abstraction() = Abstraction(Transform2D{Abstraction, Float64}())
VPECore.transformof(x::Abstraction) = x.transform

function test_scenegraph()
    world = World{TransformT}()
    
    tf1 = TransformT()
    translate!(tf1, (200, 50))
    push!(world, tf1)
    
    tf2 = TransformT()
    translate!(tf2, (-100, 50))
    parent!(tf2, tf1)
    
    tick!(world, 0.0)
    
    m1 = SMatrix{3, 3, Float64}(1, 0, 0, 0, 1, 0, 200,  50, 1)
    m2 = SMatrix{3, 3, Float64}(1, 0, 0, 0, 1, 0, 100, 100, 1)
    
    @assert tf1.dirty == false && tf2.dirty == false
    @assert isapprox(obj2world(tf1), m1)
    @assert isapprox(obj2world(tf2), m2)
    
    return true
end

function test_events_basic()
    world = World{TransformT}()
    
    flag_addroot1    = false
    flag_addroot2    = false
    flag_addroot3    = false
    flag_removeroot  = false
    flag_addchild1   = false
    flag_addchild2   = false
    flag_removechild = false
    flag_demoteroot  = false
    
    root1 = TransformT()
    root2 = TransformT()
    root3 = TransformT()
    
    hook!(world, :AddRoot) do root
        if root == root1
            @assert !flag_addroot1 "root1 added twice"
            flag_addroot1 = true
        elseif root == root2
            @assert !flag_addroot2 "root2 added twice"
            flag_addroot2 = true
        elseif root == root3
            @assert !flag_addroot3 "root3 added twice"
            flag_addroot3 = true
        else
            error("Unexpected root added")
        end
    end
    hook!(world, :RemoveRoot) do root
        @assert root == root3 "Unexpected root removed"
        @assert !flag_removeroot "root3 removed twice"
        flag_removeroot = true
    end
    hook!(world, :AddChild) do child
        if child == child1
            @assert !flag_addchild1 "child1 added twice"
            flag_addchild1 = true
        elseif child == child2
            @assert !flag_addchild2 "child2 added twice"
            flag_addchild2 = true
        else
            error("Unexpected child added")
        end
    end
    hook!(world, :RemoveChild) do child
        @assert child == child1 "Unexpected child removed"
        @assert !flag_removechild "child removed twice"
        flag_removechild = true
    end
    hook!(world, :DemoteRoot) do root
        @assert root == root1 "Unexpected root demoted"
        @assert !flag_demoteroot
        flag_demoteroot = true
    end
    
    push!(world, root1)   # Should trigger :AddRoot
    push!(world, root2)   # Should trigger :AddRoot
    push!(world, root3)   # Should trigger :AddRoot
    delete!(world, root3) # Should trigger :RemoveRoot
    
    child1 = TransformT()
    child2 = TransformT()
    parent!(child1, root2)  # Should trigger :AddChild
    parent!(child2, root2)  # Should trigger :AddChild
    parent!(child1, child2) # Should NOT trigger another :AddChild
    deparent!(child1)       # Should trigger :RemoveChild
    parent!(root1, child2)  # Should trigger :DemoteRoot
    
    @assert flag_addroot1
    @assert flag_addroot2
    @assert flag_addroot3
    @assert flag_removeroot
    @assert flag_addchild1
    @assert flag_addchild2
    @assert flag_removechild
    @assert flag_demoteroot
    true
end

function test_events_recursive()
    world = World{TransformT}()
    
    flag_addroot   = false
    flag_addchild1 = false
    flag_addchild2 = false
    flag_removeroot   = false
    flag_removechild1 = false
    flag_removechild2 = false
    
    root1  = TransformT()
    child1 = TransformT()
    child2 = TransformT()
    parent!(child1, root1)
    parent!(child2, root1)
    
    hook!(world, :AddRoot) do root
        @assert root == root1 "Unexpected root added"
        @assert !flag_addroot "Root added twice"
        flag_addroot = true
    end
    hook!(world, :AddChild) do child
        if child == child1
            @assert !flag_addchild1 "child1 added twice"
            flag_addchild1 = true
        elseif child == child2
            @assert !flag_addchild2 "child2 added twice"
            flag_addchild2 = true
        else
            error("Unexpected child added")
        end
    end
    hook!(world, :RemoveRoot) do root
        @assert root == root1 "Unexpected root removed"
        @assert !flag_removeroot "Root removed twice"
        flag_removeroot = true
    end
    hook!(world, :RemoveChild) do child
        if child == child1
            @assert !flag_removechild1 "child1 removed twice"
            flag_removechild1 = true
        elseif child == child2
            @assert !flag_removechild2 "child2 removed twice"
            flag_removechild2 = true
        else
            error("Unexpected child removed")
        end
    end
    
    push!(world, root1)
    delete!(world, root1)
    
    @assert flag_addroot
    @assert flag_removeroot
    @assert flag_addchild1
    @assert flag_addchild2
    @assert flag_removechild1
    @assert flag_removechild2
    true
end

function test_abstraction()
    world = World{Abstraction}()
    
    flag_addroot   = false
    flag_addchild1 = false
    flag_addchild2 = false
    flag_removeroot   = false
    flag_removechild1 = false
    flag_removechild2 = false
    
    root1  = Abstraction()
    child1 = Abstraction()
    child2 = Abstraction()
    parent!(child1, root1)
    parent!(child2, root1)
    
    hook!(world, :AddRoot) do root
        @assert root == root1 "Unexpected root added"
        @assert !flag_addroot "Root added twice"
        flag_addroot = true
    end
    hook!(world, :AddChild) do child
        if child == child1
            @assert !flag_addchild1 "child1 added twice"
            flag_addchild1 = true
        elseif child == child2
            @assert !flag_addchild2 "child2 added twice"
            flag_addchild2 = true
        else
            error("Unexpected child added")
        end
    end
    hook!(world, :RemoveRoot) do root
        @assert root == root1 "Unexpected root removed"
        @assert !flag_removeroot "Root removed twice"
        flag_removeroot = true
    end
    hook!(world, :RemoveChild) do child
        if child == child1
            @assert !flag_removechild1 "child1 removed twice"
            flag_removechild1 = true
        elseif child == child2
            @assert !flag_removechild2 "child2 removed twice"
            flag_removechild2 = true
        else
            error("Unexpected child removed")
        end
    end
    
    push!(world, root1)
    delete!(world, root1)
    
    @assert flag_addroot
    @assert flag_removeroot
    @assert flag_addchild1
    @assert flag_addchild2
    @assert flag_removechild1
    @assert flag_removechild2
    true
end

@testset "VPECore World" begin
    @test test_scenegraph()
    @test test_events_basic()
    @test test_events_recursive()
    @test test_abstraction()
end
