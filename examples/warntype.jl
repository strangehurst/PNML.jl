# script to run as: julia examples/warntype.jl 
using PNML, EzXML, ModuleDocstrings, InteractiveUtils

node = EzXML.ElementNode("n1/")
reg = PNML.IDRegistry()
pdict = PNML.PnmlDict()
pntd = PnmlCore()

InteractiveUtils.@code_warntype PNML.parse_file("file")
InteractiveUtils.@code_warntype PNML.parse_str("</tag>")
InteractiveUtils.@code_warntype PNML.parse_doc(EzXML.parsexml("<pnml></pnml>"))


