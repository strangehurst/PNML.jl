
"Attribute label of 'net' and 'page' nodes"
function parse_declaration(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "declaration" || error("parse_declaration element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"Annotation label of transition nodes. Meaning it can have text, graphics, et al."
function parse_condition(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "condition" || error("parse_condition element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    parse_pnml_label_common!.(Ref(d),elements(node); kwargs...)
    d
end


"Parse type of a place. Id different from net type or pntd."
function parse_type(node; kwargs...)
    nn = nodename(node)
    nn == "type" || error("parse_type element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
     parse_declarations(node; kwargs...)

Return NamedTuple with :contents holding a vector of parsed child elements.
"""
function parse_declarations(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "declarations" || error("parse_declarations element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

function parse_sort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "sort" || error("parse_sort element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

#=
There are many attribute-label elements.
These do not have the same characteristics as annotation-label elements.
The common usage is that 'label' usually be read as annotation-label
The graphics, toolspecific, text and structure of the common dictonary
are not useful.

Unknown tags get parsed by attribute_elem.  Annotation-labels usually have
known tags and dedicated dictonary keys. Pnml-node-elements put unregistered children
into the :labels collection.  It can include annotations and attributes.

Because any tag not present in the tagmap are processed by [`attribute_elem`](@ref)
it is not necessary to define a parse method unless valididation, documentation,
or additional processing is desired. Some are defined here anyway.
=#

"""
    parse_term(n)
"""
function parse_term(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "term" || error("parse_term element name wrong: $nn")
    attribute_elem(node; kwargs...)
end


""
function parse_and(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "and" || error("parse_and element name wrong: $nn")
    attribute_elem(node; kwargs...)
end


""
function parse_arbitraryoperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitraryoperator" || error("parse_arbitraryoperator element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_arbitrarysort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitrarysort" || error("parse_arbitrarysort element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_bool(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "bool" || error("parse_bool element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_booleanconstant(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "booleanconstant" || error("parse_booleanconstant element name wrong: $nn")
    has_declaration(node) || throw(MalformedException("$(nn) missing declaration attribute", node))
    attribute_elem(node; kwargs...)
end

""
function parse_equality(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "equality" || error("parse_equality element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_imply(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "imply" || error("parse_imply element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_inequality(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "inequality" || error("parse_inequality element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_mulitsetsort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "mulitsetsort" || error("parse_mulitsetsort element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_namedoperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "namedoperator" || error("parse_namedoperator element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_not(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "not" || error("parse_not element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_or(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "or" || error("parse_or element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_productsort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "productsort" || error("parse_productsort element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_tuple(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "tuple" || error("parse_tuple element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_unparsed(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "unparsed" || error("parse_unparsed element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

""
function parse_useroperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "useroperator" || error("parse_useroperator element name wrong: $nn")
    has_declaration(node) || throw(MalformedException("$(nn) missing declaration attribute", node))
    attribute_elem(node; kwargs...)
end

""
function parse_usersort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "usersort" || error("parse_usersort element name wrong: $nn")
    has_declaration(node) || throw(MalformedException("$(nn) missing declaration attribute", node))
    attribute_elem(node; kwargs...)
end

""
function parse_variable(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "variable" || error("parse_variable element name wrong: $nn")
    has_refvariable(node) || throw(MalformedException("$(nn) missing refvariable attribute", node))
    attribute_elem(node; kwargs...)
end

""
function parse_variabledecl(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "variabledecl" || error("parse_variabledecl element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_name(node) || throw(MalformedException("$(nn) missing name attribute", node))
    attribute_elem(node; kwargs...)
end
