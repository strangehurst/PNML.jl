# Ideas from MathML.jl

"""
Map XML tag names to parser functions.

$(TYPEDEF)
"""
const tagmap = Dict{String,Function}(
    "and" => parse_and,
    "arbitraryoperator" => parse_arbitraryoperator,
    "arbitrarysort" => parse_arbitrarysort,
    "arc"  => parse_arc,
    "bool" => parse_bool,
    "booleanconstant" => parse_booleanconstant,
    "condition" => parse_condition,
    "declaration" => parse_declaration,
    "declarations"  => parse_declarations,
    "equality" => parse_equality,
    "graphics" => parse_graphics,
    "hlinitialMarking" => parse_hlinitialMarking,
    "hlinscription" => parse_hlinscription,
    "imply" => parse_imply,
    "inequality" => parse_inequality,
    "initialMarking" => parse_initialMarking,
    "inscription" => parse_inscription,
    "label" => parse_label,
    "mulitsetsort" => parse_mulitsetsort,
    "name" => parse_name,
    "namedoperator" => parse_namedoperator,
    #"net" => parse_net, #! Method should not be forun by parse_node.
    "not" => parse_not,
    "or" => parse_or,
    "page"  => parse_page,
    "place"  => parse_place,
    #"pnml" => parse_pnml, #! Method should not be forun by parse_node.
    "productsort" => parse_productsort,
    "referencePlace"  => parse_refPlace,
    "referenceTransition"  => parse_refTransition,
    "sort" => parse_sort,
    "structure" => parse_structure,
    "term" => parse_term, #TODO is this valid?
    "text" => parse_text,
    "tokengraphics"  => parse_tokengraphics,
    "tokenposition" => parse_tokenposition,
    "toolspecific"  => parse_toolspecific,
    "transition"  => parse_transition,
    "tuple" => parse_tuple,
    "type" => parse_type,
    "unparsed" => parse_unparsed,
    "useroperator" => parse_useroperator,
    "usersort" => parse_usersort,
    "variable" => parse_variable,
    "variabledecl" => parse_variabledecl,

    # "add" => unclaimed_label,
    # "addition" => unclaimed_label,
    # "all" => unclaimed_label,
    # "anyName" => unclaimed_label,
    # "arctype" => unclaimed_label,
    # "attribute" => unclaimed_label,
    # "bool" => unclaimed_label,
    # "cardinality" => unclaimed_label,
    # "cardinalityof" => unclaimed_label,
    # "choice" => unclaimed_label,
    # "cyclicenumeration" => unclaimed_label,
    # "data" => unclaimed_label,
    # "def" => unclaimed_label,
    # "define" => unclaimed_label,
    # "dimension" => unclaimed_label,
    # "div" => unclaimed_label,
    # "dot" => unclaimed_label,
    # "dotconstant" => unclaimed_label,
    # "element" => unclaimed_label,
    # "empty" => unclaimed_label,
    # "emptylist" => unclaimed_label,
    # "except" => unclaimed_label,
    # "externalRef" => unclaimed_label,
    # "feconstant" => unclaimed_label,
    # "fill" => unclaimed_label,
    # "finiteenumeration" => unclaimed_label,
    # "finiteintrange" => unclaimed_label,
    # "finiteintrangeconstant" => unclaimed_label,
    # "font" => unclaimed_label,
    # "geq" => unclaimed_label,
    # "geqs" => unclaimed_label,
    # "grammar" => unclaimed_label,
    # "greaterthan" => unclaimed_label,
    # "greaterthanorequal" => unclaimed_label,
    # "group" => unclaimed_label,
    # "gt" => unclaimed_label,
    # "gtp" => unclaimed_label,
    # "gts" => unclaimed_label,
    # "include" => unclaimed_label,
    # "input" => unclaimed_label,
    # "integer" => unclaimed_label,
    # "interleave" => unclaimed_label,
    # "leq" => unclaimed_label,
    # "leqs" => unclaimed_label,
    # "lessthan" => unclaimed_label,
    # "lessthanorequal" => unclaimed_label,
    # "line" => unclaimed_label,
    # "list" => unclaimed_label,
    # "listappend" => unclaimed_label,
    # "listconcatenation" => unclaimed_label,
    # "listlength" => unclaimed_label,
    # "lt" => unclaimed_label,
    # "ltp" => unclaimed_label,
    # "lts" => unclaimed_label,
    # "makelist" => unclaimed_label,
    # "memberatindex" => unclaimed_label,
    # "mixed" => unclaimed_label,
    # "mod" => unclaimed_label,
    # "mult" => unclaimed_label,
    # "multisetsort" => unclaimed_label,
    # "namedsort" => unclaimed_label,
    # "natural" => unclaimed_label,
    # "notAllowed" => unclaimed_label,
    # "nsName" => unclaimed_label,
    # "numberconstant" => unclaimed_label,
    # "numberof" => unclaimed_label,
    # "offset" => unclaimed_label,
    # "oneOrMore" => unclaimed_label,
    # "optional" => unclaimed_label,
    # "output" => unclaimed_label,
    # "param" => unclaimed_label,
    # "parameter" => unclaimed_label,
    # "parentRef" => unclaimed_label,
    # "partition" => unclaimed_label,
    # "partitionelement" => unclaimed_label,
    # "partitionelementof" => unclaimed_label,
    # "position" => unclaimed_label,
    # "positive" => unclaimed_label,
    # "predecessor" => unclaimed_label,
    # "ref" => unclaimed_label,
    # "scalarproduct" => unclaimed_label,
    # "start" => unclaimed_label,
    # "string" => unclaimed_label,
    # "stringappend" => unclaimed_label,
    # "stringconcatenation" => unclaimed_label,
    # "stringconstant" => unclaimed_label,
    # "stringlength" => unclaimed_label,
    # "sublist"  => unclaimed_label,
    # "substring" => unclaimed_label,
    # "subterm" => unclaimed_label,
    # "subtract" => unclaimed_label,
    # "subtraction" => unclaimed_label,
    # "successor" => unclaimed_label,
    # "value" => unclaimed_label,
    # "zeroOrMore" => unclaimed_label,
)

