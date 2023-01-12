using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, xmlnode, labels, firstpage, first_net,
    PnmlNet, Page,
    arcs, places, transitions, refplaces, reftransitions,
    place_ids, transition_ids, arc_ids, refplace_ids, reftransition_ids,
    flatten_pages!, nets

@testset "pages" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
            <page id="page1">
                <place id="p1"/>
                <transition id ="t1"/>
                <arc id="a11" source="p1" target="t1"/>
                <arc id="a12" source="t1" target="rp1"/>
                <referencePlace id="rp1" ref="p2"/>
                <page id="page11">
                    <place id="p11" />
                    <page id="page111">
                        <place id="p111" />
                    </page>
                </page>
                <page id="page12" />
                <page id="page13" />
                <page id="page14" />
            </page>
            <page id="page2">
            <place id="p2"/>
            <transition id ="t2"/>
                <arc id="a21" source="t2" target="p2"/>
                <arc id="a22" source="t2" target="rp2"/>
                <referencePlace id="rp2" ref="p3111"/>
                <referenceTransition id="rt2" ref="t3"/>
            </page>
            <page id="page3">
                <place id="p3"/>
                <transition id ="t3"/>
                <arc id="a31" source="t3" target="p4"/>
                <page id="page31">
                    <place id="p31"/>
                    <transition id ="t31"/>
                    <arc id="a311" source="t31" target="p1"/>
                    <page id="page311">
                        <place id="p311" />
                        <page id="page3111">
                            <place id="p3111" />
                        </page>
                    </page>
                    <page id="page312" />
                    <page id="page313" />
                    <page id="page314" />
                </page>
            </page>
        </net>
    </pnml>
    """
    model = @inferred parse_str(str)
    #@show typeof(nets(model))
    # The nets of a model is an array of abstract types so not infred.er
    net = first_net(model)

    @test net isa PnmlNet
    @test typeof(net) <: PnmlNet
    @test typeof(@inferred(firstpage(net))) <: Page

    @test_broken arc_ids(net)           == [:a11, :a12, :a21, :a22, :a31, :a311]
    @test_broken place_ids(net)         == [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
    @test_broken transition_ids(net)    == [:t1, :t2, :t3, :t31]
    @test refplace_ids(net)      == [:rp1, :rp2]
    @test reftransition_ids(net) == [:rt2]

    #@show arc_ids(net)
    #@show place_ids(net)
    #@show transition_ids(net)
    #@show refplace_ids(net)
    #@show reftransition_ids(net)

    @test arcs(net) !== nothing
    @test places(net) !== nothing
    @test transitions(net) !== nothing
    @test refplaces(net) !== nothing
    @test reftransitions(net) !== nothing

    @testset "flatten" begin
        @inferred flatten_pages!(net)

        expected_a = [:a11, :a12, :a21, :a22, :a31, :a311]
        expected_p = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
        expected_t = [:t1, :t2, :t3, :t31]
        expected_rt = [] # removed by flatten
        expected_rp = [] # removed by flatten

        @test arc_ids(net) == expected_a
        @test arc_ids(firstpage(net)) == expected_a
        @test arc_ids(net) == arc_ids(firstpage(net))
        @test_call arc_ids(net)
        @test_call arc_ids(firstpage(net))

        for a ∈ expected_a
            @test a ∈ arc_ids(net)
        end

        @test place_ids(net) == expected_p
        @test place_ids(firstpage(net)) == expected_p
        @test place_ids(net) == place_ids(firstpage(net))
        @test_call place_ids(net)
        @test_call place_ids(firstpage(net))

        for p ∈ expected_p
            @test p ∈ place_ids(net)
        end

        @test transition_ids(net) == expected_t
        @test transition_ids(firstpage(net)) == expected_t
        @test transition_ids(net) == transition_ids(firstpage(net))
        @test_call transition_ids(net)
        @test_call transition_ids(firstpage(net))

        for t ∈ expected_t
            @test t ∈ transition_ids(net)
        end

        @test reftransition_ids(net) == expected_rt
        @test reftransition_ids(firstpage(net)) == expected_rt
        @test reftransition_ids(net) == reftransition_ids(firstpage(net))
        @test_call reftransition_ids(net)
        @test_call reftransition_ids(firstpage(net))

        for rt ∈ expected_rt
            @test rt ∈ reftransition_ids(net)
        end

        @test refplace_ids(net) == expected_rp
        @test refplace_ids(firstpage(net)) == expected_rp
        @test refplace_ids(net) == refplace_ids(firstpage(net))
        @test_call refplace_ids(net)
        @test_call refplace_ids(firstpage(net))

        for rp ∈ expected_rp
            @test rp ∈ refplace_ids(net)
        end
    end
end # pages
