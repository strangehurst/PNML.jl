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
    nn = check_nodename(node, "declaration")
    @debug nn
    d = pnml_label_defaults(node, :tag=>Symbol(nn))

    foreach(elements(node)) do child
        @match nodename(child) begin
            "structure" => (d[:structure] = decl_structure(child, pntd; kw...))
            _ => parse_pnml_label_common!(d, child, pntd; kw...)
         end
    end
    Declaration(d[:structure], ObjectCommon(d), node)
end

# <declaration><structure><declarations><namedsort id="weight" name="Weight">...
# optional, required,  zero or more
function decl_structure(node, pntd; kw...)
    nn = check_nodename(node, "structure")
    @debug nn
    #TODO warn if more than one?
    declarations = firstchild("declarations", node)
    isnothing(declarations) ? AbstractDeclaration[] :
                            parse_declarations(declarations, pntd; kw...)
end

"""
$(TYPEDSIGNATURES)

Return an Vector{[`AbstractDeclaration`](@ref)} subtype,
"""
function parse_declarations(node, pntd; kw...)
    nn = check_nodename(node, "declarations")

    v = AbstractDeclaration[]
    foreach(elements(node)) do child
        @match nodename(child) begin
            "namedsort" => push!(v, parse_namedsort(child, pntd; kw...))
            "namedoperator" => push!(v, parse_namedoperator(child, pntd; kw...))
            "variabledecl" => push!(v, parse_variabledecl(child, pntd; kw...))
            _ =>  push!(v, parse_unknowndecl(child, pntd; kw...))
        end
    end
    return v
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedsort(node, pntd; kw...)
    nn = check_nodename(node, "namedsort")
    @debug nn
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))

    def = parse_sort(firstelement(node), pntd; kw...)
    NamedSort(register_id!(kw[:reg], node["id"]), node["name"], def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedoperator(node, pntd; kw...)
    nn = check_nodename(node, "namedoperator")
    @debug nn
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$(nn) missing name attribute", node))

    @warn "namedoperator under development"

    defnode = getfirst("def", node)
    isnothing(defnode) && error("namedoperator does not have a <def>")
    def = parse_sort(defnode, pntd; kw...)

    # <parameter> holds zero or more VariableDeclaration
    parnode = getfirst("parameter", node)
    isnothing(parnode) && error("namedoperator does not have a <parameters>")
    parameters = if isnothing(parnode)
        [default_term(pntd)]
    else
        [x->parse_variabledecl(x, pntd; kw...) in elements(parnode)]
    end
    NamedOperator(register_id!(kw[:reg], node["id"]), node["name"], parameters, def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node, pntd; kw...)
    nn = check_nodename(node, "variabledecl")

    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))
    # Assert only 1 element
    sort = parse_sort(firstelement(node), pntd; kw...)
    # XML attributes and the sort
    VariableDeclaration(Symbol(node["id"]), node["name"], sort) #TODO register id?
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType; kw...)
    nn = nodename(node)
    @info("unknown declaration: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute", node))

    content = [anyelement(x, pntd; kw...) for x in elements(node) if x !== nothing] #TODO Turn children into?
    @show length(content), typeof(content)
    UnknownDeclaration(Symbol(node["id"]), node["name"], nn, content)
end

#------------------------
"""
$(TYPEDSIGNATURES)

Defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place is different from the "type" of a net or "pntd".

"""
function parse_type(node::XMLNode, pntd::PnmlType; kw...)
    nn = check_nodename(node, "type")
    @debug nn
    anyelement(node, pntd; kw...) #TODO implement sort type
end

"""
$(TYPEDSIGNATURES)

Sorts are found within a <structure> element.
"""
function parse_sort(node, pntd; kw...)
    nn = nodename(node)
    @debug nn
    sort_tags = [
        "bool",
        "finiteenumeration",
        "finiteintrange",
        "cyclicenumeration",
        "dot",
        "mulitsetsort",
        "productsort",
        "usersort",
        "partition"]
    if !any(==(nn), sort_tags)
        error("'$nn' is not a known sort in $sort_tags")
    end
    anyelement(node, pntd; kw...)
end
# BuiltInSort
# MultisetSort
# ProductSort ordered list of sorts
# UserSort

# NamedSort id, name

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node, pntd; kw...)
    nn = check_nodename(node, "usersort")
    @debug nn
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    UserSort(anyelement(node, pntd; kw...))
end


"""
$(TYPEDSIGNATURES)

There will be no node <term>.
Instead it is the interpertation of the child of some <structure> elements.
"""
function parse_term(node, pntd; kw...)
    nn = nodename(node)
    @debug nn
    #TODO Validate that it is a kind of term? How? nn == "term" || error("element name wrong: $nn")
    Term(unclaimed_label(node, pntd; kw...))
end

#! TODO Variable is one kind of term.
#! TODO Operator is another kind of term.

"""
$(TYPEDSIGNATURES)
"""
function parse_and(node, pntd; kw...)
    nn = check_nodename(node, "and")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitraryoperator(node, pntd; kw...)
    nn = check_nodename(node, "arbitraryoperator")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitrarysort(node, pntd; kw...)
    nn = check_nodename(node, "arbitrarysort")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_bool(node, pntd; kw...)
    nn = check_nodename(node, "bool")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node, pntd; kw...)
    nn = check_nodename(node, "booleanconstant")
    @debug nn
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node, pntd; kw...)
    nn = check_nodename(node, "equality")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node, pntd; kw...)
    nn = check_nodename(node, "imply")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node, pntd; kw...)
    nn = check_nodename(node, "inequality")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_mulitsetsort(node, pntd; kw...)
    nn = check_nodename(node, "mulitsetsort")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_not(node, pntd; kw...)
    nn = check_nodename(node, "not")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node, pntd; kw...)
    nn = check_nodename(node, "or")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_productsort(node, pntd; kw...)
    nn = check_nodename(node, "productsort")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node, pntd; kw...)
    nn = check_nodename(node, "tuple")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node, pntd; kw...)
    nn = check_nodename(node, "unparsed")
    @debug nn
    #PnmlLabel(node; kw...)
    PnmlLabel(unclaimed_label(node, pntd; kw...), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_useroperator(node, pntd; kw...)
    nn = check_nodename(node, "useroperator")
    @debug nn
    EzXML.haskey(node, "declaration") || throw(MalformedException("$(nn) missing declaration attribute", node))
    UserOperator(Symbol(node["declaration"]))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node, pntd; kw...)
    nn = check_nodename(node, "variable")
    @debug nn
    # The 'primer' UML2 uses variableDecl
    EzXML.haskey(node, "refvariable") || throw(MalformedException("$(nn) missing refvariable attribute", node))
    Variable(Symbol(node["refvariable"]))
end
