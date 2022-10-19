using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, getfirst

@testset "getfirst iteratible" begin
    v = [string(i) for i in 1:9]
    @test_call getfirst(==("3"), v)
    @test "3" == @inferred Maybe{String} getfirst(==("3"), v)
    @test nothing === @inferred Maybe{String} getfirst(==("33"), v)
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
    @test_call nodename(getfirst("a", node))
    @test nodename(getfirst("a", node)) == "a"
    @test getfirst("b", node) === nothing
    @test nodename(getfirst("c", node)) == "c"
end
