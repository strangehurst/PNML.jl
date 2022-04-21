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
function parse_declaration(node, pntd; kw...)
    nn = nodename(node)
    nn == "declaration" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
   
    foreach(elements(node)) do child
        @match nodename(child) begin
            "structure" => (d[:structure] = decl_structure(child, pntd; kw...))
            _ => parse_pnml_label_common!(d, child, pntd; kw...)
         end
    end
   Declaration(d)
end

# <declaration><structure><declarations><namedsort id="weight" name="Weight">...
# optional,     required,  zero or more
function decl_structure(node, pntd; kw...)
    nn = nodename(node)
    nn == "structure" || error("element name wrong: $nn")
    declarations = getfirst("declarations", node)
    isnothing(declarations) ? AbstractDeclaration[] : parse_declarations(declarations, pntd; kw...)
end

"""
$(TYPEDSIGNATURES)

Return an Vector{[`AbstractDeclaration`](@ref)} subtype,
"""
function parse_declarations(node, pntd; kw...)
    nn = nodename(node)
    nn == "declarations" || error("element name wrong: $nn") 

    v = AbstractDeclaration[]
    foreach(elements(node)) do child
        @match nodename(child) begin
            "namedsort" => push!(v, parse_namedsort(child, pntd; kw...))
            "namedoperator" => push!(v, parse_namedoperator(child, pntd; kw...))
            "variabledecl" => push!(v, parse_variabledecl(child, pntd; kw...))
            _ =>  push!(v, parse_unknowndecl(child, pntd; kw...))
            #@warn("$(nodename(child)) is not a known declaration tag")
        end
    end
    return v
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedsort(node, pntd; kw...)
    nn = nodename(node)
    nn == "namedsort" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))

    def = parse_sort(firstelement(node), pntd; kw...)
    NamedSort(register_id!(kw[:reg], node["id"]), node["name"], def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedoperator(node, pntd; kw...)
    nn = nodename(node)
    nn == "namedoperator" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$(nn) missing name attribute", node))

    @warn "namedoperator under test"
    # <parameter> holds zero or more VariableDeclaration
    def = parse_sort(getfirst("def", node), pntd; kw...)
    parameters = parse_variabledecl.(elements(getfirst("parameter", node)), Ref(pntd); kw...)
    NamedOperator(register_id!(kw[:reg], node["id"]), node["name"], def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node, pntd; kw...)
    nn = nodename(node)
    nn == "variabledecl" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))

    sort = parse_sort(firstelement(node), pntd; kw...)

    VariableDeclaration(Symbol(node["id"]), node["name"], sort)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node, pntd; kw...)
    nn = nodename(node)
    @info("unknown declaration: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))

    #TODO Turn all children into anyelements?
    content = anyelement.(elements(node), Ref(pntd); kw...)
    UnknownDeclaration(Symbol(node["id"]), node["name"], nn, content)
end

#------------------------
"""
Defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place is different from the "type" of a net or "pntd".

$(TYPEDSIGNATURES)
"""
function parse_type(node, pntd; kwargs...)
    nn = nodename(node)
    nn == "type" || error("element name wrong: $nn")
    anyelement(node, pntd; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_sort(node, pntd; kw...)
    nn = nodename(node)
    # Builtin
    sort =  nn == "bool" ? anyelement(node, pntd; kw...) :
            nn == "finiteenumeration" ? anyelement(node, pntd; kw...) :
            nn == "finiteintrange" ? anyelement(node, pntd; kw...) :
            nn == "cyclicenumeration"  ? anyelement(node, pntd; kw...) : 
            nn == "dot" ? anyelement(node, pntd; kw...) : 
            # Also do these.
            nn == "mulitsetsort" ? anyelement(node, pntd; kw...) :
            nn == "productsort" ? anyelement(node, pntd; kw...) :
            nn == "usersort" ? anyelement(node, pntd; kw...) : nothing
    #TODO partition
    isnothing(sort) && error("$nn is not a known sort")
    return sort
end
# BuiltInSort
# MultisetSort
# ProductSort ordered list of sorts
# UserSort

# NamedSort id, name

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "usersort" || error("element name wrong: $nn")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    UserSort(anyelement(node, pntd; kwargs...))
end


"""
$(TYPEDSIGNATURES)

There will be no node <term>. 
Instead it is the interpertation of the child of some <structure> elements.
"""
function parse_term(node, pntd; kwargs...)
    nn = nodename(node)
    #TODO Validate that it is a kind of term? How? nn == "term" || error("element name wrong: $nn")
    Term(unclaimed_label(node, pntd; kwargs...))
end

#! TODO Variable is one kind of term.
#! TODO Operator is another kind of term.

"""
$(TYPEDSIGNATURES)
"""
function parse_and(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "and" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitraryoperator(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitraryoperator" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitrarysort(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "arbitrarysort" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_bool(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "bool" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "booleanconstant" || error("element name wrong: $nn")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "equality" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "imply" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "inequality" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_mulitsetsort(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "mulitsetsort" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_not(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "not" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "or" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_productsort(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "productsort" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "tuple" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "unparsed" || error("element name wrong: $nn")
    PnmlLabel(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_useroperator(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "useroperator" || error("element name wrong: $nn")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    UserOperator(Symbol(node["declaration"]))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node, pntd; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "variable" || error("element name wrong: $nn")
    # The 'primer' UML2 uses variableDecl
    EzXML.haskey(node, "refvariable") || throw(MalformedException("$(nn) missing refvariable attribute", node))
    Variable(Symbol(node["refvariable"]))
end
