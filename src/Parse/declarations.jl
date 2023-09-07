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
Assume behavior of a High-level Net label in that the meaning is in a <structure>.

Expected format: <declaration> <structure> <declarations> <namedsort/> <namedsort/> ...
"""
function parse_declaration(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "declaration")
    decls::Maybe{Vector{AbstractDeclaration}} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]

    CONFIG.verbose && println("parse_declaration")
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        CONFIG.verbose && println("    $tag")
        if tag == "structure"
            decls = _parse_decl_structure(child, pntd, idregistry)
        elseif tag == "graphics"
            graphics => parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else # labels (unclaimed) are everything-else
            @warn "ignoring unexpected child of <declaration>: $tag"
        end
    end

    Declaration(something(decls, AbstractDeclaration[]), graphics, tools, node)
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

    def::Maybe{Term} = nothing
    parameters = VariableDeclaration[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "def"
            # NamedOperators have a def element that is a operator or variable term.
            def = parse_term(EzXML.firstelement(child), pntd, idregistry)
        elseif tag == "parameter"
            for vdecl in EzXML.eachelement(child)
                push!(parameters, parse_variabledecl(vdecl, pntd, idregistry))
            end
        else
            @warn "element '$tag' invalid as child of <namedoperator>, allowed: def, parameter"
        end
    end
    isnothing(def) && error("<namedoperator> $name $id does not have a <def> element")
    NamedOperator(id, name, parameters, def)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = check_nodename(node, "variabledecl")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute"))
    name = node["name"]
    # Assert only 1 element
    sort = parse_sort(EzXML.firstelement(node), pntd, idregistry)
    # XML attributes and the sort
    VariableDeclaration(id, name, sort) #TODO register id?
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = EzXML.nodename(node)
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn $id missing name attribute"))
    name = node["name"]

    @info("unknown declaration: tag = $nn id = $id name = $name")

    content = [anyelement(x, pntd, idregistry) for x in EzXML.eachelement(node) if x !== nothing]
    UnknownDeclaration(id, name, nn, content)
end

#------------------------
"""
$(TYPEDSIGNATURES)

Defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place from _many-sorted algebra_ is different from
the Petri Net "type" of a net or "pntd". Neither is directly a julia type.
"""
function parse_type end

# Allow all pntd's places to have a <type> label.
# Non high-level are expecting a numeric sort: eltype(sort) <: Number.
# See default_sort
function parse_type(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "type")
    text::Maybe{AbstractString} = nothing
    sortterm::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        @match tag begin
            "text"         => (text = parse_text(child, pntd, idregistry))
            "structure"    => (sortterm = parse_sorttype_term(child, pntd, idregistry))
            "graphics"     => (graphics = parse_graphics(child, pntd, idregistry))
            "toolspecific" => add_toolinfo!(tools, child, pntd, idregistry)
            _              => @warn("ignoring unexpected child of <type>: $tag")
        end
    end

    SortType(text, Ref{AbstractSort}(something(sortterm, default_sort(pntd)())), graphics, tools)
end

"""
$(TYPEDSIGNATURES)

#TODO where does this belong? A concrete subtype of [`AbstractSort`](@ref).
Built from many different elements that contain a Sort:
type, namedsort, variabledecl, multisetsort, productsort, numberconstant, partition...

Sort = BuiltInSort | MultisetSort | ProductSort | UserSort
"""
function parse_sorttype_term(typenode, pntd, idregistry)
    check_nodename(typenode, "structure")
    EzXML.haselement(typenode) || error("missing sort type term element in <structure>")
    term = EzXML.firstelement(typenode)

    # Expect a sort: usersort usually. No multiset sort here.
    ucl = unclaimed_label(term, pntd, idregistry)
    #println("sorttype declaration: "); dump(ucl)

    #TODO sort_ids and sort_tags should be "global constants"
    sort_ids = Symbol[:usersort, :multisetsort, :productsort, :partition,
                      :cyclicenumeration, :finiteenumeration, :finiteintrange,
                      :bool, :integer, :list, :string]

    sortid = ucl.first
    sortid ∈ sort_ids || @warn("invalid sort type '$sortid', allowed: $sort_ids")

    if sortid === :usersort
        @assert ucl.second isa Vector{AnyXmlNode}
        d = first(ucl.second)
        @assert tag(d) == :declaration
        @assert value(d) isa AbstractString
        idref = Symbol(value(d))
        t = UserSort(idref)
    elseif sortid === :dot
        t = DotSort()
    elseif sortid === :integer
        t = IntegerSort()
    elseif sortid === :natural
        t = NaturalSort()
    elseif sortid === :positive
        t = PositiveSort()
    elseif sortid === :bool
        t = BoolSort()

        #! XXX FINNISH this =========================================== XXX

    else
        error("parse_sorttype_term $sortid not implemented")
    end

    #println("sorttype_term"); dump(t)
    return t::AbstractSort
end

"""
$(TYPEDSIGNATURES)

Sorts are found within a <structure> element.
"""
function parse_sort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = EzXML.nodename(node)
    sort_tags = ["bool",
                 "finiteenumeration",
                 "finiteintrange",
                 "cyclicenumeration",
                 "dot",
                 "integer",
                 "natural",
                 "positive",
                 "mulitsetsort",
                 "productsort", # ordered list of sorts
                 "usersort",
                 "partition"]
    any(==(nn), sort_tags) || @warn("'$nn' is not a known sort in $sort_tags")
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

There will be no XML node 'term'.
Instead it is the interpertation of the child of some 'structure' or `def` elements.
The PNML specification describes Terms and Sorts as abstract types for the 'structure'
element of some [`HLAnnotation`](@ref).
"""
function parse_term(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    tag, value = unclaimed_label(node, pntd, reg)
    Term(tag, value)
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
    EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))

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
    EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))
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
