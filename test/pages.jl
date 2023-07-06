using PNML, EzXML, ..TestUtils, JET, AbstractTrees, PrettyPrinting
using PNML:
    Maybe, tag, xmlnode, labels, firstpage, first_net, nettype,
    PnmlNet, Page, nets, pages, pid,
    arc, arcs, place, places, transition, transitions,
    refplace, refplaces, reftransition, reftransitions,
    place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset,
    flatten_pages!,
    place_type, transition_type, arc_type, refplace_type, reftransition_type,
    pnmlnet_type, page_type, arc_type, place_type, transition_type,
    condition_type, condition_value_type, inscription_type, inscription_value_type,
    marking_type, marking_value_type, refplace_type, reftransition_type,
    rate_value_type, sort_type,
    default_inscription, default_marking, default_sort, default_condition,
    default_term, default_one_term, default_zero_term,
    currentMarkings,
    netsets, netdata, page_idset, pagedict

const noisy::Bool = false

function verify_sets(net::PnmlNet)
    #println("\nverify sets and structure ++++++++++++++++++++++")
    @test typeof(page_idset(net))  == typeof(page_idset(firstpage(net)))
    @test typeof(arc_idset(net))  == typeof(arc_idset(firstpage(net)))
    @test typeof(place_idset(net)) == typeof(place_idset(firstpage(net)))
    @test typeof(transition_idset(net)) == typeof(transition_idset(firstpage(net)))
    @test typeof(refplace_idset(net))  == typeof(refplace_idset(firstpage(net)))
    @test typeof(reftransition_idset(net)) ==  typeof(reftransition_idset(firstpage(net)))

    #@show arc_idset(net)
    #@show place_idset(net)
    #@show transition_idset(net)
    #@show refplace_idset(net)
    #@show reftransition_idset(net)
    #println()

    #@show arc_idset(firstpage(net))
    #@show place_idset(firstpage(net))
    #@show transition_idset(firstpage(net))
    #@show refplace_idset(firstpage(net))
    #@show reftransition_idset(firstpage(net))
    #println()

    #@show netdata(net)
    #@show netdata(firstpage(net))
    @test netdata(net) === netdata(firstpage(net))
    #println()

    #@show netsets(net)
    #@show pid(firstpage(net))
    #@show netsets(firstpage(net))
    #println()

    for page in pages(net)
        #@show pid(page)
        #@show netsets(page)
        @test netdata(net) === netdata(page)
    end
    #println()

    for pageid in PNML.page_idset(net)
        #@show pageid
        #@show netsets(pagedict(net)[pageid])
        #@show netdata(pagedict(net)[pageid])
        @test netdata(net) === netdata(pagedict(net)[pageid])
    end
    #println()

    # net-level from PnmlNetData (OrderdDict) -- KeySet iterator.
    # page-level from PnmlNetKeys (OrderedSet) -- OrderedSet.
    #@show typeof(arc_idset(net))
    #println()
    #for page in pages(net)
    #    @show pid(page) (typeof ∘ values ∘ arc_idset)(page)  #(collect ∘ values ∘ arc_idset)(page)
    #end
    #println()
    #@show arc_idset(net)
    #@show setdiff(arc_idset(net), [arc_idset(p) for p in pages(net)]...)
    #println("+++++++++++++++++++++++++++++++++++++++++++++++++")
end

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
    #@show typeof(nets(model))
    net = first_net(model) # The nets of a model not inferred.

    @test net isa PnmlNet
    #@show typeof(firstpage(net))
    @test @inferred(firstpage(net)) isa Page

    #println()
    #PNML.pagetree(net)
    #println()
    #AbstractTrees.print_tree(net)
    #println()

    verify_sets(net)
    # @show arc_idset(net)
    # @show place_idset(net)
    # @show transition_idset(net)
    # @show refplace_idset(net)
    # @show reftransition_idset(net)
    # println()
    # @show arc_idset(firstpage(net))
    # @show place_idset(firstpage(net))
    # @show transition_idset(firstpage(net))
    # @show refplace_idset(firstpage(net))
    # @show reftransition_idset(firstpage(net))
    # println()

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

    @test (sort ∘ collect)(@inferred(place_idset(net)))         == exp_place_ids
    @test (sort ∘ collect)(@inferred(arc_idset(net)))           == exp_arc_ids
    @test (sort ∘ collect)(@inferred(transition_idset(net)))    == exp_transition_ids
    @test (sort ∘ collect)(@inferred(refplace_idset(net)))      == exp_refplace_ids
    @test (sort ∘ collect)(@inferred(reftransition_idset(net))) == exp_reftransition_ids

    for arcid in exp_arc_ids
    end
    for arcid in exp_arc_ids
        a = @inferred Maybe{arc_type(net)} arc(net, arcid)
        @test !isnothing(a)
        #! Pages do not decend subpages!
        #!@test typeof(arc(net, aid)) === typeof(arc(firstpage(net), aid))
    end

    @test arcs(net) !== nothing
    @test places(net) !== nothing
    @test transitions(net) !== nothing
    @test refplaces(net) !== nothing
    @test reftransitions(net) !== nothing

    noisy && println("---------------")
    noisy && @show (collect ∘ values ∘ page_idset)(net)
    noisy && println("---------------")

    @testset "flatten" begin
        @inferred flatten_pages!(net)
        #println("---------------")
        #@show netsets(firstpage(net))
        #@show netdata(net)
        #println("---------------")

        expected_a = [:a11, :a12, :a21, :a22, :a31, :a311]
        expected_p = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
        expected_t = [:t1, :t2, :t3, :t31]
        expected_rt = [] # removed by flatten
        expected_rp = [] # removed by flatten


        noisy && println()
        #@show (collect ∘ values ∘ page_idset)(net)
        noisy && AbstractTrees.print_tree(net)
        noisy && println()
        noisy && PNML.pagetree(net)
        noisy && println()

        @test (sort ∘ collect)(arc_idset(net)) == expected_a
        @test (sort ∘ collect)(arc_idset(firstpage(net))) == expected_a
        @test arc_idset(net) == arc_idset(firstpage(net))
        @test_call target_modules=target_modules arc_idset(net)
        @test_call arc_idset(firstpage(net))

        for a ∈ expected_a
            @test a ∈ arc_idset(net)
        end

        @test (sort ∘ collect)(place_idset(net)) == expected_p
        @test (sort ∘ collect)(place_idset(firstpage(net))) == expected_p
        @test place_idset(net) == place_idset(firstpage(net))
        @test_call target_modules=target_modules place_idset(net)
        @test_call place_idset(firstpage(net))

        for p ∈ expected_p
            @test p ∈ place_idset(net)
        end

        @test (sort ∘ collect)(transition_idset(net)) == expected_t
        @test (sort ∘ collect)(transition_idset(firstpage(net))) == expected_t
        @test (sort ∘ collect)(transition_idset(net)) == (sort ∘ collect)(transition_idset(firstpage(net)))
        @test_call target_modules=target_modules transition_idset(net)
        @test_call transition_idset(firstpage(net))

        for t ∈ expected_t
            @test t ∈ transition_idset(net)
        end

        # After flatten reference nodes remain in the netdata dictonary.
        #@show (sort ∘ collect)(reftransition_idset(net)) (
        #@show sort ∘ collect)(reftransition_idset(firstpage(net)))
        #@show expected_rt

        @test (sort ∘ collect)(reftransition_idset(firstpage(net))) == expected_rt
        @test (sort ∘ collect)(reftransition_idset(net)) == expected_rt
        @test (sort ∘ collect)(reftransition_idset(net)) == (sort ∘ collect)(reftransition_idset(firstpage(net)))
        @test_call target_modules=target_modules reftransition_idset(net)
        @test_call reftransition_idset(firstpage(net))

        for rt ∈ expected_rt
            @test rt ∈ reftransition_idset(net)
        end

        @test (sort ∘ collect)(refplace_idset(net)) == expected_rp
        @test (sort ∘ collect)(refplace_idset(firstpage(net))) == expected_rp
        @test (sort ∘ collect)(refplace_idset(net)) == (sort ∘ collect)(refplace_idset(firstpage(net)))
        @test_call target_modules=target_modules refplace_idset(net)
        @test_call refplace_idset(firstpage(net))

        for rp ∈ expected_rp
            @test rp ∈ refplace_idset(net)
        end
    end
end # pages

@testset "lookup types $pntd" for pntd in  values(PNML.PnmlTypeDefs.pnmltype_map)
    @test arc_type(pntd) <: PNML.Arc
    @test place_type(pntd) <: PNML.Place
    @test transition_type(pntd) <: PNML.Transition
    @test condition_type(pntd) <: PNML.Condition
    @test condition_value_type(pntd) isa Type
    @test sort_type(pntd) isa Type
    @test inscription_type(pntd) <: Union{PNML.Inscription, PNML.HLInscription}
    @test inscription_value_type(pntd) isa Type
    @test marking_type(pntd) <: Union{PNML.Marking, PNML.HLMarking}
    @test marking_value_type(pntd) isa Type
    @test page_type(pntd) <: PNML.Page
    @test refplace_type(pntd) <: PNML.RefPlace
    @test reftransition_type(pntd) <: PNML.RefTransition
    @test rate_value_type(pntd) isa Type


end
@testset "dump lookup types" begin
    noisy && dump_lutypes()
end
function dump_lutypes()
    # Is just the core 3 sufficient? [PnmlCoreNet(), HLCoreNet(), ContinuousNet()]
    # PTNet(), PT_HLPNG(), SymmetricNet()

    println("------------------------------------------------------------")
    for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
        println("------------------------------------------------------------")
        println("\n pnmlnet_type"); dump( pnmlnet_type(pntd))
        println("\n page_type"); dump( page_type(pntd))
        println("\n arc_type"); dump( arc_type(pntd))
        println("\n place_type"); dump( place_type(pntd))
        println("\n transition_type"); dump( transition_type(pntd))
        println("\n refplace_type"); dump( refplace_type(pntd))
        println("\n reftransition_type"); dump( reftransition_type(pntd))

        println("\n marking_type"); dump( marking_type(pntd))
        println("\n inscription_type"); dump( inscription_type(pntd))
        println("\n condition_type"); dump( condition_type(pntd))

        println("\n condition_value_type"); dump( condition_value_type(pntd))
        println("\n sort_type"); dump( sort_type(pntd))

        println("\n inscription_value_type"); dump( inscription_value_type(pntd))
        println("\n marking_value_type"); dump( marking_value_type(pntd))
        println("\n rate_value_type"); dump( rate_value_type(pntd))
        println("------------------------------------------------------------")
    end
    println("------------------------------------------------------------")
end
