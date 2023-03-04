"""
$(DocStringExtensions.README)

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PNML


Base.@kwdef mutable struct PnmlConfig
    indent_width::Int = 4
    warn_on_namespace::Bool = true
    text_element_optional::Bool = true
    warn_on_fixup::Bool = false
    warn_on_unclaimed::Bool = false
    verbose::Bool = false
end

"""
    PNML.CONFIG

# Options
- `indent_width::Int`: Indention of nested lines. Defaults to `$(PnmlConfig().indent_width)`.
- `warn_on_namespace::Bool`: There are pnml files that break the rules &
do not have an xml namespace. Initial state of toggle defaults to `true`.
- `text_element_optional::Bool`: There are pnml files that break the rules & do not have <text> elements.
Initial state of warning toggle defaults to `true`.
- `warn_on_fixup::Bool`: When an missing value is replaced by a default value,
issue a warning. Initial state of "warn_on_fixup" toggle defaults to `false`.
- `warn_on_unclaimed::Bool`: Issue warning when PNML label does not have a parser defined.
While allowed, there will be code required to do anything useful with the label.
Initial state of "warn" toggle defaults to `false`.
- `verbose::Bool`: Print information as runs.  Initial state of "verbose" toggle.
Defaults to `false`.
"""
const CONFIG = PnmlConfig()

using Preferences
include("preferences.jl")
__init__() = read_config!(CONFIG)



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
using FunctionWrappers
import FunctionWrappers: FunctionWrapper
import OrderedCollections: OrderedDict, OrderedSet

using Base: Fix1, Fix2, @kwdef

@reexport using PnmlCore

using PnmlCore:
    AbstractContinuousNet, AbstractHLCore, AbstractLabel,
    AbstractPnmlCore, AbstractPnmlTool, @xml_str,
    Annotation, AnyElement, Arc, Condition,
    ContinuousNet, Coordinate, Declaration,
    Fill, Font, Graphics, HLCoreNet, HLPNG,
    Inscription, Line,
    MalformedException, Marking, Maybe, MissingIDException, Name, ObjectCommon,
    OpenNet, PTNet, PT_HLPNG, Page, Place, PnmlCoreNet, PnmlDict, PnmlException,
    PnmlIDRegistry, PnmlLabel, PnmlModel, PnmlNet,
    AbstractPnmlNode,
    AbstractPnmlObject, PnmlType, PnmlTypeDefs, RefPlace, RefTransition, ReferenceNode,
    StochasticNet, SymmetricNet, TimedNet, TokenGraphics, ToolInfo, Transition,
    XMLNode

import PnmlCore: CONFIG,
    PnmlCore, _evaluate,
    all_arcs, allchildren, append_page!, arc, arc_ids, arcs,
    check_nodename, common, condition, conditions, currentMarkings,
    condition_type, condition_value_type,
    declarations, default_condition, default_inscription, default_marking, default_sort,
    deref!, deref_place, deref_transition, dict,
    find_net, find_nets, first_net, firstchild, firstpage, flatten_pages!,
    get_label, get_labels, getfirst, graphics,
    has_arc, has_graphics, has_label, has_labels, has_name, has_place,
    has_refP, has_refT, has_structure, has_text, has_tools, has_transition, has_xml,
    hastag, haspid,
    ispid, idregistry, inc_indent, indent, infos,
    initialMarking, marking, marking_type, marking_value_type,
    inscription, inscription_type, inscription_value_type,
    isregistered_id, labels,
    name, namespace, nets, nettype,
    pages, pid, place, place_ids, places, pnml_ns,
    pnmltype, pntd_symbol, refid, refplace, refplace_ids, refplaces,
    reftransition, reftransition_ids, reftransitions, register_id!,
    show_common, show_page_field, shownames, source,
    src_arcs, structure, tag, target, text, tgt_arcs, tools,
    transition, transition_ids, transitions,
    update_maybe!, value, version,
    xmlnode, xmlroot,
    arc_type, place_type, transition_type, refplace_type, reftransition_type,
    page_type, sort_type, coordinate_type, coordinate_value_type, pnmlnet_type



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


export @xml_str, CONFIG,
    xmlroot,
    PnmlDict,
    parse_str,
    parse_file,
    parse_pnml,
    parse_node,
    PnmlException,
    MissingIDException,
    MalformedException


#TODO ============================================
#TODO precompile setup.
#TODO ============================================

using SnoopPrecompile

SnoopPrecompile.@precompile_setup begin
    #! data = ...
    SnoopPrecompile.@precompile_all_calls begin
        #! call_some_code(data, ...)
    end
end

end # module PNML
