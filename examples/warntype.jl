# script to run as: julia examples/warntype.jl
using PNML, EzXML, ModuleDocstrings, InteractiveUtils

node = EzXML.ElementNode("n1/")
reg = registry()
pntd = PnmlCoreNet()

InteractiveUtils.@code_warntype PNML.parse_file("file")
InteractiveUtils.@code_warntype PNML.parse_str("</tag>")
