"Utilities shared by SafeTestSets"
module TestUtils
using EzXML, Preferences, XMLDict, Reexport, Multisets

@reexport using PNML: PNML

@reexport using PNML: PnmlIDRegistrys, registry, isregistered
@reexport using PNML: PnmlTypeDefs, core_nettypes, all_nettypes, ishighlevel, isdiscrete, iscontinuous

@reexport using PNML:   Maybe,
    XMLNode, xmlroot, getfirst, firstchild, allchildren,
    XDVT,
    pid, ispid,
    name, has_name,
    length, arity, tag, value, text, elements,
    graphics, has_graphics,
    DictType, AnyElement, anyelement, unparsed_tag

@reexport using PNML: PnmlNetData, PnmlNetKeys, netsets, netdata, pagedict,
    page_idset, place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset

@reexport using PNML: PnmlModel,
    PnmlNet, nets, nettype,
    Page, pages, npages, firstpage, allpages, flatten_pages!,
    Place, place, places, nplaces,  has_place,
    Transition, transition, transitions, ntransitions, has_transition,
    RefPlace, refplace, refplaces, nrefplaces,
    RefTransition, reftransition, reftransitions, nreftransitions,
    Arc, arc, arcs, narcs, source, target, has_arc

@reexport using PNML: SimpleNet
@reexport using PNML: parse_file, parse_str, parse_pnml,
    parse_net, parse_page!,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name, parse_text, parse_graphics, parse_tokengraphics, parse_toolspecific,
    parse_initialMarking, parse_inscription, parse_sort, parse_declaration

@reexport using PNML: PnmlLabel, has_label, get_label, get_labels, add_label!, labels
@reexport using PNML: ToolInfo, tools, get_toolinfo, version, TokenGraphics

@reexport using PNML: AbstractDeclaration, Declaration, decldict, refid,
    Condition, condition,
    inscription,
    initial_marking, initial_markings

@reexport using PNML: default_bool_term, default_zero_term, default_one_term,
    default_condition, default_inscription, default_marking, default_sort, default_sorttype

@reexport using PNML: page_type, place_type, transition_type, arc_type, refplace_type, reftransition_type,
    marking_type, inscription_type, condition_type,
    marking_value_type, inscription_value_type, condition_value_type,
    rate_value_type, term_value_type

@reexport using PNML: AbstractSort, SortType, BoolSort, DotSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort, PartitionElement,
    IntegerSort, NaturalSort, PositiveSort, RealSort,
    MultisetSort, ProductSort, PartitionSort, UserSort,
    ListSort, StringSort
@reexport using PNML: NumberConstant, DotConstant
@reexport using PNML: AbstractTerm, AbstractVariable, AbstractOperator,
    inputs, incidence_matrix

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

export VERBOSE_PNML, pff, target_modules, runopt, testshow, noisy

end # module TestUtils
