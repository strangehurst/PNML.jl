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
                </page>
            </page>
        </net>
    </pnml>
    """ 
    recursive_merge(x::AbstractDict...) = merge(recursive_merge, x...)
    recursive_merge(x::AbstractVector...) = cat(x...; dims=1)
    recursive_merge(x...) = x[end]
    
    doc = PNML.Document(str)

    net = PNML.first_net(doc)
    @test net isa PNML.PnmlNet
    printnode(net; label="\nMultiple nested pages", compress=false)

    net1 = recursive_merge(net)
    printnode(net1; label="\nRecusivly merged", compress=true)
    
    PNML.flatten_pages!(net)
    printnode(net; label="\nFlattened to 1 page", compress=false)

    cnet = PNML.compress(net)
    @test cnet isa PNML.PnmlNet
    printnode(cnet; label="\nCompressed", compress=false)
    # Transition to PnmlNet breaks compress
    @test_broken cnet != net

end
