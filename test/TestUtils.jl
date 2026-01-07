"Utilities shared by SafeTestSets"
module TestUtils
using EzXML, Preferences, XMLDict, Reexport, Multisets
Multisets.set_key_value_show()

@reexport import Moshi
@reexport import Moshi.Match: @match
@reexport import Moshi.Data: @data, isa_variant, is_data_type, variant_type

@reexport using PNML
@reexport using PNML.Sorts
@reexport using PNML.Labels
@reexport using PNML.Labels: TokenGraphics, get_toolinfo, version
@reexport using PNML.Parser
@reexport using PNML.Declarations
@reexport using PNML.IDRegistrys
@reexport using PNML.PnmlTypes
@reexport using PNML.PnmlGraphics
@reexport using PNML.PNet
@reexport using PNML: Maybe, DeclDict, XMLNode, xmlnode, @xml_str
@reexport using PNML: Parser.firstchild, Parser.allchildren, PnmlMultiset, pid, ispid,
    name, length, arity, tag, value, term, Labels.text, elements,
    graphics, has_graphics,
    DictType, AnyElement, Parser.anyelement, Parser.xmldict,
    multiset
@reexport using PNML: toexpr, PnmlExpr

@reexport using PNML: Context

@reexport using PNML: PnmlNetData, PnmlNetKeys, netsets, netdata, pagedict

@reexport using PNML: PnmlModel,
    PnmlNet, nets, nettype,
    Page, pages, npages, firstpage, allpages, flatten_pages!,
    Place, place, places, nplaces,  has_place,
    Transition, transition, transitions, ntransitions, has_transition,
    RefPlace, refplace, refplaces, nrefplaces,
    RefTransition, reftransition, reftransitions, nreftransitions,
    Arc, arc, arcs, narcs, source, target, has_arc

@reexport using PNML: labels, varsubs

@reexport using PNML.Parser: pnmlmodel, parse_net, parse_page!,
    parse_place, parse_arc, parse_transition, parse_refPlace, parse_refTransition,
    parse_name, parse_text, parse_graphics, parse_toolspecific,
    parse_initialMarking, parse_inscription, parse_sort, parse_declaration!,
    parse_hlinitialMarking, parse_hlinscription, parse_fifoinitialMarking
@reexport using PNML.Parser: to_sort

@reexport using PNML.Labels: PnmlLabel, has_label, get_label, Condition

@reexport using PNML: toolinfos

@reexport using PNML: AbstractDeclaration, Declaration, refid
@reexport using PNML: PNet.initial_marking, PNet.initial_markings, inscription, condition

@reexport using PNML: AbstractSort, SortType, NamedSort, BoolSort, DotSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort, PartitionElement,
    IntegerSort, NaturalSort, PositiveSort, RealSort,
    MultisetSort, ProductSort, PartitionSort, ListSort, StringSort, ArbitrarySort,
    sortof, sortref, sortdefinition, namedsort

@reexport using PNML: NumberConstant, DotConstant, DotConstantEx, zero

@reexport using PNML: AbstractTerm, AbstractVariable, AbstractOperator, inputs

@reexport using PNML.Expressions

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
    #if ft === typeof(IDRegistrys.register_id!) ||
    if  ft === Preferences.load_preference ||
        ft === EzXML.nodename ||
        ft === EzXML.namespace ||
        ft === Base.repr ||
        ft === Base.sprint ||
        ft === Base.string ||
        ft === Base.print ||
        ft === Base.println ||
        ft === PNML.Parser.xmldict ||
        ft === PNML.Parser.add_label! ||
        ft === XMLDict.xml_dict ||
        false
        return false
    end
    return true
end

export VERBOSE_PNML, pff, target_modules, runopt, testshow, noisy

end # module TestUtils
