using PNML, PnmlCore
using EzXML, JET, AbstractTrees
using Preferences
using PNML: rate_value_type, default_term, default_one_term, default_zero_term,
        parse_net
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
    AbstractPnmlObject, PnmlType, RefPlace, RefTransition, ReferenceNode,
    StochasticNet, SymmetricNet, TimedNet, TokenGraphics, ToolInfo, Transition,
    XMLNode,
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
    page_type, sort_type

const fname = "test1.pnml"

const x = EzXML.root(EzXML.readxml(fname));
const r = PnmlIDRegistry();
const m = parse_pnml(x, r);

function parse_top_net(node::XMLNode, i)
    nn = check_nodename(node, "pnml")
    reg = PnmlIDRegistry()
    nets = allchildren("net", node)
    net_tup = tuple(parse_net(nets[i], reg),)
    PnmlModel(net_tup, pnml_ns, reg, node)
end

function timed_parse(node::XMLNode)
    #! DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER
    #! Does not match original source!!!!
    reg = PnmlIDRegistry()
    nn = check_nodename(node, "pnml")
    nets = allchildren("net", node)
    isempty(nets) && throw(MalformedException("$nn does not have any <net> elements", node))
    # Do not yet have a PNTD defined, so call parse_net directly.
    net_vec = parse_net.(nets, Ref(reg))
    net_tup = tuple(net_vec...)
    PnmlModel(net_tup, pnml_ns, reg, node)
end

function pnml_ff(@nospecialize(ft))
    #@show ft
    if ft === typeof(PnmlIDRegistrys.register_id!) ||
        ft === typeof(PNML.PnmlModel) ||
        ft === typeof(PNML.EzXML.nodename) ||
        false
        return false
    end
    return true
end

#=

julia> @report_opt function_filter=pnml_ff EzXML.root(EzXML.readxml(fname))
julia> @report_opt function_filter=pnml_ff PnmlIDRegistry()
julia> @report_opt function_filter=pnml_ff parse_pnml(x, r)
julia> @report_opt target_modules = (PNML,PnmlCore,PnmlIDRegistrys,PnmlTypeDefs,) parse_pnml(x, r)

julia> @report_opt target_modules = (PNML,PnmlCore,PnmlIDRegistrys,PnmlTypeDefs,) parse_top_net(x,1)

julia> @code_warntype parse_pnml(x, r)

=#

@show pid.(nets(m))
@show nettype.(nets(m))

@show typeof(nets(m)[1])

# usage: showtree.(nets(m))
function showtree(n)
    println()
    AbstractTrees.print_tree(n)
end
include("defaults_types.jl")
nothing
