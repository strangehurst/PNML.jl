using EzXML, PNML
prosetup() = EzXML.root(EzXML.readxml("/home/jeff/Jules/PNML/snoopy/test1.pnml"))
x = prosetup()
using Profile

#-----------------------------------------------------
r = registry()
VSCodeServer.@profview parse_pnml(x, r)
PNML.reset!(r) # need to empty the registry
VSCodeServer.@profview parse_pnml(x, r) # ignore 1st run

#-----------------------------------------------------
node = xml"""
<place id="place1">
  <name> <text>with text</text> </name>
  <initialMarking> <text>100</text> </initialMarking>
</place>
"""
tfx() = for i in 1:1000
    PNML.parse_place(node, PNML.PnmlCoreNet(), PNML.registry())
end
VSCodeServer.@profview tfx()


#-----------------------------------------------------
using EzXML, PNML
fx() = for i in 1:1000
    PNML.SimpleNet("""<?xml version="1.0"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="small-net" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name> <text>P/T Net with one place</text> </name>
    <page id="page1">
      <place id="place1">
	    <initialMarking> <text>100</text> </initialMarking>
      </place>
      <transition id="transition1">
        <name><text>Some transition</text></name>
      </transition>
      <arc source="transition1" target="place1" id="arc1">
        <inscription><text>12</text></inscription>
      </arc>
    </page>
  </net>
</pnml>""")
end
VSCodeServer.@profview fx()

#-----------------------------------------------------
using EzXML, PNML
prosetup() = parse_file

node = EzXML.root(EzXML.readxml("/home/jeff/Jules/PNML/snoopy/test1.pnml"))
  fx() = for i in 1:1000
    PNML.SimpleNet(node)
  end
VSCodeServer.@profview fx()



#-----------------------------------------------------
using EzXML, PNML


PNML.CONFIG.verbose = true;

PNML.CONFIG.warn_on_unclaimed = true;     # Customize some defaults

n = PNML.SimpleNet("""<?xml version="1.0"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="small-net" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name> <text>P/T Net with one place</text> </name>
    <page id="page1">
      <place id="place1">
	    <initialMarking> <text>100</text> </initialMarking>
      </place>
      <transition id="transition1">
        <name><text>Some transition</text></name>
      </transition>
      <arc source="transition1" target="place1" id="arc1">
        <inscription><text>12</text></inscription>
      </arc>
    </page>
  </net>
</pnml>""");


#-----------------------------------------------------
julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time includet("setup.jl");
const netxml = first(PNML.allchildren("net", x));
@report_opt target_modules = (PNML,) PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry())
