# script to run as: julia examples/warntype.jl
using PNML, EzXML, ModuleDocstrings, InteractiveUtils

node = EzXML.ElementNode("n1/")
reg = registry()
pdict = PNML.PnmlDict()
pntd = PnmlCoreNet()

InteractiveUtils.@code_warntype PNML.parse_file("file")
InteractiveUtils.@code_warntype PNML.parse_str("</tag>")
InteractiveUtils.@code_warntype PNML.parse_doc(EzXML.parsexml("<pnml></pnml>"))
