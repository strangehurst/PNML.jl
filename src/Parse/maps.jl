# Ideas from MathML.jl

#TODO: use pnml tag names instead of mathml?
"""
$(TYPEDEF)
"""
applymap = Dict{String,Function}(
    "times" => Base.prod, # arity 2, but prod fine
    # "prod" => Base.prod,
    "divide" => x -> Base.:/(x...),
    "power" => x -> Base.:^(x...),
    "plus" => x -> Base.:+(x...),
    "minus" => x -> Base.:-(x...),
    # Lots more functions possible
)


"""
Map XML tag names to parser functions.

$(TYPEDEF)
"""
tagmap = Dict{String,Function}(
    # Assumes all child elements have an entry in tagmap
    #""  => x -> map(parse_node, elements(x)),

    "arc"  => parse_arc,
    "condition" => parse_condition,
    "declaration" => parse_declaration,
    "declarations"  => parse_declarations,
    "graphics" => parse_graphics,
    "hlinitialMarking" => parse_hlinitialMarking,
    "hlinscription" => parse_hlinscription,
    "initialMarking" => parse_initialMarking,
    "inscription" => parse_inscription,
    "label" => parse_label,
    "name" => parse_name,
    "net" => parse_net,
    "page"  => parse_page,
    "place"  => parse_place,
    "pnml" => parse_pnml,
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
    "type" => parse_type,
    
    # Parts of declaratuons, types, sorts, inscription, condition, marking
    # These are expected to be under a structure element.
    "and" => parse_and,
    "arbitraryoperator" => parse_arbitraryoperator,
    "arbitrarysort" => parse_arbitrarysort,
    "bool" => parse_bool,
    "booleanconstant" => parse_booleanconstant,
    "equality" => parse_equality,
    "imply" => parse_imply,
    "inequality" => parse_inequality,
    "mulitsetsort" => parse_mulitsetsort,
    "namedoperator" => parse_namedoperator,
    "not" => parse_not,
    "or" => parse_or,
    "productsort" => parse_productsort,
    "tuple" => parse_tuple,
    "unparsed" => parse_unparsed,
    "useroperator" => parse_useroperator,
    "usersort" => parse_usersort,
    "variable" => parse_variable,
    "variabledecl" => parse_variabledecl,
)

