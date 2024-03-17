"Utilities shared by SafeTestSets"
module TestUtils
using EzXML, Preferences, XMLDict, Reexport, Multisets
@reexport using PNML: PNML, Maybe, tag, labels, pid, AnyElement, name, value,
    nets, pages,
    parse_sort, parse_declaration,
    registry, isregistered,
    DictType, AbstractDeclaration,
    getfirst, firstchild, allchildren,
    ishighlevel, PnmlTypeDefs,
    Declaration, Condition, Term,
    default_bool_term, default_zero_term, default_one_term,
    default_condition, default_inscription, default_marking, default_sort, default_sorttype,
    page_type, place_type, transition_type, arc_type, marking_type, inscription_type,
    condition_type, condition_value_type, rate_value_type, term_value_type,
    AbstractSort, BoolSort, DotSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort,
    IntegerSort, ListSort, MultisetSort,
    NaturalSort, PositiveSort, ProductSort, PartitionSort, RealSort, UserSort, StringSort,
    SortType, PartitionElement,
    NumberConstant, DotConstant

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
