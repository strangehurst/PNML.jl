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

Expected format: <declaration> <structure> <declarations> <namedsort/> <namedsort/> ...
"""
function parse_declaration(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "declaration")
    decls::Maybe{Vector{AbstractDeclaration}} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]

    CONFIG.verbose && println("parse_declaration")
    for child in eachelement(node)
        tag = EzXML.nodename(child)
        CONFIG.verbose && println("    $tag")
        if tag == "structure"
            decls = _parse_decl_structure(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics => parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            add_label!(labels, child, pntd, idregistry)
        end
    end

    Declaration(something(decls, AbstractDeclaration[]),
                ObjectCommon(graphics, tools, labels), node)
end

"Assumes high-level semantics until someone specializes. See [`decl_structure`](@ref)."
function _parse_decl_structure(node::XMLNode, pntd::T, idregistry) where {T <: PnmlType}
    decl_structure(node, pntd, idregistry)
end

# <declaration><structure><declarations><namedsort id="weight" name="Weight">...
# optional, required,  zero or more
"Return vector of AbstractDeclaration subtypes."
function decl_structure(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "structure")
    EzXML.haselement(node) || throw(ArgumentError("missing <declarations> element"))
    declarations = EzXML.firstelement(node)
    check_nodename(declarations, "declarations")
    decs = AbstractDeclaration[]
    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        CONFIG.verbose && println("    $tag")
        @match tag begin
            "namedsort"     => push!(decs, parse_namedsort(child, pntd, idregistry))
            "namedoperator" => push!(decs, parse_namedoperator(child, pntd, idregistry))
            "variabledecl"  => push!(decs, parse_variabledecl(child, pntd, idregistry))
            _ =>  push!(decs, parse_unknowndecl(child, pntd, idregistry))
        end
    end
    return decs
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "namedsort")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(reg, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn $id missing name attribute"))
    name = node["name"]

    def = parse_sort(EzXML.firstelement(node), pntd, reg)
    NamedSort(id, name, def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = check_nodename(node, "namedoperator")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn $id missing name attribute"))
    name = node["name"]

    @warn "namedoperator under development"

    def::Maybe{AbstractSort} = nothing
    parameters = VariableDeclaration[]
    for child in eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "def"
            def = parse_sort(child, pntd, idregistry)
        elseif tag == "parameter"
            for vdecl in EzXML.eachelement(child)
                push!(parameters, parse_variabledecl(vdecl, pntd, idregistry))
            end
        else
            @warn "$tag invalid, valid children of <namedoperator>: def, parameter"
        end
    end
    isnothing(def) && error("<namedoperator> $name $id does not have a <def>")
    NamedOperator(id, name, parameters, def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = check_nodename(node, "variabledecl")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException(lazy"$nn missing name attribute"))
    name = node["name"]
    # Assert only 1 element
    sort = parse_sort(EzXML.firstelement(node), pntd, idregistry)
    # XML attributes and the sort
    VariableDeclaration(id, name, sort) #TODO register id?
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = nodename(node)
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn $id missing name attribute"))
    name = node["name"]

    @info("unknown declaration: $nn $id $name")

    content = [anyelement(x, pntd, reg) for x in EzXML.eachelement(node) if x !== nothing]
    UnknownDeclaration(id, name, nn, content)
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

function parse_type(hlnode::XMLNode, pntd::PNTD, idregistry::PnmlIDRegistry) where {PNTD <: AbstractHLCore}
    check_nodename(hlnode, "type")
    text::Maybe{AbstractString} = nothing
    term::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]
    labels = PnmlLabel[]

    for child in EzXML.eachelement(hlnode)
        tag = EzXML.nodename(child)
        @match nodename(child) begin
            "text"         => (text = parse_text(child, pntd, idregistry))
            "structure"    => (term = parse_sorttype_term(child, pntd, idregistry))
            "graphics"     => (graphics = parse_graphics(child, pntd, idregistry))
            "toolspecific" => add_toolinfo!(tools, child, pntd, idregistry)
            _              => add_label!(labels, child, pntd, idregistry) # (unclaimed) are everything-else
        end
    end

    SortType(text, something(term, default_sort(pntd)), ObjectCommon(graphics, tools, labels))
end

# Sort type for non-high-level meaning is TBD and non-standard.
function parse_type(node::XMLNode, pntd::PNTD, idregistry::PnmlIDRegistry) where {PNTD <: PnmlType}
    check_nodename(node, "type")
    # Parse as unclaimed label. Then assume it is a `number_value` for non-High-Level nets.
    # First use-case of technique is `rate` of `ContinuousNet`.
    ucl = unclaimed_label(node, pntd, idregistry)
    CONFIG.verbose && @show ucl
    SortType("default sorttype", Term(:sorttype, [AnyXmlNode(ucl)]))
    @assert ucl.second[1] isa AbstractString
    return numeric_label_value(sort_type(pntd), ucl.second[1]) #TODO This should conform to the TBD `Sort` interface.
end

# not a label
parse_sorttype_term(typenode, pntd, idregistry) = begin
    check_nodename(typenode, "structure")
    term = EzXML.firstelement(typenode)
    if !isnothing(term)
        t = parse_term(term, pntd, idregistry)
    else
        # Handle an empty <structure>.
        t = default_sort(pntd)
    end
    return t
end

"""
$(TYPEDSIGNATURES)

Sorts are found within a <structure> element.
"""
function parse_sort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = nodename(node)
    sort_tags = [
        "bool", #TODO BoolSort
        "finiteenumeration",
        "finiteintrange",
        "cyclicenumeration",
        "dot", #TODO DotSort
        "mulitsetsort",
        "productsort", # ordered list of sorts
        "usersort",
        "partition"]
    any(==(nn), sort_tags) || error("'$nn' is not a known sort in $sort_tags")
    anyelement(node, pntd, reg)
end


# NamedSort id, name

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "usersort")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))
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
    nn = EzXML.nodename(node)
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
    EzXML.haskey(node, "declaration") || throw(MalformedException(lazy"$nn missing declaration attribute"))

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
    check_nodename(node, "unparsed")
    PnmlLabel(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_useroperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    check_nodename(node, "useroperator")
    EzXML.haskey(node, "declaration") || throw(MalformedException(lazy"$nn missing declaration attribute"))
    UserOperator(Symbol(node["declaration"]))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "variable")
    # The 'primer' UML2 uses variableDecl
    EzXML.haskey(node, "refvariable") || throw(MalformedException("$nn missing refvariable attribute"))
    Variable(Symbol(node["refvariable"]))
end
