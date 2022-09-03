using PNML, EzXML, ..TestUtils, JET
using PNML: Place, Transition, Arc, 
  pid, marking, condition, inscription

header("NODES")

@testset "place" begin
    node = xml"""
      <place id="place1">
        <name> <text>Some place</text> </name>
        <initialMarking> <text>100</text> </initialMarking>
      </place>
    """
    @test_call parse_node(node; reg = PNML.IDRegistry())
    n = @inferred Place parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: Place
    @test_call PNML.has_xml(n)
    @test !PNML.has_xml(n)
    @test @inferred(pid(n)) === :place1
    @test @inferred PNML.has_name(n)
    @test @inferred(PNML.name(n)) == "Some place"
    @test_call marking(n)
    @test marking(n) == 100
end

@testset "no text" begin
    node = xml"""
      <place id="place1">
        <name> <text>Some place</text> </name>
        <initialMarking>100</initialMarking>
      </place>
    """
    @test_call parse_node(node; reg = PNML.IDRegistry())
    n = @inferred Place parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: Place
    @test_call PNML.has_xml(n)
    @test !PNML.has_xml(n)
    @test @inferred(pid(n)) === :place1
    @test @inferred PNML.has_name(n)
    @test @inferred(PNML.name(n)) == "Some place"
    @test_call marking(n)
    @test marking(n) == 100
end

@testset "transition" begin
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <structure>100</structure> </condition>
      </transition>
    """
    n = @inferred Transition parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.Transition
    @test !PNML.has_xml(n)
    @test pid(n) === :transition1
    @test PNML.has_name(n)
    @test PNML.name(n) == "Some transition"
    @test condition(n) == 100

    node = xml"""<transition id ="t1"> <condition><text>test</text></condition></transition>"""
    @test_throws ErrorException parse_node(node; reg = PNML.IDRegistry())
    node = xml"""<transition id ="t2"> <condition/> </transition>"""
    @test_throws ErrorException parse_node(node; reg = PNML.IDRegistry())
    node = xml"""<transition id ="t3"> <condition><structure/></condition> </transition>"""
    t = parse_node(node; reg = PNML.IDRegistry())
    @test t isa PNML.Transition
    @test_call condition(t)
    @test condition(t) === true
end

@testset "arc" begin
    node = xml"""
      <arc source="transition1" target="place1" id="arc1">
        <name> <text>Some arc</text> </name>
        <inscription> <text>6</text> </inscription>
      </arc>
    """
    n = @inferred Arc parse_node(node; reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.Arc
    @test !PNML.has_xml(n)
    @test pid(n) === :arc1
    @test PNML.has_name(n)
    @test PNML.name(n) == "Some arc"
    @test_call inscription(n)
    @show PNML.inscription(n)
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
