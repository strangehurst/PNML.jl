using PNML, EzXML, ..TestUtils, JET
using PNML: Place, Transition, Arc, RefPlace, RefTransition,
    has_xml, has_name, name,
    pid, marking, condition, inscription,
    has_graphics, graphics, has_name, name, has_label,
    parse_place, parse_transition, parse_arc, parse_refTransition, parse_refPlace

const pntd::PnmlType = PnmlCoreNet() # Default pntd

@testset "place" begin
    node = xml"""
      <place id="place1">
        <name> <text>with text</text> </name>
        <initialMarking> <text>100</text> </initialMarking>
      </place>
    """
    n  = parse_place(node, pntd, registry())
    #println("parse_place "); dump(n)

    @test parse_node(node, pntd, registry()) === nothing
    @test_logs (:warn, r"^Attempt to parse excluded tag") parse_node(node, pntd, registry())

    @test_call target_modules=target_modules parse_place(node, pntd, registry())

    @test pid(n) === :place1
    @test typeof(n) <: Place
    @test_call has_xml(n)
    @test !has_xml(n)
    @test @inferred(pid(n)) === :place1
    @test has_name(n)
    @test @inferred(name(n)) == "with text"
    @test_call marking(n)
    @test marking(n)() == 100
end

@testset "no marking text" begin
    node = xml"""
      <place id="place1">
        <name> <text>no marking text</text> </name>
        <initialMarking> 100 </initialMarking>
      </place>
    """
    @test_call target_modules = target_modules parse_place(node, PnmlCoreNet(), registry())
    n = parse_place(node, PnmlCoreNet(), registry())
    @test typeof(n) <: Place
    @test_call has_xml(n)
    @test !has_xml(n)
    @test @inferred(pid(n)) === :place1
    @test @inferred(has_name(n)) == true
    @test @inferred(name(n)) == "no marking text"
    @test_call marking(n)
    @test marking(n)() == 100
end

# <condition> introduced as High-Level in specification. We use it everywhere.
@testset "transition" begin
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>foo</text><structure>100</structure> </condition>
      </transition>
    """
    n = @inferred Transition parse_transition(node, PnmlCoreNet(), registry())
    @test typeof(n) <: Transition
    @test !has_xml(n)
    @test pid(n) === :transition1
    @test has_name(n)
    @test name(n) == "Some transition"
    @test condition(n) isa Bool #! define non-HL other's semantics.

    node = xml"""<transition id ="t1"> <condition><text>test</text></condition></transition>"""
    #@test_throws ErrorException parse_transition(node, pntd, registry())
    @test parse_transition(node, pntd, registry()) !== nothing
    node = xml"""<transition id ="t2"> <condition/> </transition>"""
    #@test_throws ErrorException parse_transition(node, pntd, registry())
    @test parse_transition(node, pntd, registry()) !== nothing
    node = xml"""<transition id ="t3"> <condition><structure/></condition> </transition>"""
    t = parse_transition(node, pntd, registry())
    @test t isa Transition
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
    n = @inferred Arc parse_arc(node, PnmlCoreNet(), registry())
    @test typeof(n) <: Arc
    @test !has_xml(n)
    @test pid(n) === :arc1
    @test has_name(n)
    @test name(n) == "Some arc"
    @test_call inscription(n)
    @test inscription(n) == 6
end

@testset "ref Trans" begin
    node = xml"""
        <referenceTransition id="rt1" ref="t1"/>
    """
    n = parse_refTransition(node, PnmlCoreNet(), registry())
    @test n isa RefTransition
    @test !has_xml(n)
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
        n = parse_refPlace(s.node, ContinuousNet(), registry())
        @test typeof(n) <: RefPlace
        @test !has_xml(n)
        @test typeof(n.id) == Symbol
        @test typeof(n.ref) == Symbol
        @test n.id === Symbol(s.id)
        @test n.ref === Symbol(s.ref)
    end
end
