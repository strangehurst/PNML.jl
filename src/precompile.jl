using PrecompileTools

PrecompileTools.@setup_workload begin
    PrecompileTools.@compile_workload begin
        #redirect_stdio(; stdout=devnull, stderr=devnull) do

        let pntds = ["pnmlcore", "ptnet", "nonstandard", "open"]    
            for pntd in pntds
                parse_str("""<?xml version="1.0"?>
                    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                    <net id="net0" type="$pntd">
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
                metagraph(SimpleNet("""<?xml version="1.0"?>
                    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                    <net id="small-net" type="$pntd">
                    <name> <text>Some Net</text> </name>
                    <page id="page1">
                        <place id="place1">
                            <hlinitialMarking> <text>100</text> </hlinitialMarking>
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
                metagraph(SimpleNet("""<?xml version="1.0"?>
                    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
                    <net id="small-net" type="$pntd">
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
