header("NODES")

@testset "place" begin
    node = xml"""
      <place id="place1">
        <name> <text>Some place</text> </name>
        <initialMarking> <text>100</text> </initialMarking>
      </place>
    """
    n = parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.Place
    @test !PNML.has_xml(n)
    @test pid(n) === :place1
    @test PNML.has_name(n)
    @test PNML.name(n) == "Some place"
    @test PNML.marking(n) == 100
end

@testset "transition" begin
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>100</text> </condition>
      </transition>
    """
    n = parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.Transition
    @test !PNML.has_xml(n)
    @test pid(n) === :transition1
    @test PNML.has_name(n)
    @test PNML.name(n) == "Some transition"
    @test PNML.condition(n) == 100
end
 
@testset "arc" begin
    node = xml"""
      <arc source="transition1" target="place1" id="arc1">
        <name> <text>Some arc</text> </name>
        <inscription> <text>6</text> </inscription>
      </arc>
    """
    n = parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.Arc
    @test !PNML.has_xml(n)
    @test pid(n) === :arc1
    @test PNML.has_name(n)
    @test PNML.name(n) == "Some arc"
    @test PNML.inscription(n) == 6
end


@testset "ref Trans" begin
    node = xml"""
        <referenceTransition id="rt1" ref="t1"/>
    """
    n = parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.RefTransition
    @test !PNML.has_xml(n)
    @test pid(n) === :rt1
    @test n.ref === :t1
end

@testset "ref Place" begin
    n1 = (node = xml"""
    <referencePlace id="rp2" ref="rp1"/>
    """,
    id="rp2", ref="rp1" )
    n2 = (node = xml"""
    <referencePlace id="rp1" ref="Sync1">
        <graphics>
          <position x="734.5" y="41.5"/>
          <dimension x="40.0" y="40.0"/>
        </graphics>
    </referencePlace>
    """,
    id="rp1", ref="Sync1")
    @testset for s in [n1, n2]
        n = parse_node(s.node; reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.RefPlace
        @test !PNML.has_xml(n)
        @test typeof(n.id) == Symbol
        @test typeof(n.ref) == Symbol
        @test n.id === Symbol(s.id)
        @test n.ref === Symbol(s.ref)
    end
end
