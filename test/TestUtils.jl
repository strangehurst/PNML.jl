"Utilities shared by SafeTestSets"
module TestUtils
using EzXML, Preferences, XMLDict, Reexport, Multisets

@reexport using PNML: PNML, Maybe, length,
    XMLNode, xmlroot, XDVT, arity, tag, labels, pid, ispid, value, text, tools, elements,
    name, has_name,
    DictType, AnyElement, anyelement, unparsed_tag,
    registry, isregistered,
    PnmlTypeDefs, core_nettypes, all_nettypes, ishighlevel, isdiscrete, iscontinuous,
    PnmlModel, SimpleNet,
    PnmlNetData, PnmlNetKeys, netsets, netdata,
    pagedict, page_idset, place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset,
    PnmlNet, nets, nettype,
    Page, pages, firstpage, allpages, flatten_pages!,
    Place, place, places, initial_marking, initial_markings,
    Transition, transition, transitions,
    RefPlace, refplace, refplaces,
    RefTransition, reftransition, reftransitions,
    Arc, arc, arcs,source, target,
    has_graphics, graphics,
    PnmlLabel, has_label, get_label, get_labels, add_label!, labels,
    ToolInfo, tools, get_toolinfo, version, TokenGraphics,
    parse_file, parse_str, parse_pnml, parse_net, parse_page!,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name, parse_text, parse_graphics, parse_tokengraphics, parse_toolspecific,
    parse_initialMarking, parse_inscription, parse_sort, parse_declaration,
    has_place, has_transition, has_arc,
    getfirst, firstchild, allchildren,
    AbstractDeclaration, Declaration, decldict,
    Condition, condition, inscription, refid,
    Term, default_bool_term, default_zero_term, default_one_term,
    default_condition, default_inscription, default_marking, default_sort, default_sorttype,
    page_type, place_type, transition_type, arc_type, marking_type, inscription_type,
    condition_type, refplace_type, reftransition_type,
    marking_value_type, inscription_value_type, condition_value_type, rate_value_type, term_value_type,
    AbstractSort, BoolSort, DotSort,CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort,
    IntegerSort, NaturalSort, PositiveSort, RealSort, ListSort, MultisetSort, ProductSort, PartitionSort, UserSort, StringSort,
    SortType, PartitionElement,
    NumberConstant, DotConstant,
    inputs, incidence_matrix

"Often JET has problems with beta julia versions:("
const jet_broke = (VERSION < v"1.10-") ? false : true

"Run @test_opt, expect many dynamic dispatch reports."
const runopt::Bool = false

"Print a lot of information as tests run."
const noisy::Bool = false

"Only report for our module."
const target_modules = (PNML,)

"Allow test of print/show methods without creating a file."
const testshow = devnull # nothing turns off redirection

"Ignore some dynamically-designed functions."
function pff(@nospecialize(ft))
    #if ft === typeof(PnmlIDRegistrys.register_id!) ||
    if  ft === Preferences.load_preference ||
        ft === EzXML.nodename ||
        ft === EzXML.namespace ||
        ft === Base.repr ||
        ft === Base.sprint ||
        ft === Base.string ||
        ft === Base.print ||
        ft === Base.println ||
        ft === PNML.unparsed_tag ||
        ft === PNML.add_label! ||
        ft === XMLDict.xml_dict ||
        false
        return false
    end
    return true
end

export VERBOSE_PNML, pff, target_modules, jet_broke, runopt, testshow, noisy

end # module TestUtils
