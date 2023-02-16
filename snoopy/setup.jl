using PNML, PnmlCore, PnmlIDRegistrys, PnmlTypeDefs, EzXML, JET, AbstractTrees
using PNML: rate_value_type, default_term, default_one_term, default_zero_term
using PnmlCore:
    AbstractContinuousNet, AbstractHLCore, AbstractLabel,
    AbstractPnmlCore, AbstractPnmlTool, @xml_str,
    Annotation, AnyElement, Arc, Condition,
    ContinuousNet, Coordinate, Declaration,
    Fill, Font, Graphics, HLCoreNet, HLPNG,
    Inscription, Line,
    MalformedException, Marking, Maybe, MissingIDException, Name, ObjectCommon,
    OpenNet, PTNet, PT_HLPNG, Page, Place, PnmlCoreNet, PnmlDict, PnmlException,
    PnmlIDRegistry, PnmlLabel, PnmlModel, PnmlNet,    AbstractPnmlNode,
    AbstractPnmlObject, PnmlType, PnmlTypeDefs, RefPlace, RefTransition, ReferenceNode,
    StochasticNet, SymmetricNet, TimedNet, TokenGraphics, ToolInfo, Transition,
    XMLNode,
    PnmlCore, _evaluate, _reduce,
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
    ispid, idregistry, inc_indent, indent, indent_width, infos,
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
    page_type, sort_type

const fname = "test1.pnml"
@time x = EzXML.root(EzXML.readxml(fname));
@time r = PnmlIDRegistry();
@time m = parse_pnml(x, r);

function_filter(@nospecialize(ft)) =
    ft !== typeof(EzXML.throw_xml_error) &&
    ft !== typeof(Base.lock)

#=
julia> @report_opt function_filter=function_filter EzXML.root(EzXML.readxml(fname))
julia> @report_opt function_filter=function_filter PnmlIDRegistry()
julia> @report_opt function_filter=function_filter parse_pnml(x, r)
julia> @report_opt target_modules = (PNML,PnmlCore,PnmlIDRegistrys,PnmlTypeDefs,) parse_pnml(x, r)
=#
@show pid.(nets(m))
@show nettype.(nets(m))

# usage: showtree.(nets(m))
function showtree(n)
    println()
    AbstractTrees.print_tree(n)
end
include("defaults_types.jl")
nothing
