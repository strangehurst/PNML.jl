# Profile Guided Despecialization
using PNML, EzXML

const fname = "test1.pnml"
const x = EzXML.root(EzXML.readxml(fname));

using SnoopCompile
tinf = @snoopi_deep parse_pnml(x, PNML.registry());

using Profile
@profile parse_pnml(x, PNML.registry());

import PyPlot
mref, ax = pgdsgui(tinf);
