using PNML, ..TestUtils, JET, AbstractTrees
using PNML: page_idset, place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset

function verify_sets(net::PnmlNet)
    println("\nverify sets and structure ++++++++++++++++++++++")
    @test page_idset(net) isa AbstractSet
    @test page_idset(firstpage(net)) isa AbstractSet
    @test !isempty(setdiff(page_idset(net), page_idset(firstpage(net))))

    @test arc_idset(net) isa AbstractSet
    @test arc_idset(firstpage(net)) isa AbstractSet
    #@show arc_idset(net) arc_idset(firstpage(net))
    @test !isempty(setdiff(arc_idset(net), arc_idset(firstpage(net))))

    @test place_idset(net) isa AbstractSet
    @test place_idset(firstpage(net)) isa AbstractSet
    @test !isempty(setdiff(place_idset(net), place_idset(firstpage(net))))

    @test transition_idset(net) isa AbstractSet
    @test transition_idset(firstpage(net)) isa AbstractSet
    @test !isempty(setdiff(transition_idset(net), transition_idset(firstpage(net))))

    @test refplace_idset(net) isa AbstractSet
    @test refplace_idset(firstpage(net)) isa AbstractSet
    @test !isempty(setdiff(refplace_idset(net), refplace_idset(firstpage(net))))

    @test reftransition_idset(net) isa AbstractSet
    @test reftransition_idset(firstpage(net)) isa AbstractSet
    @test !isempty(setdiff(reftransition_idset(net), reftransition_idset(firstpage(net))))

    @test netdata(net) === netdata(firstpage(net))
    for page in pages(net)
        @test netdata(net) === netdata(page)   # There is only 1 netdata.
        @test pagedict(net) === pagedict(page) # There is only 1 pagedict.
    end

    for pageid in PNML.page_idset(net)
        @test netdata(net) === netdata(pagedict(net)[pageid])
    end
end

model = @inferred PNML.PnmlModel parse_string("""<?xml version="1.0"?>
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
""")
net = first(nets(model)) # The nets of a model not inferrable.
@test net isa PnmlNet  # Any concrete subtype.
@test isconcretetype(typeof(net))
@test startswith(sprint(show, model), "PnmlModel")
@test @inferred(firstpage(net)) isa Page # add parameters?
@test length(PNML.allpages(net)) == 14

@test_logs sprint(println, PNML.allpages(net))
#@show net
verify_sets(net)

type_funs = (
    PNML.arc_type,
    PNML.place_type,
    PNML.transition_type,
    PNML.condition_type,
    PNML.condition_value_type,
    PNML.inscription_type,
    PNML.inscription_value_type,
    PNML.marking_type,
    PNML.marking_value_type,
    PNML.page_type,
    PNML.refplace_type,
    PNML.reftransition_type,
    PNML.rate_value_type,
    )

def_funs = (
            Labels.default_inscription,
            #!Labels.default_marking, #! needs ids
            Labels.default_condition,
            )

@testset "by pntd $pntd" for pntd in PnmlTypeDefs.core_nettypes()
    for fun in type_funs
        @test_opt function_filter=pff target_modules=(@__MODULE__,) fun(pntd)
        @test_call fun(pntd)

        pt = typeof(pntd)
        @test_opt function_filter=pff target_modules=(@__MODULE__,) fun(pt)
        @test_call fun(pt)

        @test_opt function_filter=pff target_modules=(@__MODULE__,) fun(net)
        @test_call fun(net)
        @test fun(net) isa Type
    end

    #for fun in def_funs
    #    @test_opt function_filter=pff target_modules=(@__MODULE__,) fun(pntd)
    #    @test_call fun(pntd)
    #end
end

exp_arc_ids           = [:a11, :a12, :a21, :a22, :a31, :a311]
exp_place_ids         = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
exp_transition_ids    = [:t1, :t2, :t3, :t31]
exp_refplace_ids      = [:rp1, :rp2]
exp_reftransition_ids = [:rt2]

@test isempty(setdiff(@inferred(place_idset(net)), exp_place_ids))
@test isempty(setdiff(@inferred(arc_idset(net)), exp_arc_ids))
@test isempty(setdiff(@inferred(transition_idset(net)), exp_transition_ids))
@test isempty(setdiff(@inferred(refplace_idset(net)), exp_refplace_ids))
@test isempty(setdiff(@inferred(reftransition_idset(net)), exp_reftransition_ids))

for arcid in exp_arc_ids
    @test !isnothing(arc(net, arcid))
end

@test arcs(net) !== nothing
@test places(net) !== nothing
@test transitions(net) !== nothing
@test refplaces(net) !== nothing
@test reftransitions(net) !== nothing

@test narcs(net) != 0
@test nplaces(net) != 0
@test ntransitions(net) != 0
@test nrefplaces(net) != 0
@test nreftransitions(net) != 0

@testset "flatten" begin
    println("---------------"^4)
    flatten_pages!(net; verbose=false)
    println("---------------"^4)

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

    @test isempty(setdiff(arc_idset(net), expected_a))
    @test isempty(setdiff(arc_idset(firstpage(net)), expected_a))
    @test isempty(setdiff(arc_idset(net), arc_idset(firstpage(net))))
    @test_call target_modules=target_modules arc_idset(net)
    @test_call arc_idset(firstpage(net))
    for a ∈ expected_a
        @test a ∈ arc_idset(net)
        @test a ∈ arc_idset(firstpage(net))
    end

    @test isempty(setdiff(place_idset(net), expected_p))
    @test isempty(setdiff(place_idset(firstpage(net)), expected_p))
    @test isempty(setdiff(place_idset(net), place_idset(firstpage(net))))
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

    @test isempty(reftransition_idset(net))
    @test isempty(reftransition_idset(firstpage(net)))
    @test (sort ∘ collect)(reftransition_idset(net)) == expected_rt
    @test (sort ∘ collect)(reftransition_idset(firstpage(net))) == expected_rt
    @test (sort ∘ collect)(reftransition_idset(net)) == (sort ∘ collect)(reftransition_idset(firstpage(net)))
    @test_call target_modules=target_modules reftransition_idset(net)
    @test_call reftransition_idset(firstpage(net))
    for rt ∈ expected_rt
        @test rt ∈ reftransition_idset(net)
    end

    @test isempty(refplace_idset(net))
    @test isempty(refplace_idset(firstpage(net)))
    @test (sort ∘ collect)(refplace_idset(net)) == expected_rp
    @test (sort ∘ collect)(refplace_idset(firstpage(net))) == expected_rp
    @test (sort ∘ collect)(refplace_idset(net)) == (sort ∘ collect)(refplace_idset(firstpage(net)))
    @test_call target_modules=target_modules refplace_idset(net)
    @test_call refplace_idset(firstpage(net))
    for rp ∈ expected_rp
        @test rp ∈ refplace_idset(net)
    end
end

@testset "lookup types $pntd" for pntd in PnmlTypeDefs.all_nettypes()
    @test PNML.arc_type(pntd) <: PNML.Arc
    @test PNML.place_type(pntd) <: PNML.Place
    @test PNML.transition_type(pntd) <: PNML.Transition
    @test PNML.condition_type(pntd) <: PNML.Labels.Condition
    @test PNML.condition_value_type(pntd) <: Bool
    @test PNML.inscription_type(pntd) <: Union{PNML.Inscription, PNML.HLInscription}
    if ishighlevel(pntd)
        @test PNML.inscription_value_type(pntd) <: PnmlMultiset{<:Any, <:Any}
    else
        @test PNML.inscription_value_type(pntd) <: Number
    end
    #@show inscription_value_type(pntd)
    @test PNML.marking_type(pntd) <: Union{PNML.Marking, PNML.HLMarking}
    @test PNML.marking_value_type(pntd) <: Union{Number, PNML.PnmlMultiset{<:Any, <:Any}}

    @test PNML.page_type(pntd) <: PNML.Page
    @test PNML.refplace_type(pntd) <: PNML.RefPlace
    @test PNML.reftransition_type(pntd) <: PNML.RefTransition
    @test PNML.rate_value_type(pntd) <: Float64
end
