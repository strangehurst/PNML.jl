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

Return [`Declaration`](@ref) label of 'net' or 'page' node.
Assume behavior of a High-level Net label in that the meaning is in a <structure>.

Expected format: <declaration> <structure> <declarations> <namedsort/> <namedsort/> ...
"""
function parse_declaration(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "declaration")
    decls::Maybe{Vector{AbstractDeclaration}} = nothing
    text = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "structure"
            decls = _parse_decl_structure(child, pntd, idregistry)
        elseif tag == "text"
            text = string(strip(EzXML.nodecontent(child)))
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            add_toolinfo!(tools, child, pntd, idregistry)
        else
            @warn "ignoring unexpected child of <declaration>: '$tag'"
        end
    end

    Declaration(text, something(decls, AbstractDeclaration[]), graphics, tools)
end

"Assumes high-level semantics until someone specializes. See [`decl_structure`](@ref)."
function _parse_decl_structure(node::XMLNode, pntd::T, idregistry) where {T <: PnmlType}
    decl_structure(node, pntd, idregistry)
end

# <declaration><structure><declarations><namedsort id="weight" name="Weight">...
"Return vector of AbstractDeclaration subtypes."
function decl_structure(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "structure")
    EzXML.haselement(node) || throw(ArgumentError("missing <declaration> <structure> element"))
    declarations = EzXML.firstelement(node) # <declaration> contains only <declarations>.
    check_nodename(declarations, "declarations")
    decs = AbstractDeclaration[]
    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        @match tag begin
            # These three cases have
            "namedsort"     => push!(decs, parse_namedsort(child, pntd, idregistry))
            "namedoperator" => push!(decs, parse_namedoperator(child, pntd, idregistry))
            "variabledecl"  => push!(decs, parse_variabledecl(child, pntd, idregistry))
            #todo "arbitrarysort"
            "partition"     => push!(decs, parse_partition_decl(child, pntd, idregistry))
            _               => push!(decs, parse_unknowndecl(child, pntd, idregistry))
        end
    end
    return decs
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps a Sort, adding an ID and name.
"""
function parse_namedsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "namedsort")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(reg, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn $id missing name attribute"))
    name = node["name"]

    def = parse_sort(EzXML.firstelement(node), pntd, reg) #! register id?
    NamedSort(id, name, def)
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = check_nodename(node, "namedoperator")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn))
    id = register_id!(idregistry, node["id"])
    EzXML.haskey(node, "name") || throw(MalformedException("$nn $id missing name attribute"))
    name = node["name"]

    def::Maybe{Term} = nothing
    parameters = VariableDeclaration[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "def"
            # NamedOperators have a def element that is a operator or variable term.
            def = parse_term(EzXML.firstelement(child), pntd, idregistry) #todo

        elseif tag == "parameter"
            # Zero or more parameters for operator.
            for vdecl in EzXML.eachelement(child)
                push!(parameters, parse_variabledecl(vdecl, pntd, idregistry))
            end
        else
            @warn """ignoring child of <namedoperator name="$name", id="$id">: '$tag', allowed: 'def', 'parameter'"""
        end
    end
    isnothing(def) && (throw ∘ ArgumentError)("""<namedoperator name="$name", id="$id"> does not have a <def> element""")
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

    @warn("parse unknown declaration: tag = $nn, id = $id, name = $name")
    # Defer parsing by returning AnyElement
    content = [anyelement(x, pntd, idregistry) for x in EzXML.eachelement(node) if x !== nothing]
    ud = UnknownDeclaration(id, name, nn, content)
    return ud
end

# Pass in parser function (or functor?)
function parse_label_content(node::XMLNode, termparser::F,
                             pntd::PnmlType, idregistry) where {F <: Function}
    text::Maybe{Union{String,SubString{String}}} = nothing #
    term::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools  = ToolInfo[]

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        @match tag begin
            "text"         => (text = parse_text(child, pntd, idregistry))
            "structure"    => (term = termparser(child, pntd, idregistry)) # Apply function/functor
            "graphics"     => (graphics = parse_graphics(child, pntd, idregistry))
            "toolspecific" => add_toolinfo!(tools, child, pntd, idregistry)
            _ => @warn("ignoring unexpected child of <$(EzXML.nodename(node))>: '$tag'")
        end
    end
    return (; text, term, graphics, tools)
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
    l = parse_label_content(node, parse_sorttype_term, pntd, idregistry)
    SortType(l.text, Ref{AbstractSort}(something(l.term, default_sort(pntd)())), l.graphics, l.tools)
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
    EzXML.haselement(typenode) || (throw ∘ ArgumentError)("missing sort type element in <structure>")
    term = EzXML.firstelement(typenode)::XMLNode # Expect only child element to be a sort.
    # No multiset sort for the sort of a Place. Who checks/cares?
    parse_sort(term, pntd, idregistry)
end

isEmptyContent(body::DictType) = tag(body) == "content" && isempty(value(body))

function parse_feconstants(body::DictType)
    @assert tag(body) == "feconstant"
    feconstants = FEConstant[]
    for fec in value(body)
        push!(feconstants, (; :id => Symbol(fec[:id]), :name => fec[:name]))
    end
    return feconstants
end

"Has a tag of :declaration, return value as a string."
function parse_decl end

parse_decl(p::Pair) = parse_decl(p...)
function parse_decl(tag::Symbol, d::XDVT)
    tag != :declaration && throw(ArgumentError("expected tag 'declaration', found '$tag'"))
    return string(d)
end
parse_decl(d::DictType) = parse_decl(tag(d), value(d))

function parse_decl!(vec::Vector{T}, vd::Vector{Any}) where {T <: AbstractSort}
    for us in vd
        parse_decl!(vec, us) # expand pair
    end
end
function parse_decl!(vec::Vector{T}, d::DictType) where {T <: AbstractSort}
    decl = parse_decl(d) # expand pair
    srt2 = UserSort(decl)
    push!(vec, srt2)
end

parse_usersort(body::DictType) = parse_decl(body)
parse_usersort(str::AbstractString) = str

parse_useroperator(body::DictType) = parse_decl(body)
parse_useroperator(str::AbstractString) = str

"Tags used in sort XML elements."
const sort_ids = (:usersort, :dot, :bool, :integer, :natural, :positive,
                  :multisetsort, :productsort, :partition, :list, :string,
                  :cyclicenumeration, :finiteenumeration, :finiteintrange)

#
function parse_sort(::Val{:dot}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    isempty(body) || @error "sort :dot not empty" body
    DotSort()
end
function parse_sort(::Val{:bool}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    isempty(body) || @error "sort :bool not empty" body
    BoolSort()
end

function parse_sort(::Val{:integer}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    isempty(body) || @error "sort :integer not empty" body
    IntegerSort()
end

function parse_sort(::Val{:natural}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    isempty(body) || @error "sort :natural not empty" body
    NaturalSort()
end

function parse_sort(::Val{:positive}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    isempty(body) || @error "sort :positive not empty" body
    PositiveSort()
end

function parse_sort(::Val{:usersort}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    UserSort(parse_decl(body))
end

function parse_sort(::Val{:cyclicenumeration}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    fecs = parse_feconstants(body)
    CyclicEnumerationSort(fecs)
end
function parse_sort(::Val{:finiteenumeration}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    fecs = parse_feconstants(body)
    FiniteEnumerationSort(fecs)
end
function parse_sort(::Val{:finiteintrange}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    (start, stop) = start_stop(body)
    FiniteIntRangeSort(start, stop)
end
function parse_sort(::Val{:list}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    @error("IMPLEMENT ME: sort = $body")
    ListSort()
end
function parse_sort(::Val{:string}, body::DictType,  _::PnmlType, _::PnmlIDRegistry)
    @error("IMPLEMENT ME: sort = $body")
    StringSort()
end

function parse_sort(::Val{:multisetsort}, body::DictType,  pntd::PnmlType, idreg::PnmlIDRegistry)
    #@show sortid body
    @assert length(body) == 1 ":mulitsetsort requires one basis sort, found $body"
    (k,v) = only(pairs(body))
    srt = parse_sort(Val(Symbol(k)), v, pntd, idreg)
    MultisetSort(srt)
end


#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort> element
function parse_sort(::Val{:productsort}, body::DictType, pntd::PnmlType, idreg::PnmlIDRegistry)
    # `body` was asserted to be a `DictType` and its the `unparsed_tag` path, based on XMLDict.
    sorts = AbstractSort[] # Orderded collection of zero or more Sorts, not just UserSorts.
    for (k,v) in pairs(body)
        if v isa DictType
            push!(sorts, parse_sort(Val(Symbol(k)), v, pntd, idreg))
        else
            foreach(v) do s # v may be a vector that has the same k
                push!(sorts, parse_sort(Val(Symbol(k)), s, pntd, idreg))
            end
        end
    end
    #@show sorts
    ProductSort(sorts)
end

"""
$(TYPEDSIGNATURES)

Sorts are found within an enclosing XML element, usually <structure>.
PNML maps the sort element name, frequently called a 'tag', to the body of the sort.
Heavily-used in the high-level abstract syntax tree.
Some nesting is used. Meaning that some sorts contain other sorts.
`parse_sort` returns a top-level sort instance.
"""
function parse_sort(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    (sortid, body) = unparsed_tag(node, pntd, idregistry)
    (ismissing(sortid) || isnothing(sortid)) && error("sort id is $sortid")
    (ismissing(body) || isnothing(body)) && error("sort body is $body")
    sortid = Symbol(sortid)
    body = body::DictType
    srt::Maybe{AbstractSort} = nothing

    if sortid in sort_ids
        srt = parse_sort(Val(sortid), body, pntd, idregistry)
    else
        @error("parse_sort sort '$sortid' not implemented: allowed: $sort_ids", body)
    end
    #@show sortid srt
    return srt
end
function parse_partition_decl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    (tag, body) = unparsed_tag(node, pntd, idregistry)
    (ismissing(tag) || isnothing(tag)) && error("sort id is $tag")
    (ismissing(body) || isnothing(body)) && error("sort body is $body")
    tag = Symbol(tag)
    body = body::DictType
    part = parse_partition(body, idregistry)
    #@show part
    return part
end

 """
# $(TYPEDSIGNATURES)
# """
# function parse_usersort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "usersort")
#     EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))
#     UserSort(anyelement(node, pntd, reg))
# end





# """
# $(TYPEDSIGNATURES)
# """
# function parse_arbitraryoperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "arbitraryoperator")
#     Term(unparsed_tag(node, pntd, reg))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_arbitrarysort(node, pntd, reg)
#     nn = check_nodename(node, "arbitrarysort")
#     Term(unparsed_tag(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_bool(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "bool")
#     Term(unparsed_tag(node, pntd, reg))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_mulitsetsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "mulitsetsort")
#     Term(unparsed_tag(node, pntd, reg))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_productsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "productsort")
#     Term(unparsed_tag(node, pntd, reg))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_useroperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     check_nodename(node, "useroperator")
#     EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))
#     UserOperator(Symbol(node["declaration"]))
# end

"""
$(TYPEDSIGNATURES)
"""
function parse_variable(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "variable")
    # The 'primer' UML2 uses variableDecl
    EzXML.haskey(node, "refvariable") || throw(MalformedException("$nn missing refvariable attribute"))
    Variable(Symbol(node["refvariable"]))
end
