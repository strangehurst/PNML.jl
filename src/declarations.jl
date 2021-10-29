#=
There are many attribute-label elements.
These do not have the same characteristics as annotation-label elements.
The common usage is that 'label' usually be read as annotation-label
The graphics, text and structure tags of the common dictonary
are not useful for attributes.

Unknown tags get parsed by attribute_elem.  Annotation-labels usually have
known tags and dedicated dictonary keys. Pnml-node-elements put unregistered children
into the :labels collection.  It can include annotations and attributes.

Because any tag not present in the tagmap are processed by [`attribute_elem`](@ref)
it is not necessary to define a parse method unless valididation, documentation,
or additional processing is desired. Some are defined here anyway.
=#

"""
$(TYPEDSIGNATURES)

Attribute label of 'net' and 'page' nodes.
"""
function parse_declaration(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "declaration" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)

These type of a place is different from net type or pntd.
Used to define the "sort" of tokens held by the place and semantics of the marking.
"""
function parse_type(node; kwargs...)
    nn = nodename(node)
    nn == "type" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_declarations(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "declarations" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_sort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "sort" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_term(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "term" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_and(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "and" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitraryoperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitraryoperator" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitrarysort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitrarysort" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_bool(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "bool" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "booleanconstant" || error("element name wrong: $nn")
    has_declaration(node) || throw(MalformedException("$(nn) missing declaration attribute", node))
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node; kwargs...)
    @debug node
    nn   = nodename(node)
    nn == "equality" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "imply" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "inequality" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_mulitsetsort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "mulitsetsort" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedoperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "namedoperator" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_not(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "not" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "or" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_productsort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "productsort" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "tuple" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "unparsed" || error("element name wrong: $nn")
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_useroperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "useroperator" || error("element name wrong: $nn")
    has_declaration(node) || throw(MalformedException("$(nn) missing declaration attribute", node))
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "usersort" || error("element name wrong: $nn")
    has_declaration(node) || throw(MalformedException("$(nn) missing declaration attribute", node))
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "variable" || error("element name wrong: $nn")
    has_refvariable(node) || throw(MalformedException("$(nn) missing refvariable attribute", node))
    attribute_elem(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "variabledecl" || error("element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_name(node) || throw(MalformedException("$(nn) missing name attribute", node))
    attribute_elem(node; kwargs...)
end
