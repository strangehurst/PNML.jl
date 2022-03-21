#=
There are many attribute-label elements.
The common usage is that 'label' usually be read as annotation-label.

Attribute-labels do not have associated graphics elements. Since <graphics> are
optional for annotation-labels they share the same implementation.

Unknown tags get parsed by unclaimed_label.  Annotation-labels usually have
known tags and dedicated dictonary keys. Pnml-node-elements put unregistered children
into the :labels collection.  It can include annotations and attributes.

Because any tag not present in the tagmap are processed by `unclaimed_label`
it is not necessary to define a parse method unless valididation, documentation,
or additional processing is desired. Some are defined here anyway.
=#

"""
$(TYPEDSIGNATURES)

Return [`Declaration`](@ref) label of 'net' and 'page' nodes.
"""
function parse_declaration(node; kw...)
    nn = nodename(node)
    nn == "declaration" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))

    # <declaration><structure><declarations><namedsort id="weight" name="Weight">...
    # optional,     required,  zero or more
    decl_structure(nv::Vector{XMLNode}) =
            isempty(nv) ? AbstractDeclaration[] : parse_declarations.(nv; kw...)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # <declaration>'s <structure> contains a vector of declarations. Usually 1.
            "structure" => (d[:structure] = decl_structure(allchildren("declarations",node)))
            _ => parse_pnml_label_common!(d, child; kw...)
         end
    end
   Declaration(d)
end

"""
Return an Vector{[`AbstractDeclaration`](@ref)} subtype,

$(TYPEDSIGNATURES)
"""
function parse_declarations(node; kw...)::Vector{AbstractDeclaration}
    nn = nodename(node)
    nn == "declarations" || error("element name wrong: $nn")
    v = AbstractDeclaration[]
    foreach(elements(node)) do child
        @match nodename(child) begin
            "namedsort" => push!(v, parse_namedsort(child; kw...))
            "namedoperator" => push!(v, parse_namedoperator(child; kw...))
            "variabledecl" => push!(v, parse_variabledecl(child; kw...))
            _ => @error("$nn is not a known declaration tag")
        end
    end
    return v
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedsort(node; kw...)
    @debug node
    nn = nodename(node)
    nn == "namedsort" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))
    def = parse_sort(firstelement(node); kw...)
    NamedSort(node["id"], node["name"], def; kw...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedoperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "namedoperator" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$(nn) missing name attribute", node))
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node; kw...)
    nn = nodename(node)
    nn == "variabledecl" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$(nn) missing name attribute", node))
    # Sort
    PnmlLabel(node; kw...)
end

#------------------------
"""
Defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place is different from the "type" of a net or "pntd".

$(TYPEDSIGNATURES)
"""
function parse_type(node; kwargs...)
    nn = nodename(node)
    nn == "type" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_sort(node; kwargs...)
    nn = nodename(node)
    nn == "sort" || error("element name wrong: $nn")
    @match nodename(child) begin
        #Booleans, range of integers, finite enumerations, cyclic enumerations and dots
        "bool" => (def = anyelement(child; kw...))
        "finiteenumeration" => (def = anyelement(child; kw...))
        "finiterange" => (def = anyelement(child; kw...))
        "cyclicenumeration" => (def = anyelement(child; kw...))
        "dot" => (def = anyelement(child; kw...))
        _ => @error("$nn is not a known declaration tag")
    end
    PnmlLabel(node; kwargs...)
end
# BuiltInSort
# MultisetSort
# ProductSort ordered list of sorts
# UserSort

# NamedSort id, name

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "usersort" || error("element name wrong: $nn")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    PnmlLabel(node; kwargs...)
end


"""
$(TYPEDSIGNATURES)
"""
function parse_term(node; kwargs...)
    nn = nodename(node)
    nn == "term" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end
# Variable
# Operator

"""
$(TYPEDSIGNATURES)
"""
function parse_and(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "and" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitraryoperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitraryoperator" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitrarysort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitrarysort" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_bool(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "bool" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "booleanconstant" || error("element name wrong: $nn")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "equality" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "imply" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "inequality" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_mulitsetsort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "mulitsetsort" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_not(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "not" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "or" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_productsort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "productsort" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "tuple" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "unparsed" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_useroperator(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "useroperator" || error("element name wrong: $nn")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "variable" || error("element name wrong: $nn")
    EzXML.haskey(node, "refvariable") || throw(MalformedException("$(nn) missing refvariable attribute", node))
    PnmlLabel(node; kwargs...)
end
