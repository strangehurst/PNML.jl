@testset "ID registry" begin
    reg = PNML.IDRegistry()
    PNML.register_id!(reg, "p")
    @test PNML.isregistered(reg, "p")
    @test PNML.isregistered(reg, :p)
    PNML.reset_registry!(reg)
    @test !PNML.isregistered(reg, "p")
    @test !PNML.isregistered(reg, :p)

    @test_logs (:warn,"ID 'p' already registered") PNML.duplicate_id_action(:p)
    @test_logs (:warn,"ID 'p' already registered") PNML.duplicate_id_action(:p; action=:warn)
    @test_throws ErrorException PNML.duplicate_id_action(:p; action=:error)
    @test PNML.duplicate_id_action(:p; action=:bogus) === nothing
end

header("GETFIRST")
@testset "getfirst iteratible" begin
    v = [string(i) for i in 1:9]
    @test PNML.getfirst(==("3"), v) == "3"
    @test PNML.getfirst(==("33"), v) === nothing
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
    @test nodename(PNML.getfirst("a", node)) == "a"
    @test PNML.getfirst("b", node) === nothing
    @test nodename(PNML.getfirst("c", node)) == "c"
end
