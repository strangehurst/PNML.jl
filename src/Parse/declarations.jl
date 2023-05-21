#=
There are many attribute-label elements.
The common usage is that 'label' usually be read as annotation-label.

Attribute-labels do not have associated graphics elements. Since <graphics> are
optional for annotation-labels they share the same implementation.

Unknown tags get parsed by `unclaimed_label`.  Annotation-labels usually have
known tags and dedicated parsers. `parse_pnml_object_common` puts unregistered children
into the labels collection of a [`AbstractPnmlObject`].  It can include annotations and attributes.

Because any tag not present in the tagmap are processed by `unclaimed_label`
it is not necessary to define a parse method unless valididation, documentation,
or additional processing is desired. Some are defined here anyway.
=#

"""
$(TYPEDSIGNATURES)

Return [`Declaration`](@ref) label of 'net' and 'page' nodes.
Assume behavior of a High-level Net label in that the meaning is in a <struct>.
"""
function parse_declaration(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "declaration")
    tup = pnml_label_defaults(:tag=>Symbol(nn))
    CONFIG.verbose && println("parse_declaration")
    for child in eachelement(node)
        tag = nodename(child)
        CONFIG.verbose && println(lazy"    $tag")
        if tag == "structure"
            tup = merge(tup, [:decls => _parse_decl_structure(child, pntd, reg)])
        else
            # This is here <text> gets parsed.
            tup = parse_pnml_label_common(tup, child, pntd, reg)
        end
    end

    #@show tup
    decls = hasproperty(tup, :decls) ? tup.decls : Any[]
    Declaration(decls, ObjectCommon(tup), node)
end

"Assumes high-level semantics until someone specializes. See [`decl_structure`](@ref)."
function _parse_decl_structure(node::XMLNode, pntd::T, reg) where {T <: PnmlType}
    decl_structure(node, pntd, reg)
end

# <declaration><structure><declarations><namedsort id="weight" name="Weight">...
# optional, required,  zero or more
"Return vector of "
function decl_structure(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    check_nodename(node, "structure")
    declarations = firstchild("declarations", node)
    decs = AbstractDeclaration[]
    if !isnothing(declarations)
        for child in eachelement(declarations)
            tag = EzXML.nodename(child)
            CONFIG.verbose && println(lazy"    $tag")
            @match tag begin
                "namedsort"     => push!(decs, parse_namedsort(child, pntd, reg))
                "namedoperator" => push!(decs, parse_namedoperator(child, pntd, reg))
                "variabledecl"  => push!(decs, parse_variabledecl(child, pntd, reg))
                _ =>  push!(decs, parse_unknowndecl(child, pntd, reg))
            end
        end
    end
    return decs
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "namedsort")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException(lazy"$nn missing name attribute", node))

    def = parse_sort(firstelement(node), pntd, reg)
    NamedSort(register_id!(reg, node["id"]), node["name"], def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "namedoperator")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException(lazy"$nn missing name attribute", node))

    @warn "namedoperator under development"

    defnode = getfirst("def", node)
    isnothing(defnode) && error("namedoperator does not have a <def>")
    def = parse_sort(defnode, pntd, reg)

    # <parameter> holds zero or more VariableDeclaration
    parnode = getfirst("parameter", node)
    isnothing(parnode) && error("namedoperator does not have a <parameters>")
    parameters = if isnothing(parnode)
        [default_term(pntd)] # Vector for type stability.
    else
        [x->parse_variabledecl(x, pntd, reg) in EzXML.eachelement(parnode)]
    end
    NamedOperator(register_id!(reg, node["id"]), node["name"], parameters, def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "variabledecl")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException(lazy"$nn missing name attribute", node))
    # Assert only 1 element
    sort = parse_sort(firstelement(node), pntd, reg)
    # XML attributes and the sort
    VariableDeclaration(Symbol(node["id"]), node["name"], sort) #TODO register id?
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = nodename(node)
    @info("unknown declaration: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "name") || throw(MalformedException(lazy"$nn missing name attribute", node))

    content = [anyelement(x, pntd, reg) for x in EzXML.eachelement(node) if x !== nothing]
    #@show length(content), typeof(content)
    UnknownDeclaration(Symbol(node["id"]), node["name"], nn, content)
end

#------------------------
"""
$(TYPEDSIGNATURES)

Defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place from _many-sorted algebra_ is different from
the Petri Net "type" of a net or "pntd".
Neither is directly a julia type.
"""
function parse_type end

function parse_type(node::XMLNode, pntd::PNTD, idregistry::PnmlIDRegistry) where {PNTD <: AbstractHLCore}
    nn = check_nodename(node, "type")
    tup = pnml_label_defaults(:tag => Symbol(nn))

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "structure"
            tup = parse_sorttype_term(tup, child, pntd, idregistry)
        else
            tup = parse_pnml_label_common(tup, child, pntd, idregistry)
        end
    end

    term = hasproperty(tup, :term) ? tup.term : default_sort(pntd)
    SortType(tup.text, term, ObjectCommon(tup))
end

parse_sorttype_term(tup::NamedTuple, node, pntd, idregistry) = begin
    check_nodename(node, "structure")
    if EzXML.haselement(node)
        t = parse_term(EzXML.firstelement(node), pntd, idregistry)
    else
        # Handle an empty <structure>.
        t = default_sort(pntd)
    end
    return merge(tup, (; :term => t))
end

# Sort type for non-high-level meaning is TBD and non-standard.
function parse_type(node::XMLNode, pntd::PNTD, idregistry::PnmlIDRegistry) where {PNTD <: PnmlType}
    check_nodename(node, "type")
    # Parse as unclaimed label. Then assume it is a `number_value` for non-High-Level nets.
    # First use-case is `rate` of `ContinuousNet`.
    ucl = unclaimed_label(node, pntd, idregistry)
    CONFIG.verbose && @show ucl
    #@show dump(ucl)
    return numeric_label_value(sort_type(pntd), ucl.second) #TODO This should conform to the TBD `Sort` interface.
end


"""
$(TYPEDSIGNATURES)

Sorts are found within a <structure> element.
"""
function parse_sort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = nodename(node)
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
        error(lazy"'$nn' is not a known sort in $sort_tags")
    end
    anyelement(node, pntd, reg)
end
# BuiltInSort
# MultisetSort
# ProductSort ordered list of sorts
# UserSort

# NamedSort id, name

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "usersort")
    EzXML.haskey(node, "declaration") || throw(MalformedException(lazy"$nn missing declaration attribute", node))
    UserSort(anyelement(node, pntd, reg))
end


"""
$(TYPEDSIGNATURES)

There will be no node <term>.
Instead it is the interpertation of the child of some <structure> elements.
The PNML specification describes Terms and Sorts as abstract types for the <structure>
element of some [`HLAnnotation`](@ref).
"""
function parse_term(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = nodename(node)
    #TODO Validate that it is a kind of term? How? nn == "term" || error("element name wrong: $nn")
    Term(unclaimed_label(node, pntd, reg))
end

#! TODO Terms kinds are Variable and Operator

"""
$(TYPEDSIGNATURES)
"""
function parse_and(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "and")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitraryoperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "arbitraryoperator")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitrarysort(node, pntd, reg)
    nn = check_nodename(node, "arbitrarysort")
    PnmlLabel(unclaimed_label(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_bool(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "bool")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "booleanconstant")
    EzXML.haskey(node, "declaration") || throw(MalformedException(lazy"$nn missing declaration attribute", node))
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "equality")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "imply")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "inequality")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_mulitsetsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "mulitsetsort")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_not(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "not")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "or")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_productsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "productsort")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "tuple")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "unparsed")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_useroperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "useroperator")
    EzXML.haskey(node, "declaration") ||
        throw(MalformedException(lazy"$nn missing declaration attribute", node))
    UserOperator(Symbol(node["declaration"]))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "variable")
    # The 'primer' UML2 uses variableDecl
    EzXML.haskey(node, "refvariable") ||
        throw(MalformedException(lazy"$nn missing refvariable attribute", node))
    Variable(Symbol(node["refvariable"]))
end
