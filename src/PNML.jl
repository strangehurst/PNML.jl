"""
$(DocStringExtensions.README)

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PNML

# Width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

using EzXML
using MLStyle: @match
using DocStringExtensions
using AutoHashEquals
using PrettyPrinting
import PrettyPrinting: quoteof
using AbstractTrees
using LabelledArrays
using Reexport
using Preferences

using Base: Fix1, Fix2
import PnmlCore
@reexport using PnmlCore

using PnmlCore: AbstractContinuousNet, AbstractHLCore, AbstractLabel,
AbstractPnmlCore, AbstractPnmlTool, @xml_str,
Annotation, AnyElement, Arc, Condition,
ContinuousNet, Coordinate, Declaration,
Fill, Font, Graphics, HLCoreNet, HLPNG, IDRegistry, Inscription, Line,
MalformedException, Marking, Maybe, MissingIDException, Name, ObjectCommon,
OpenNet, PTNet, PT_HLPNG, Page, Place, PnmlCoreNet, PnmlDict, PnmlException,
PnmlIDRegistry, PnmlIDRegistrys, PnmlLabel, PnmlModel, PnmlNet, PnmlNode,
PnmlObject, PnmlType, PnmlTypeDefs, RefPlace, RefTransition, ReferenceNode,
StochasticNet, SymmetricNet, TimedNet, TokenGraphics, ToolInfo, Transition,
XMLNode


import PnmlCore: _evaluate, _ppages, _reduce,
all_arcs, allchildren, append_page!, arc, arc_ids, arcs,
check_nodename, common, condition, conditions, currentMarkings,
declarations, default_condition, default_inscription,
default_marking, deref!, deref_place, deref_transition, dict,
find_net, find_nets, first_net, firstchild, firstpage, flatten_pages!,
get_label, get_labels, getfirst, graphics,
has_arc, has_graphics, has_label, has_labels, has_name, has_place,
has_refP, has_refT, has_structure, has_text, has_tools, has_transition, has_xml,
hastag, haspid,
ispid, idregistry, inc_indent, indent, indent_width, infos,
initialMarking, inscription, inscriptiontype, inscriptionvaluetype,
isregistered_id, labels,
marking, markingtype, markingvaluetype,
name, namespace, nets, nettype,
pages, pid, place, place_ids, places, pnml_ns,
pnmltype, pntd_symbol, refid, refplace, refplace_ids, refplaces,
reftransition, reftransition_ids, reftransitions, register_id!,
show_common, show_page_field, shownames, source,
src_arcs, structure, tag, target, text, tgt_arcs, tools,
transition, transition_ids, transitions,
update_maybe!, value, version,
xmlnode, xmlroot



# High-Level
include("HighLevel/hltypes.jl")
include("HighLevel/hldefaults.jl")
include("HighLevel/structure.jl")
include("HighLevel/hllabels.jl")
include("HighLevel/hldeclarations.jl")
include("HighLevel/terms.jl")
include("HighLevel/sorts.jl")
include("HighLevel/hlinscriptions.jl")
include("HighLevel/hlmarkings.jl")
include("HighLevel/hlshow.jl")

# PETRI NET
include("Net/petrinet.jl")
include("Net/simplenet.jl")
include("Net/hlnet.jl")

include("Continuous/rates.jl")
include("Net/transition_function.jl")

# PARSE
include("Parse/parseutils.jl")
include("Parse/anyelement.jl")
include("Parse/parse.jl")
include("Parse/graphics.jl")
include("Parse/declarations.jl")
include("Parse/toolspecific.jl")
include("Parse/maps.jl")


export @xml_str,
    xmlroot,
    PnmlDict,
    parse_str,
    parse_file,
    parse_pnml,
    parse_node,
    PnmlException,
    MissingIDException,
    MalformedException
end
