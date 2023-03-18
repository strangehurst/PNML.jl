using PNML, EzXML, ..TestUtils, JET, AbstractTrees
using PNML: Maybe, tag, xmlnode, labels, firstpage, first_net, nettype,
    PnmlNet, Page, pages, pid,
    arc, arcs, place, places, transition, transitions,
    refplace, refplaces, reftransition, reftransitions,
    place_ids, transition_ids, arc_ids, refplace_ids, reftransition_ids,
    flatten_pages!, nets,
    place_type, transition_type, arc_type, refplace_type, reftransition_type,
    currentMarkings,
    arc_type, place_type, transition_type,
    condition_type, condition_value_type,
    sort_type,
    inscription_type, inscription_value_type,
    marking_type, marking_value_type, page_type, refplace_type, reftransition_type,
    rate_value_type,
    default_inscription,
    default_marking,
    default_sort,
    default_condition,
    default_term,
    default_one_term,
    default_zero_term,
    pnmlnet_type

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
    #@show typeof(model)
    @show typeof(nets(model))

    net = first_net(model) # The nets of a model not inferred.

    #AbstractTrees.print_tree(net);  println()

    @test net isa PnmlNet
    @test typeof(net) <: PnmlNet
    @test typeof(@inferred(firstpage(net))) <: Page

    @show arc_ids(net)
    @show collect(place_ids(net))
    @show transition_ids(net)
    @show refplace_ids(net)
    @show reftransition_ids(net)


    @testset "by pntd" begin

        type_funs = (
            arc_type,
            place_type,
            transition_type,
            condition_type,
            condition_value_type,
            sort_type,
            inscription_type,
            inscription_value_type,
            marking_type,
            marking_value_type,
            page_type,
            refplace_type,
            reftransition_type,
            rate_value_type,
            )

        def_funs = (
            default_inscription,
            default_marking,
            default_sort,
            default_condition,
            default_term,
            default_one_term,
            default_zero_term,
            )

            #println()
            for fun in type_funs
                #println()
                for pntd in values(PnmlTypeDefs.pnmltype_map)
                    #print("$fun($pntd) \t ")
                    #println(fun(pntd))
                    @test_opt fun(pntd)
                    @test_call fun(pntd)
                end
                #println()
            end
            #println()
            #println("###############################################")
            #println()
            for fun in type_funs
                #println()
                for pntd in values(PnmlTypeDefs.pnmltype_map)
                    pt = typeof(pntd)
                    #print("$fun($pt) \t ")
                    #println(fun(pt))
                    @test_opt fun(pt)
                    @test_call fun(pt)
                end
                #println()
            end
            #println()
    end

    @testset "x_types" begin
        @test arc_type(net) isa Type
        @test place_type(net) isa Type
        @test transition_type(net) isa Type
        @test condition_type(net) isa Type
        @test condition_value_type(net) isa Type
        @test sort_type(net) isa Type
        @test inscription_type(net) isa Type
        @test inscription_value_type(net) isa Type
        @test marking_type(net) isa Type
        @test marking_value_type(net) isa Type
        @test page_type(net) isa Type
        @test refplace_type(net) isa Type
        @test reftransition_type(net) isa Type
        @test rate_value_type(net) isa Type

        @test_call arc_type(net)
        @test_call place_type(net)
        @test_call transition_type(net)
        @test_call condition_type(net)
        @test_call condition_value_type(net)
        @test_call sort_type(net)
        @test_call inscription_type(net)
        @test_call inscription_value_type(net)
        @test_call marking_type(net)
        @test_call marking_value_type(net)
        @test_call page_type(net)
        @test_call refplace_type(net)
        @test_call reftransition_type(net)
        @test_call rate_value_type(net)

        @test_opt arc_type(net)
        @test_opt place_type(net)
        @test_opt transition_type(net)
        @test_opt condition_type(net)
        @test_opt condition_value_type(net)
        @test_opt sort_type(net)
        @test_opt inscription_type(net)
        @test_opt inscription_value_type(net)
        @test_opt marking_type(net)
        @test_opt marking_value_type(net)
        @test_opt page_type(net)
        @test_opt refplace_type(net)
        @test_opt reftransition_type(net)
        @test_opt rate_value_type(net)
    end

    exp_arc_ids           = [:a11, :a12, :a21, :a22, :a31, :a311]
    exp_place_ids         = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
    exp_transition_ids    = [:t1, :t2, :t3, :t31]
    exp_refplace_ids      = [:rp1, :rp2]
    exp_reftransition_ids = [:rt2]

    @test (sort ∘ collect)(@inferred(place_ids(net)))         == exp_place_ids
    @test (sort ∘ collect)(@inferred(arc_ids(net)))           == exp_arc_ids
    @test (sort ∘ collect)(@inferred(transition_ids(net)))    == exp_transition_ids
    @test (sort ∘ collect)(@inferred(refplace_ids(net)))      == exp_refplace_ids
    @test (sort ∘ collect)(@inferred(reftransition_ids(net))) == exp_reftransition_ids

    for aid in exp_arc_ids
    end
    for aid in exp_arc_ids
        #@show aid
        a = @inferred Maybe{arc_type(net)} arc(net, aid)
        #@show a
        @test !isnothing(a)
        #! Pages do not decend subpages!
        #!@test typeof(arc(net, aid)) === typeof(arc(firstpage(net), aid))
    end

    @test arcs(net) !== nothing
    @test places(net) !== nothing
    @test transitions(net) !== nothing
    @test refplaces(net) !== nothing
    @test reftransitions(net) !== nothing

    # @testset "pagetree" begin
    #     @show typeof(AbstractTrees.children(net))
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), place_ids(x), transition_ids(x), arc_ids(x), refplace_ids(x), reftransition_ids(x)
    #     end
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), typeof(x)
    #     end
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), place_type(nettype(x))
    #     end
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), transition_type(nettype(x))
    #     end
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), arc_type(nettype(x))
    #     end
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), refplace_type(nettype(x))
    #     end
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), reftransition_type(nettype(x))
    #     end
    #     println()
    #     for x in AbstractTrees.PreOrderDFS(net)
    #         @show pid(x), currentMarkings(x)
    #     end
    #     println()
    # end

    @testset "flatten" begin
        @inferred flatten_pages!(net)

        expected_a = [:a11, :a12, :a21, :a22, :a31, :a311]
        expected_p = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
        expected_t = [:t1, :t2, :t3, :t31]
        expected_rt = [] # removed by flatten
        expected_rp = [] # removed by flatten

        @test (sort ∘ collect)(arc_ids(net)) == expected_a
        @test (sort ∘ collect)(arc_ids(firstpage(net))) == expected_a
        @test arc_ids(net) == arc_ids(firstpage(net))
        @test_call target_modules=target_modules arc_ids(net)
        @test_call arc_ids(firstpage(net))

        for a ∈ expected_a
            @test a ∈ arc_ids(net)
        end

        @test (sort ∘ collect)(place_ids(net)) == expected_p
        @test (sort ∘ collect)(place_ids(firstpage(net))) == expected_p
        @test place_ids(net) == place_ids(firstpage(net))
        @test_call target_modules=target_modules place_ids(net)
        @test_call place_ids(firstpage(net))

        for p ∈ expected_p
            @test p ∈ place_ids(net)
        end

        @test (sort ∘ collect)(transition_ids(net)) == expected_t
        @test (sort ∘ collect)(transition_ids(firstpage(net))) == expected_t
        @test (sort ∘ collect)(transition_ids(net)) == (sort ∘ collect)(transition_ids(firstpage(net)))
        @test_call target_modules=target_modules transition_ids(net)
        @test_call transition_ids(firstpage(net))

        for t ∈ expected_t
            @test t ∈ transition_ids(net)
        end

        # After flatten reference nodes remain in the netdata dictonary.
        @test_broken (sort ∘ collect)(reftransition_ids(net)) == expected_rt
        @test (sort ∘ collect)(reftransition_ids(firstpage(net))) == expected_rt
        @test_broken (sort ∘ collect)(reftransition_ids(net)) == (sort ∘ collect)(reftransition_ids(firstpage(net)))
        @test_call target_modules=target_modules reftransition_ids(net)
        @test_call reftransition_ids(firstpage(net))

        for rt ∈ expected_rt
            @test rt ∈ reftransition_ids(net)
        end

        @test_broken (sort ∘ collect)(refplace_ids(net)) == expected_rp
        @test (sort ∘ collect)(refplace_ids(firstpage(net))) == expected_rp
        @test_broken (sort ∘ collect)(efplace_ids(net)) == (sort ∘ collect)(refplace_ids(firstpage(net)))
        @test_call target_modules=target_modules refplace_ids(net)
        @test_call refplace_ids(firstpage(net))

        for rp ∈ expected_rp
            @test rp ∈ refplace_ids(net)
        end
    end
end # pages
