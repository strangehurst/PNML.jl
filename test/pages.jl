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
                    <page id="page11.1">
                        <place id="p11.1" /> 
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
                        <page id="page41.1">
                            <place id="p41.1" /> 
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
    doc = PNML.Document(str)

    net = PNML.first_net(doc)
    @test net isa PNML.PnmlNet
    printnode(net; label="\n\nMultiple nested pages\n")

    PNML.flatten_pages!(net)
    printnode(net; label="\nFlattened to 1 page")

    

end
