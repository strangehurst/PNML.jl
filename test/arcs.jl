using PNML, JET, XMLDict

include("TestUtils.jl")
using .TestUtils

#---------------------------------------------
# ARC
#---------------------------------------------
PNML.CONFIG[].warn_on_unclaimed = true

function insc_xml(pntd)
    if ishighlevel(pntd)
        """<hlinscription>
            <text>6</text>
            <structure>
                <numberof>
                    <subterm>
                        <numberconstant value="6"> <positive/> </numberconstant>
                    </subterm>
                    <subterm> <dotconstant/> </subterm>
                </numberof>
            </structure>
           </hlinscription>"""
    else
        """<inscription> <text>6</text> </inscription>"""
    end
end
#! arc needs :place1 for adjacent place
function pl_node(pntd, net, netdata, netsets)
    node = if ishighlevel(pntd)
        xml"""
            <place id="place1">
            <name> <text>with text</text> </name>
            <type><structure><dot/></structure></type>
            <hlinitialMarking>
                <text>101</text>
                <structure>
                    <numberof>
                        <subterm>
                            <numberconstant value="11"><positive/></numberconstant>
                        </subterm>
                        <subterm><dotconstant/></subterm>
                    </numberof>
                </structure>
            </hlinitialMarking>
            </place>
            """
    else
        xml"""
            <place id="place1">
            <initialMarking> <text>1</text> </initialMarking>
            </place>
            """
    end
    pl = parse_place(node, pntd, net)
    push!(PNML.place_idset(netsets), pid(pl))
    PNML.placedict(netdata)[pid(pl)] = pl
end

#! arc needs :transition1 for adjacent transition
function tr_node(pntd, net, netdata, netsets)
    node = xml"""<transition id="transition1" />"""
    tr = parse_transition(node, pntd, net)
    push!(PNML.transition_idset(netsets), pid(tr))
    PNML.transitiondict(netdata)[pid(tr)] = tr
end

println("\nARC\n")
@testset "arc $pntd" for pntd in PnmlTypes.all_nettypes()
    # PNML.CONFIG[].warn_on_unclaimed = true
    net = make_net(pntd, :arc_net)
    netsets = PNML.PnmlNetKeys()
    pl_node(pntd, net, netdata(net), netsets)
    tr_node(pntd, net, netdata(net), netsets)

     node = xmlnode("""
      <arc source="transition1" target="place1" id="arc1">
        <name> <text>Some arc</text> </name>
        $(insc_xml(pntd))
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
        <graphics/>
        <toolspecific tool=":test" version="1.0.0" />
      </arc>
    """)

    a = @test_logs(match_mode=:any,
                  (:info, "add PnmlLabel :unknown to :arc1"),
                  parse_arc(node, pntd, net))
    @test typeof(a) <: Arc
    @test pid(a) === :arc1
    @test name(a) == "Some arc"
    @test has_graphics(a)
    @test_call inscription(a)
    #@show a inscription(a)(NamedTuple())
    if ishighlevel(pntd) # assumes storttype of dot
        @test PNML.cardinality(inscription(a)(NamedTuple())) == 6
    else
        @test inscription(a)(NamedTuple()) == 6
    end
    @test PNML.has_tools(a) == true
end

@testset "arc unknown label for $pntd" for pntd in PnmlTypes.all_nettypes()
    net = make_net(pntd, :arc_unknown)
    netsets = PNML.PnmlNetKeys()
    pl_node(pntd, net, netdata(net), netsets)
    tr_node(pntd, net, netdata(net), netsets)
    node = xmlnode("""
      <arc source="transition1" target="place1" id="arc1">
        <name> <text>Some arc</text> </name>
        $insc_xml
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
        <graphics/>
        <toolspecific tool=":test" version="1.0.0" />
      </arc>
    """)
   a = @test_logs(match_mode=:any,
                  (:info, "add PnmlLabel :unknown to :arc1"),
                  parse_arc(node, pntd, net))
end
