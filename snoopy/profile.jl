using EzXML, PNML
function prosetup(fname = "/home/jeff/PNML/snoopy/test1.pnml")
    (EzXML.root(EzXML.readxml(fname)), registry(),)
end
#=
x, r = prosetup("/home/jeff/PNML/snoopy/test1.pnml")
using Profile, ProfileView
@profview parse_pnml(x, r) # ignore 1st run
@profview parse_pnml(x, r)

julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time includet("setup.jl");
const netxml = first(allchildren("net", x));
@report_opt target_modules = (PNML,) PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry())
=#
