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
    @info "parse declaration"
   
    foreach(elements(node)) do child
        @match nodename(child) begin
            "structure" => (d[:structure] = decl_structure(child; kw...))
            _ => parse_pnml_label_common!(d, child; kw...)
         end
    end
   Declaration(d)
end

# <declaration><structure><declarations><namedsort id="weight" name="Weight">...
# optional,     required,  zero or more
function decl_structure(node; kw...)
    @info "decl_structure"
    nn = nodename(node)
    nn == "structure" || error("element name wrong: $nn")
    declarations = getfirst("declarations", node)
    isnothing(declarations) ? AbstractDeclaration[] : parse_declarations(declarations; kw...)
end

"""
$(TYPEDSIGNATURES)

Return an Vector{[`AbstractDeclaration`](@ref)} subtype,
"""
function parse_declarations(node; kw...)
    nn = nodename(node)
    nn == "declarations" || error("element name wrong: $nn") 
    @info "parse declarations"

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
    nn = nodename(node)
    nn == "namedsort" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))

    def = parse_sort(firstelement(node); kw...)
    #@show typeof(def), def
    NamedSort(register_id!(kw[:reg], node["id"]), node["name"], def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedoperator(node; kwargs...)
    nn = nodename(node)
    nn == "namedoperator" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$(nn) missing name attribute", node))
    anyelement(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node; kw...)
    nn = nodename(node)
    nn == "variabledecl" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))
    # Sort
    sort = parse_sort(firstelement(node); kw...)

    VariableDeclaration(Symbol(node["id"]), node["name"], sort)
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
    anyelement(node; kwargs...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_sort(node; kw...)
    nn = nodename(node)
    # Builtin
    sort =  nn == "bool" ? anyelement(node; kw...) :
            nn == "finiteenumeration" ? anyelement(node; kw...) :
            nn == "finiterange" ? anyelement(node; kw...) :
            nn == "cyclicenumeration"  ? anyelement(node; kw...) : 
            nn == "dot" ? anyelement(node; kw...) : 
            # Also do these.
            nn == "mulitsetsort" ? anyelement(node; kw...) :
            nn == "productsort" ? anyelement(node; kw...) :
            nn == "usersort" ? anyelement(node; kw...) : nothing
 
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
function parse_usersort(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "usersort" || error("element name wrong: $nn")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    UserSort(anyelement(node; kwargs...))
end


"""
$(TYPEDSIGNATURES)

There will be no node <term>. 
Instead it is the interpertation of the child of some <structure> elements.
"""
function parse_term(node; kwargs...)
    nn = nodename(node)
    #TODO validate? nn == "term" || error("element name wrong: $nn")
    Term(unclaimed_label(node; kwargs...))
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
    UserOperator(Symbol(node["declaration"]))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node; kwargs...)
    @debug node
    nn = nodename(node)
    nn == "variable" || error("element name wrong: $nn")
    # The 'primer' UML2 uses variableDecl
    EzXML.haskey(node, "refvariable") || throw(MalformedException("$(nn) missing refvariable attribute", node))
    Variable(Symbol(node["refvariable"]))
end
