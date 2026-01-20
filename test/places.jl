using PNML, JET, XMLDict

include("TestUtils.jl")
using .TestUtils

#---------------------------------------------
# PLACE
#---------------------------------------------

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(!ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <initialMarking>
            <text>100</text>
            <!-- standard does not use/allow structure here
            <structure><numberconstant value="100"><integer/></numberconstant></structure>
            -->
        </initialMarking>
        </place>
    """
    ctx = PNML.parser_context()

    placetype = SortType("XXX", NamedSortRef(:natural), nothing, nothing, ctx.ddict)

    n  = parse_place(node, pntd; parse_context=ctx)::Place
    pntd isa PnmlCoreNet &&
        @test_opt target_modules=t_modules broken=true parse_place(node, pntd; parse_context=ctx)
    @test_call target_modules=t_modules parse_place(node, pntd; parse_context=ctx)
    @test @inferred(pid(n)) === :place1
    @test @inferred(name(n)) == "with text"
    @test_call initial_marking(n)
    #@show pntd, initial_marking(n)
    @test initial_marking(n)::Number == 100
    @test PNML.get_label(n, :nosuchlabel) == nothing
    @test PNML.has_tools(n) == false
end

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <type><structure><dot/></structure></type>
        <hlinitialMarking>
            <text>101</text>
            <structure>
            <numberof>
                <subterm><numberconstant value="101"><positive/></numberconstant></subterm>
                <subterm><dotconstant/></subterm>
            </numberof>
            </structure>
        </hlinitialMarking>
        </place>
    """
    ctx = PNML.parser_context()

    n = parse_place(node, pntd; parse_context=ctx)::Place
    @test_call target_modules=t_modules parse_place(node, pntd; parse_context=ctx)

    @test @inferred(pid(n)) === :place1
    @test @inferred(name(n)) == "with text"
    @test_call target_modules=t_modules initial_marking(n)
    #@show pntd, initial_marking(n)
    @test PNML.cardinality(initial_marking(n)::PnmlMultiset) == 101
    @test PNML.get_label(n, :nosuchlabel) == nothing
end

@testset "place unknown label $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
    node = xml"""
        <place id="place1">
        <type><structure><dot/></structure></type>
        <hlinitialMarking>
            <text>101</text>
            <structure>
            <numberof>
                <subterm><numberconstant value="101"><positive/></numberconstant></subterm>
                <subterm><dotconstant/></subterm>
            </numberof>
            </structure>
        </hlinitialMarking>
        <somelabel1 a="text">
            <another b="more" />
        </somelabel1>
        <somelabel2 c="value" />
        </place>
    """
    ctx = PNML.parser_context()
    n = @test_logs((:info, "add PnmlLabel :somelabel1 to :place1"),
                   (:info, "add PnmlLabel :somelabel2 to :place1"),
                    parse_place(node, pntd; parse_context=ctx)::Place)
    @test pid(n) === :place1
    @test name(n) == ""
    @test PNML.get_label(n, :nosuchlabel) == nothing
    #@show labels(n)
    #@show keys(labels(n))
    #@show labels(n)[:somelabel1]
    #@show labels(n)[:somelabel2]
    #@show elements(labels(n)[:somelabel1])
    @test elements(labels(n)[:somelabel1])[:a] == "text"
    @test elements(labels(n)[:somelabel1])["another"][:b] == "more"
    #@show elements(labels(n)[:somelabel2])
    @test elements(labels(n)[:somelabel2])[:c] == "value"
end

#---------------------------------------------
# REFERENCE PLACE
#---------------------------------------------

@testset "ref Place $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referencePlace id="rp1" ref="p1">
        <name>
            <text>refPlace name</text>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    </referencePlace>"""

    parse_context = PNML.parser_context()
    n = parse_refPlace(node, pntd; parse_context)::RefPlace
    @test pid(n) === :rp1
    @test PNML.refid(n) === :p1
    @test PNML.get_label(n, :nosuchlabel) == nothing
end

@testset "ref Place $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referencePlace id="rp1" ref="p1">
        <name>
            <text>refPlace name</text>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <somelabel2 c="value" />
    </referencePlace>"""

    parse_context = PNML.parser_context()
    n = @test_logs((:info, "add PnmlLabel :somelabel2 to :rp1"),
            parse_refPlace(node, pntd; parse_context)::RefPlace)
    @test pid(n) === :rp1
    @test PNML.refid(n) === :p1
    @test elements(labels(n)[:somelabel2])[:c] == "value"
    @test PNML.get_label(n, :nosuchlabel) == nothing
end
