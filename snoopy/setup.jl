using EzXML, JET, AbstractTrees, NamedTupleTools, Preferences
using PNML
using PNML:
    rate_value_type, default_one_term, default_zero_term,
    parse_net,
    AbstractContinuousNet, AbstractHLCore, AbstractLabel,
    AbstractPnmlCore, AbstractPnmlTool, @xml_str,
    Annotation, AnyElement, Arc, Condition,
    ContinuousNet, Coordinate, Declaration,
    Fill, Font, Graphics, HLCoreNet, HLPNG,
    Inscription, Line,
    MalformedException, Marking, Maybe, MissingIDException, Name, ObjectCommon,
    OpenNet, PTNet, PT_HLPNG, Page, Place, PnmlCoreNet, PnmlException,
    PnmlIDRegistry, PnmlLabel, PnmlModel, PnmlNet,    AbstractPnmlNode,
    AbstractPnmlObject, PnmlType, RefPlace, RefTransition, ReferenceNode,
    StochasticNet, SymmetricNet, TimedNet, TokenGraphics, ToolInfo, Transition,
    XMLNode,
    _evaluate,
    all_arcs, allchildren, append_page!, arc, arc_idset, arcs,
    check_nodename, common, condition, conditions, initial_markings,
    condition_type, condition_value_type,
    declarations, default_condition, default_inscription, default_marking, default_sort,
    deref!, deref_place, deref_transition, elements,
    find_net, find_nets, first_net, firstchild, firstpage, flatten_pages!,
    get_label, get_labels, getfirst, graphics,
    has_arc, has_graphics, has_label, has_labels, has_name, has_place,
    has_refplace, has_reftransition, has_structure, has_text, has_tools, has_transition, has_xml,
    hastag, haspid,
    ispid, idregistry, inc_indent, indent, infos,
    initialMarking, initial_marking, marking_type, marking_value_type,
    inscription, inscription_type, inscription_value_type,
    isregistered, labels,
    name, namespace, nets, nettype,
    pages, pid, place, place_idset, places, pnml_ns,
    pnmltype, pntd_symbol, refid, refplace, refplace_idset, refplaces,
    reftransition, reftransition_idset, reftransitions, register_id!,
    show_common, show_page_field, shownames, source,
    src_arcs, structure, tag, target, text, tgt_arcs, tools,
    transition, transition_idset, transitions,
    value, version,
    xmlnode, xmlroot,
    arc_type, place_type, transition_type, refplace_type, reftransition_type,
    page_type, sort_type

"Test input file."
const fname = "test1.pnml"

const x = EzXML.root(EzXML.readxml(fname));
const r = registry();
const m = parse_pnml(x, r);

function pnml_ff(@nospecialize(ft))
    #@show ft
    if ft === typeof(PNML.EzXML.nodename) ||
        ft === typeof(PNML.NamedTupleTools.merge) ||
        ft === typeof(PNML.merge) ||
        ft === typeof(PNML._harvest_any) ||
        ft === typeof(PNML.register_id!) ||
        false
        return false
    end
    return true
end

#=
julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time includet("setup.jl"); const netxml = first(allchildren("net", x)); @report_opt target_modules = (PNML,) PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry())
=#
function top_net(x::XMLNode)
    netxml = first(allchildren("net", x))
    @report_opt target_modules=(PNML,) function_filter=pnml_ff PNML.parse_net_1(netxml, pnmltype(netxml["type"]), registry())
end

function timed_parse(node::XMLNode)
    #! DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER DANGER
    # Bypass part of PNML flow by decending into the XML tree. #! This is exploratory (surgery?).
    #
    nn = check_nodename(node, "pnml") # Top of the pnml model.
    nets = allchildren("net", node) # That can have one or more nets of any pnml net definition types.
    isempty(nets) && throw(MalformedException("$nn does not have any <net> elements"))

    reg = registry()
    # Call parse_net directly.
    net_vec = parse_net.(nets, Ref(reg))
    net_tup = tuple(net_vec...)
    PnmlModel(net_tup, pnml_ns, reg) #! pnml_ns
end


#=

julia> @report_opt function_filter=pnml_ff EzXML.root(EzXML.readxml(fname))
julia> @report_opt function_filter=pnml_ff registry()
julia> @report_opt function_filter=pnml_ff parse_pnml(x, r)
julia> @report_opt target_modules = (PNML,) parse_pnml(x, r)
julia> @report_opt target_modules = (PNML,) parse_pnml(x, r)

julia> @report_opt target_modules = (PNML,) parse_top_net(x,1)

julia> @code_warntype parse_pnml(x, r)

julia> import Pkg; Pkg.activate("./snoopy"); cd("snoopy"); @time include("setup.jl")

julia> top_net(x)

@show pid.(nets(m))
@show nettype.(nets(m))

@show typeof(nets(m)[1])
=#

"usage: showtree.(nets(m))"
function showtree(n)
    println()
    AbstractTrees.print_tree(n)
end
include("defaults_types.jl")
nothing
