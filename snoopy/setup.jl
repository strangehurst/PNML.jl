using PNML, PnmlCore, PnmlIDRegistrys, PnmlTypeDefs

m = parse_str("""
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
                        <place id="p31"/>
                        <transition id ="t31"/>
                        <arc id="a311" source="t31" target="p1"/>
                        <place id="p311" />
                        <place id="p3111" />
                    </page>
                </net>
            </pnml>
        """)

n = PNML.first_net(m)
