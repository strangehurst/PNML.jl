using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, getfirst, allchildren

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

    @test_throws MethodError namespace(nothing)
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

    #@test_call target_modules=(PNML,) getfirst("a", node)
    @test_call target_modules=target_modules getfirst("a", node)
    @test_call nodename(getfirst("a", node))
    @test nodename(getfirst("a", node)) == "a"
    @test getfirst("a", node)["name"] == "a1"
    @test getfirst("b", node) === nothing
    @test nodename(getfirst("c", node)) == "c"

    a = @test_call target_modules=target_modules allchildren("a", node)
    @test map(c->c["name"], @inferred(allchildren("a", node))) == ["a1", "a2", "a3"]
end
