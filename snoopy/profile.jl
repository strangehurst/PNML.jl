using EzXML, PNML
function prosetup(fname = "/home/jeff/Jules/PNML/snoopy/test1.pnml")
    (EzXML.root(EzXML.readxml(fname)), registry(),)
end

x, r = prosetup()
using Profile, ProfileView
VSCodeServer.@profview parse_pnml(x, r) # ignore 1st run
VSCodeServer.@profview parse_pnml(x, r) # ignore 1st run


julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time includet("setup.jl");
const netxml = first(PNML.allchildren("net", x));
@report_opt target_modules = (PNML,) PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry())
