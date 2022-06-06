using PNML: firstpage

header("PAGES")
@testset "pages" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
            <page id="page1">
                <place id="p1"/>
                <transition id ="t1"/>
                <arc id="a1" source="p1" target="t1"/>
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
                <arc id="a2" source="t2" target="p2"/>
                <arc id="a22" source="t2" target="rp2"/>
                <referencePlace id="rp2" ref="p3"/>
                <referenceTransition id="rt2" ref="t3"/>
            </page>
            <page id="page3">
                <place id="p3"/>
                <transition id ="t3"/>
                <arc id="a3" source="t3" target="p4"/>
                <page id="page4">
                    <place id="p4"/>
                    <transition id ="t4"/>
                    <arc id="a4" source="t4" target="p1"/>
                    <page id="page41">
                        <place id="p41" />
                        <page id="page411">
                            <place id="p411" />
                        </page>
                    </page>
                    <page id="page42" />
                    <page id="page43" />
                    <page id="page44" />
                </page>
            </page>
        </net>
    </pnml>
    """
    model = parse_str(str)
    net = PNML.first_net(model)

    @test net isa PNML.PnmlNet
    @test typeof(net) <: PNML.PnmlNet
    @test typeof(firstpage(net)) <: PNML.Page

    printnode(net; label="\n----------------\n Multiple nested pages")

    @testset "flatten" begin
        PNML.flatten_pages!(net)
        printnode(net; label="\n----------------\n Flattened & dereferenced to 1 page")

        #@show PNML.arc_ids(net)
        #@show PNML.place_ids(net)
        #@show PNML.transition_ids(net)
        #@show PNML.refplace_ids(net)
        #@show PNML.reftransition_ids(net)
        #println()

        expected_a = [:a1, :a12, :a2, :a22, :a3, :a4]
        @test PNML.arc_ids(net) == expected_a
        @test PNML.arc_ids(firstpage(net)) == expected_a
        @test PNML.arc_ids(net) == PNML.arc_ids(firstpage(net))
        @test_call PNML.arc_ids(net)
        @test_call PNML.arc_ids(firstpage(net))

        for a ∈ expected_a
            @test a ∈ PNML.arc_ids(net)
        end

        expected_p = [:p1, :p11, :p111, :p2, :p3, :p4, :p41, :p411]
        @test PNML.place_ids(net) == expected_p
        @test PNML.place_ids(firstpage(net)) == expected_p
        @test PNML.place_ids(net) == PNML.place_ids(firstpage(net))
        @test_call PNML.place_ids(net)
        @test_call PNML.place_ids(firstpage(net))

        for p ∈ expected_p
            @test p ∈ PNML.place_ids(net)
        end

        expected_t = [:t1, :t2, :t3, :t4]
        @test PNML.transition_ids(net) == expected_t
        @test PNML.transition_ids(firstpage(net)) == expected_t
        @test PNML.transition_ids(net) == PNML.transition_ids(firstpage(net))
        @test_call PNML.transition_ids(net)
        @test_call PNML.transition_ids(firstpage(net))

        for t ∈ expected_t
            @test t ∈ PNML.transition_ids(net)
        end

        expected_rt = []#:rt2]
        @test PNML.reftransition_ids(net) == expected_rt
        @test PNML.reftransition_ids(firstpage(net)) == expected_rt
        @test PNML.reftransition_ids(net) == PNML.reftransition_ids(firstpage(net))
        @test_call PNML.reftransition_ids(net)
        @test_call PNML.reftransition_ids(firstpage(net))

        for rt ∈ expected_rt
            @test rt ∈ PNML.reftransition_ids(net)
        end

        expected_rp = []#:rp1, :rp2]
        @test PNML.refplace_ids(net) == expected_rp
        @test PNML.refplace_ids(firstpage(net)) == expected_rp
        @test PNML.refplace_ids(net) == PNML.refplace_ids(firstpage(net))
        @test_call PNML.refplace_ids(net)
        @test_call PNML.refplace_ids(firstpage(net))

        for rp ∈ expected_rp
            @test rp ∈ PNML.refplace_ids(net)
        end
    end
end # pages
