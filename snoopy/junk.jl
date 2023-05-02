# For use in REPL!
using PNML, AbstractTrees, Test, JET
using PNML: Maybe,
    nets, first_net, nettype,
    pages, firstpage,
    arc, place, inscription, haspid, getfirst,
    arc_type, place_type,
    arc_idset, place_idset, transition_idset,
    arcs, places,
    SimpleNet

using Base: Fix1, Fix2

"For JET"
const target_modules = (PNML, )

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
model = parse_str(str)
@show typeof(model)
@show typeof(nets(model))
n = first_net(model)
@show typeof(n)
@show typeof(pages(n))
pg = firstpage(n)
@show typeof(pg)
AbstractTrees.print_tree(n)

exp_arc_ids = [:a11, :a12, :a21, :a22, :a31, :a311]
exp_place_ids = [:p1, :p11, :p111, :p2, :p3, :p31, :p311, :p3111]
exp_transition_ids = [:t1, :t2, :t3, :t31]
exp_refplace_ids = [:rp1, :rp2]
exp_reftransition_ids = [:rt2]

@show typeof(arc(n, :a11))
@inferred Maybe{arc_type(nettype(n))} arc(n, :a11)

@show typeof(arc(pg, :a11))
@inferred Maybe{arc_type(nettype(pg))} arc(pg, :a11)

snet = @inferred SimpleNet SimpleNet(model)

@testset "JUNK" begin
    @testset "opt" begin
        @report_opt SimpleNet(model)
    end

    @test snet isa SimpleNet
    @test arc_idset(n) == exp_arc_ids

    @testset "n" begin
        @show typeof(n)
        p = places(n)
        @show typeof(p)
        @test_call target_modules=target_modules places(n)
        @inferred places(n)
    end
    @testset "snet" begin
        @show typeof(snet)
        p = places(snet)
        @show typeof(p)
        @test_call target_modules = target_modules places(snet)
        @inferred places(snet)
    end
    @testset "snet.net" begin
        @show typeof(snet.net)
        p = places(snet.net)
        @show typeof(p)
        @test_call target_modules = target_modules places(snet.net)
        @inferred places(snet.net)
    end
end
