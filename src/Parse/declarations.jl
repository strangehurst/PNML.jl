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
    # if decldictionary is not defined
    decldictionary = DeclDict()#! decls::Maybe{Vector{AbstractDeclaration}} = nothing
    text = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "structure"
            _parse_decl_structure!(decldictionary, child, pntd, idregistry)
        elseif tag == "text"
            text = string(strip(EzXML.nodecontent(child)))::String #! do we need string?
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd, idregistry)
        elseif tag == "toolspecific"
            if isnothing(tools)
                tools = ToolInfo[]
            end
            add_toolinfo!(tools, child, pntd, idregistry)
        else
            @warn "ignoring unexpected child of <declaration>: '$tag'"
        end
    end

    Declaration(; text, ddict=decldictionary, graphics, tools)
end

#"Assumes high-level semantics until someone specializes."
function _parse_decl_structure!(dd::DeclDict, node::XMLNode, pntd::T, idregistry) where {T <: PnmlType}
    fill_decl_dict!(dd, node, pntd, idregistry)
end

function fill_decl_dict!(dd::DeclDict, node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "structure")
    EzXML.haselement(node) || throw(ArgumentError("missing <declaration> <structure> element"))
    declarations = EzXML.firstelement(node)
    check_nodename(declarations, "declarations")
    decs = AbstractDeclaration[]
    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        if tag == "namedsort"
            ns = parse_namedsort(child, pntd, idregistry)
            dd.namedsorts[pid(ns)] = ns
        elseif tag == "namedoperator"
            no = parse_namedoperator(child, pntd, idregistry)
            dd.namedoperators[pid(no)] = no
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(child, pntd, idregistry)
            dd.variabledecls[pid(vardecl)] = vardecl

        elseif tag == "partition"
            part = parse_partition_decl(child, pntd, idregistry)
            dd.partitionsorts[pid(part)] = part
        #TODO Where do we find these things? Is this were they are de-duplicated?
        #! elseif tag === :partitionoperator # PartitionLessThan, PartitionGreaterThan, PartitionElementOf
        #!    partop = parse_partition_op(child, pntd, idregistry)
        #!     dd.partitionops[pid(partop)] = partop

        #elseif tag == "arbitrarysort"
        else
            push!(decs, parse_unknowndecl(child, pntd, idregistry))
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps a Sort, adding an ID and name.
"""
function parse_namedsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "namedsort")
    id = register_idof!(reg, node)
    name = attribute(node, "name", "$nn $id missing name attribute")
    def = parse_sort(EzXML.firstelement(node), pntd, reg) #! register id? deduplicate sort
    NamedSort(id, name, def)
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps an operator by giving a name to a definition term (expression in many-sorted algebra).

An operator of arity 0 is a constant.
When arity > 0, where is the parameter value stored? With operator or variable declaration
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = check_nodename(node, "namedoperator")
    id = register_idof!(idregistry, node)
    name = attribute(node, "name", "$nn $id missing name attribute")

    def::Maybe{NumberConstant} = nothing
    parameters = VariableDeclaration[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "def"
            # NamedOperators have a def element that is a expression of existing
            # operators &/or variables that define the operation.
            # The sortof the operator is the output sort of def.
            def, defsort = parse_term(EzXML.firstelement(child), pntd, idregistry) #todo
        elseif tag == "parameter"
            # Zero or more parameters for operator (arity). Map from id to sort object.
            #! Allocate here? What is difference in Declarations and NamedOperator VariableDeclrations
            #! Is def restricted to just parameters? Can others access parameters?
            for vdecl in EzXML.eachelement(child)
                push!(parameters, parse_variabledecl(vdecl, pntd, idregistry))
            end
        else
            @warn string("ignoring child of <namedoperator name=", name,", id=", id,"> ",
                    "with tag ", tag, ", allowed: 'def', 'parameter'")
        end
    end
    isnothing(def) &&
        throw(ArgumentError(string("<namedoperator name=", text(name), ", id=", id,
                                                 "> does not have a <def> element")))
    NamedOperator(id, name, parameters, def)
end

#! errors?! "$(TYPEDSIGNATURES)"
function parse_variabledecl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = check_nodename(node, "variabledecl")
    id = register_idof!(idregistry, node)
    #!EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute"))
    name = attribute(node, "name", "$nn missing name attribute")
    # firstelement throws on nothing. Ignore more than 1.
    #! There should be an actual way to store the value of the variable!
    #! Indexed by the id.  id can also map to (possibly de-duplicated) sort. And a eltype.
    #! All that work can be defered to a post-parse phase. Followed by the verification phase.
    sort = parse_sort(EzXML.firstelement(node), pntd, idregistry)
    VariableDeclaration(id, name, sort)
end,

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    nn = EzXML.nodename(node)
    id = register_idof!(idregistry, node)
    name = attribute(node, "name","$nn $id missing name attribute")

    @warn("parse unknown declaration: tag = $nn, id = $id, name = $name")
    # Defer parsing by returning AnyElement
    content = AnyElement[anyelement(x, pntd, idregistry) for x in EzXML.eachelement(node) if x !== nothing]
    ud = UnknownDeclaration(id, name, nn, content)
    return ud
end


#------------------------

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
    tag != :declaration && throw(ArgumentError(string("expected tag 'declaration', found: ",tag)::String))
    return string(d)::String
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
const sort_ids = (:usersort,
                  :dot, :bool, :integer, :natural, :positive,
                  :multisetsort, :productsort,
                  :partition,
                  :list, :string,
                  :cyclicenumeration, :finiteenumeration, :finiteintrange)
# :partition is over a :finiteenumeration
# :partition is a kind of finite enumeration

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
    length(body) != 1 &&
        throw(MalformedException(string(":mulitsetsort requires exactly one basis sort, found ", body)))
    (k,v) = only(pairs(body))
    @assert k !== :multisetsort
    srt = parse_sort(Val(Symbol(k)), v, pntd, idreg) #TODO de-duplicate sorts
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
    (sortid, body) = unparsed_tag(node)
    (ismissing(sortid) || isnothing(sortid)) && error("sort id is $sortid")
    (ismissing(body) || isnothing(body)) && error("sort body is $body")
    sortid = Symbol(sortid)
    body = body::DictType
    srt::Maybe{AbstractSort} = nothing

    if sortid in sort_ids
        srt = parse_sort(Val(sortid), body, pntd, idregistry)::AbstractSort
    else
        @error("parse_sort sort '$sortid' not implemented: allowed: $sort_ids", body)
    end
    #@show sortid srt
    return srt
end

function parse_partition_decl(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    (tag, body) = unparsed_tag(node)
    (ismissing(tag) || isnothing(tag)) && error("sort id is $tag")
    (ismissing(body) || isnothing(body)) && error("sort body is $body")
    tag = Symbol(tag)
    body = body::DictType
    part = parse_partition(body, idregistry)
    #@show part
    return part
end

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration", "$nn missing declaration attribute")))
end





# """
# $(TYPEDSIGNATURES)
# """
# function parse_arbitraryoperator(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "arbitraryoperator")
#     Term(unparsed_tag(node))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_arbitrarysort(node, pntd, reg)
#     nn = check_nodename(node, "arbitrarysort")
#     Term(unparsed_tag(node::XMLNode))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_bool(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "bool")
#     Term(unparsed_tag(node))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_mulitsetsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "mulitsetsort")parse_partition_decl
#     Term(unparsed_tag(node))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_productsort(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
#     nn = check_nodename(node, "productsort")
#     Term(unparsed_tag(node))
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
A reference to a variable declaration.
"""
function parse_variable(node::XMLNode, _::PnmlType, _::PnmlIDRegistry)
    nn = check_nodename(node, "variable")
    # The 'primer' UML2 uses variableDecl instead of refvariable. References a VariableDeclaration.
    Variable(Symbol(attribute(node, "refvariable", "$nn missing refvariable attribute")))
end
