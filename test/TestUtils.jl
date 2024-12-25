"Utilities shared by SafeTestSets"
module TestUtils
using EzXML, Preferences, XMLDict, Reexport, Multisets
Multisets.set_key_value_show()
@reexport using Base.ScopedValues

@reexport using PNML: PNML
@reexport using PNML.Sorts
@reexport using PNML.Labels
@reexport using PNML.Parser
@reexport using PNML.Declarations
@reexport using PNML.PnmlIDRegistrys
@reexport using PNML.PnmlTypeDefs
@reexport using PNML.PnmlGraphics
@reexport using PNML: PnmlIDRegistrys, registry, isregistered
@reexport using PNML: PnmlTypeDefs, core_nettypes, all_nettypes,
    ishighlevel, isdiscrete, iscontinuous

@reexport using PNML: Maybe, DeclDict,
    XMLNode, xmlroot,  Parser.firstchild, Parser.allchildren,
    XDVT, PnmlMultiset,
    pid, ispid,
    name, has_name,
    length, arity, tag, value, term, Labels.text, elements,
    graphics, has_graphics,
    DictType, AnyElement, Parser.anyelement, Parser.unparsed_tag,
    SubstitutionDict

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

@reexport using PNML: SimpleNet, labels
@reexport using PNML.Parser: parse_file, parse_str, parse_pnml,
    parse_net, parse_page!,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name, parse_text, parse_graphics, parse_tokengraphics, parse_toolspecific,
    parse_initialMarking, parse_inscription, parse_sort, parse_declaration

@reexport using PNML.Labels: PnmlLabel, has_label, get_label, get_labels,
    Condition
@reexport using PNML.Parser: add_label!
@reexport using PNML: ToolInfo, tools, get_toolinfo, version, TokenGraphics

@reexport using PNML: AbstractDeclaration, Declaration, refid,
    initial_marking, initial_markings,
    inscription,
    condition

@reexport using PNML.Labels: default_marking, default_hlmarking,
    default_inscription, default_hlinscription,
    default_condition,
    default_typeusersort

@reexport using PNML: page_type,
    place_type, transition_type, arc_type, refplace_type, reftransition_type,
    marking_type, inscription_type, condition_type,
    marking_value_type, inscription_value_type, condition_value_type,
    rate_value_type

@reexport using PNML: AbstractSort, SortType, UserSort, NamedSort, BoolSort, DotSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort, PartitionElement,
    IntegerSort, NaturalSort, PositiveSort, RealSort,
    MultisetSort, ProductSort, PartitionSort, ListSort, StringSort, NullSort,
    sortof, sortref, TransitionRate

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
        ft === PNML.Parser.add_label! ||
        ft === XMLDict.xml_dict ||
        false
        return false
    end
    return true
end

export VERBOSE_PNML, pff, target_modules, runopt, testshow, noisy

end # module TestUtils
