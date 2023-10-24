#=
There are many attribute-label elements.
The common usage is that 'label' usually be read as annotation-label.

Attribute-labels do not have associated graphics elements. Since <graphics> are
optional for annotation-labels they share the same implementation.

Unknown tags get parsed by `unparsed_tag`.  Annotation-labels usually have
known tags and dedicated parsers. `parse_pnml_object_common` puts unregistered children
into the labels collection of a [`AbstractPnmlObject`].  It can include annotations and attributes.
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

    Declaration(something(decls, AbstractDeclaration[]), graphics, tools)
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

#! errors?! "$(TYPEDSIGNATURES)"
function parse_variabledecl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = check_nodename(node, "variabledecl")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute"))
    name = node["name"]
    # Assert only 1 element? operator or variable?
    sort = parse_sort(EzXML.firstelement(node), pntd, idregistry)
    VariableDeclaration(id, name, sort) #TODO register id?
end,

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

Allow all pntd's places to have a <type> label.  Non high-level are expecting a numeric sort: eltype(sort) <: Number.
See [`default_sort`](@ref)`
"""
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
    term = EzXML.firstelement(typenode) # Expect only child element to be a sort.
    # No multiset sort for the sort of a Place. Who checks/cares?
    parse_sort(term, pntd, idregistry)
end

isEmptyContent(body::Vector{AnyXmlNode}) = (length(body) == 1 &&
                                            tag(first(body)) === :content &&
                                            isempty(value(first(body))))

function parse_feconstants(body::Vector{AnyXmlNode})
    @assert all(fec -> tag(fec) === :feconstant, body) "zero or more FEConstants"
    feconstants = FEConstant[]
    for fec in body
        onefec = value(fec)::Vector{AnyXmlNode}
        #println("fconstant"); dump(onefec)
        @assert all(o -> isa(o, AnyXmlNode), onefec)
        (id, name) = id_name(onefec)
        push!(feconstants, FEConstant(id, name))
    end
    return feconstants
end

"The body has only a :declaration, return its value as a string."
function parse_decl(body::Vector{AnyXmlNode})
    @assert length(body) == 1
    d = first(body)
    @assert tag(d) === :declaration
    return value(d)::AbstractString
end
parse_decl(str::AbstractString) = str

parse_usersort(body::Vector{AnyXmlNode}) = parse_decl(body)
parse_usersort(str::AbstractString) = str

parse_useroperator(body::Vector{AnyXmlNode}) = parse_decl(body)
parse_useroperator(str::AbstractString) = str

"Tags used in sort XML elements."
const sort_ids = (:usersort, :dot, :bool, :integer, :natural, :positive,
                  :multisetsort, :productsort, :partition, :list, :string,
                  :cyclicenumeration, :finiteenumeration, :finiteintrange)

"""
$(TYPEDSIGNATURES)

Sorts are found within a <structure> element.
"""
function parse_sort(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)

    # Use `unparsed_tag`.
    ucl = unparsed_tag(node, pntd, idregistry)

    sortid = ucl.first::Symbol # Tag identifies sort
    body = ucl.second::Vector{AnyXmlNode} # value is array

    sortid ∈ sort_ids || (@warn("invalid sort type '$sortid', allowed: $sort_ids"), dump(ucl), false)

    if sortid === :usersort
        decl = parse_decl(body)
        srt = UserSort(decl)

    elseif sortid === :dot
        @assert isEmptyContent(body)
        srt = DotSort()

    elseif sortid === :bool
        @assert isEmptyContent(body)
        srt = BoolSort()

    elseif sortid === :integer
        @assert isEmptyContent(body)
        srt = IntegerSort()

    elseif sortid === :natural
        @assert isEmptyContent(body)
        srt = NaturalSort()

    elseif sortid === :positive
        @assert isEmptyContent(body)
        srt = PositiveSort()

    elseif sortid === :cyclicenumeration
        #println("$sortid sort: "); dump(body)
        fec = parse_feconstants(body)
        srt = CyclicEnumerationSort(fec)

    elseif sortid === :finiteenumeration
        #println("$sortid sort: "); dump(body)
        @assert all(x -> tag(x) === :feconstant, body)
        fec = parse_feconstants(body)
        srt = FiniteEnumerationSort(fec)

    elseif sortid === :finiteintrange
        #println("$sortid sort: "); dump(body)
        (start, stop) = start_stop(body)
        srt = FiniteIntRangeSort(start, stop)

    elseif sortid === :list
        println("$sortid sort: "); dump(body)
        error("IMPLEMENT ME")
        srt = ListSort()
    elseif sortid === :string
        println("$sortid sort: "); dump(body)
        error("IMPLEMENT ME")
        srt = StringSort()

    elseif sortid === :multisetsort
        #println("$sortid sort: "); dump(body)
        # There will be 1 usersort
        @assert length(body) == 1
        usort = first(body)
        @assert tag(usort) === :usersort

        decl = parse_decl(value(usort))
        srt = MultisetSort(UserSort(decl))

    elseif sortid === :productsort
        #println("$sortid sort: "); dump(body)
        # orderded collection of UserSorts
        usorts = UserSort[]
        for axn in body # of productsort
            @assert tag(axn) === :usersort
            value(axn) isa Vector{AnyXmlNode} ||
                error("expected Vector{AnyXmlNode}, got $(typeof(value(axn)))")
            decl = parse_decl(value(axn))
            srt2 = UserSort(decl)
            push!(usorts, srt2)
        end
        srt = ProductSort(usorts)

    elseif sortid === :partition
        #println("$sortid sort: "); dump(body)
        part = parse_partition(body)
        srt = PartitionSort(part.id, part.name, part.sort, part.elements)
        @show typeof(srt) srt
    else
        error("parse_sort sort $sortid not implemented")
    end

    @show srt
    return srt
end

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
"""
function parse_arbitraryoperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "arbitraryoperator")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arbitrarysort(node, pntd, reg)
    nn = check_nodename(node, "arbitrarysort")
    Term(unparsed_tag(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_bool(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "bool")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_mulitsetsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "mulitsetsort")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_productsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "productsort")
    Term(unparsed_tag(node, pntd, reg))
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
