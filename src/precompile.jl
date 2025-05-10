using PrecompileTools: PrecompileTools

PrecompileTools.@setup_workload begin
    PrecompileTools.@compile_workload begin
        if false #! begin #! redirect_stdio(; stdout=devnull, stderr=devnull) do

        let pntds = ["pnmlcore", "ptnet", "continuous"]
            for pntd in pntds
                #@show pntd
                Parser.pnmlmodel(Context(), xml"""<?xml version="1.0"?>
                    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                    <net id="net_$pntd" type="$pntd">
                    <page id="page0">
                        <place id="p1">
                            <initialMarking> <text>100</text> </initialMarking>
                        </place>
                        <transition id="y1"></transition>
                        <arc source="a1" target="p1" id="t1">
                            <inscription><text>2</text></inscription>
                        </arc>
                    </page>
                    </net>
                    </pnml>""")
            end
        end

        let pntds = ["hlcore", "hlnet", "pt_hlpng", "symmetricnet"]
            for pntd in pntds
                #@show pntd
                metagraph(SimpleNet(Context(), xml"""<?xml version="1.0"?>
                    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                    <net id="smallnet_$pntd" type="$pntd">
                    <name> <text>Some Net</text> </name>
                    <page id="page1">
                        <place id="place1">
                            <hlinitialMarking> <text>100</text> </hlinitialMarking>
                            <type><usersort declaration="cli" /></type>
                        </place>
                        <transition id="transition1">
                            <name><text>Some transition</text></name>
                        </transition>
                        <arc source="transition1" target="place1" id="arc1">
                            <hlinscription><text>12</text></hlinscription>
                        </arc>
                    </page>
                    </net>
                    </pnml>"""))
            end
        end

        let pntds = ["continuous"]
            for pntd in pntds
                #@show pntd
                metagraph(SimpleNet(Context(), """<?xml version="1.0"?>
                    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                    <net id="smallnet_$pntd" type="$pntd">
                    <name> <text>Some Net</text> </name>
                    <page id="page1">
                        <place id="place1">
                            <initialMarking> <text>2.6</text> </initialMarking>
                        </place>
                        <transition id="transition1">
                            <name><text>Some transition</text></name>
                        </transition>
                        <arc source="transition1" target="place1" id="arc1">
                            <inscription><text>1</text></inscription>
                        </arc>
                    </page>
                    </net>
                    </pnml>"""))
            end
        end
    end
end
end
