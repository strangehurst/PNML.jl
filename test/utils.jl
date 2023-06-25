using PNML, ..TestUtils, JET
import EzXML
using PNML: Maybe, getfirst, firstchild, allchildren

@testset "getfirst iteratible" begin
    v = [string(i) for i in 1:9]
    @test_call getfirst(==("3"), v)
    @test "3" == @inferred Maybe{String} getfirst(==("3"), v)
    @test nothing === @inferred Maybe{String} getfirst(==("33"), v)
end

@testset "ExXML" begin
    @test_throws ArgumentError xmlroot("")
    @test_throws "empty XML string" xmlroot("")
    # This kills the testset. Macros cannot throw?
    #@test_throws( ArgumentError, xml"")

    @test_throws MethodError EzXML.namespace(nothing)
end

 @testset "getfirst XMLNode" begin
    node = xml"""<test>
        <a name="a1"/>
        <a name="a2"/>
        <a name="a3"/>
        <c name="c1"/>
        <c name="c2"/>
    </test>
    """
    @test_call target_modules=target_modules firstchild("a", node)
    @test_call EzXML.nodename(firstchild("a", node))
    @test EzXML.nodename(firstchild("a", node)) == "a"
    @test firstchild("a", node)["name"] == "a1"
    @test firstchild("b", node) === nothing
    @test EzXML.nodename(firstchild("c", node)) == "c"

    @test_call target_modules=target_modules allchildren("a", node)
    @test map(c->c["name"], @inferred(allchildren("a", node))) == ["a1", "a2", "a3"]
end
