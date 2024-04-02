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
function parse_declaration end
parse_declaration(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR) = parse_declaration(ids, [node], pntd, idregistry)

function parse_declaration(ids::Tuple, nodes::Vector{XMLNode}, pntd::PnmlType, idregistry::PIDR)
    #println("\nparse_declaration $ids")
    dd = decldict(first(ids)) # Lookup DeclDict for PnmlNet. #TODO better error if missing

    text = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    for node in nodes
        check_nodename(node, "declaration")
        for child in EzXML.eachelement(node)
            tag = EzXML.nodename(child)
            if tag == "structure" # accumulate declarations
                _parse_decl_structure!(dd, ids, child, pntd, idregistry)
            elseif tag == "text" # may overwrite
                text = string(strip(EzXML.nodecontent(child)))::String
                @info "declaration $ids $text" # Do not expect text here, so it must be important.
            elseif tag == "graphics"# may overwrite
                graphics = parse_graphics(child, pntd, idregistry)
            elseif tag == "toolspecific" # accumulate tool specific
                if isnothing(tools)
                    tools = ToolInfo[]
                end
                add_toolinfo!(tools, child, pntd, idregistry)
            else
                @warn "ignoring unexpected child of <declaration>: '$tag'"
            end
        end
    end

    Declaration(; text, ddict=dd, graphics, tools)
end

#"Assumes high-level semantics until someone specializes."
function _parse_decl_structure!(dd::DeclDict, ids::Tuple, node::XMLNode, pntd::T, idregistry) where {T <: PnmlType}
    fill_decl_dict!(dd, ids, node, pntd, idregistry)
end

function fill_decl_dict!(dd::DeclDict, ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    check_nodename(node, "structure")
    EzXML.haselement(node) || throw(ArgumentError("missing <declaration> <structure> element"))
    declarations = EzXML.firstelement(node)
    check_nodename(declarations, "declarations")
    unknown_decls = AbstractDeclaration[]

    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        if tag == "namedsort"
            ns = parse_namedsort(ids, child, pntd, idregistry)
            dd.namedsorts[pid(ns)] = ns
        elseif tag == "namedoperator"
            no = parse_namedoperator(ids, child, pntd, idregistry)
            dd.namedoperators[pid(no)] = no
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(ids, child, pntd, idregistry)
            dd.variabledecls[pid(vardecl)] = vardecl

        elseif tag == "partition"
            part = parse_term(Val(:partition), child, pntd, idregistry; ids)
            dd.partitionsorts[pid(part)] = part
        #TODO Where do we find these things? Is this were they are de-duplicated?
        #! elseif tag === :partitionoperator # PartitionLessThan, PartitionGreaterThan, PartitionElementOf
        #!    partop = parse_partition_op(child, pntd, idregistry)
        #!     dd.partitionops[pid(partop)] = partop

        #elseif tag == "arbitrarysort"
        else
            #TODO  add to DeclDict
            push!(unknown_decls, parse_unknowndecl(ids, child, pntd, idregistry))
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps a Sort, adding an ID and name.
"""
function parse_namedsort(ids::Tuple, node::XMLNode, pntd::PnmlType, reg::PIDR)
    nn = check_nodename(node, "namedsort")
    id = register_idof!(reg, node)
    name = attribute(node, "name", "$nn $id missing name attribute. trail = $ids")
    def = parse_sort(EzXML.firstelement(node), pntd, reg; ids) #! deduplicate sort
    NamedSort(id, name, def)
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps an operator by giving a name to a definition term (expression in many-sorted algebra).

An operator of arity 0 is a constant.
When arity > 0, where is the parameter value stored? With operator or variable declaration
"""
function parse_namedoperator(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "namedoperator")
    id = register_idof!(idregistry, node)
    name = attribute(node, "name", "$nn $id missing name attribute. trail = $ids")

    def::Maybe{NumberConstant} = nothing
    parameters = VariableDeclaration[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "def"
            # NamedOperators have a def element that is a expression of existing
            # operators &/or variables that define the operation.
            # The sortof the operator is the output sort of def.
            def, defsort = parse_term(EzXML.firstelement(child), pntd, idregistry; ids) #todo
        elseif tag == "parameter"
            # Zero or more parameters for operator (arity). Map from id to sort object.
            #! Allocate here? What is difference in Declarations and NamedOperator VariableDeclrations
            #! Is def restricted to just parameters? Can others access parameters?
            for vdecl in EzXML.eachelement(child)
                push!(parameters, parse_variabledecl(ids, vdecl, pntd, idregistry))
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
function parse_variabledecl(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = check_nodename(node, "variabledecl")
    id = register_idof!(idregistry, node)
    #!EzXML.haskey(node, "name") || throw(MalformedException("$nn missing name attribute"))
    name = attribute(node, "name", "$nn missing name attribute. trail = $ids")
    # firstelement throws on nothing. Ignore more than 1.
    #! There should be an actual way to store the value of the variable!
    #! Indexed by the id.  id can also map to (possibly de-duplicated) sort. And a eltype.
    #! All that work can be defered to a post-parse phase. Followed by the verification phase.
    sort = parse_sort(EzXML.firstelement(node), pntd, idregistry; ids)
    VariableDeclaration(id, name, sort)
end,


"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    nn = EzXML.nodename(node)
    id = register_idof!(idregistry, node)
    name = attribute(node, "name","$nn $id missing name attribute. trail = $ids")

    @warn("parse unknown declaration: tag = $nn, id = $id, name = $name")
    # Defer parsing by returning AnyElement
    content = AnyElement[anyelement(x, pntd, idregistry) for x in EzXML.eachelement(node) if x !== nothing]
    ud = UnknownDeclaration(id, name, nn, content)
    return ud
end


#------------------------

isEmptyContent(body::DictType) = tag(body) == "content" && isempty(value(body))

"""
Return ordered vector of finite enumeration constant IDs.
Place the constants into feconstants(decldict(netid)).
"""
function parse_feconstants(ids::Tuple, node::XMLNode, pntd::PnmlType, idregistry::PIDR)
    sorttag = EzXML.nodename(node)
    @assert sorttag in ("finiteenumeration", "cyclicenumeration")
    EzXML.haselement(node) || error("$sorttag has no child element")
    netid = first(ids)
    dd = decldict(netid) # Declarations are at net/page level.

    fec_refs = Symbol[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag != "feconstant"
            throw(MalformedException("$sorttag has unexpected child element $tag. trail = $ids"))
        else
            id = register_idof!(idregistry, child)
            name = attribute(child, "name", "$sorttag <feconstant id=$id> missing name attribute. trail = $ids")
            fec = (id, name, netid, partid = :unknown) #! XXX partition id XXXX
            dd.feconstants[id] = fec
            push!(fec_refs, id)
        end
    end
    return fec_refs #
end

# "Has a tag of :declaration, return value as a string."
# function parse_decl end

# parse_decl(p::Pair) = parse_decl(p...)
# function parse_decl(tag::Symbol, d::XDVT)
#     tag != :declaration && throw(ArgumentError(string("expected tag 'declaration', found: ",tag)::String))
#     return string(d)::String
# end
# parse_decl(d::DictType) = parse_decl(tag(d), value(d))

# function parse_decl!(vec::Vector{T}, vd::Vector{Any}) where {T <: AbstractSort}
#     for us in vd
#         parse_decl!(vec, us) # expand pair
#     end
# end
# function parse_decl!(vec::Vector{T}, d::DictType) where {T <: AbstractSort}
#     decl = parse_decl(d) # expand pair
#     srt2 = UserSort(decl)
#     push!(vec, srt2)
# end

# parse_usersort(body::DictType) = parse_decl(body)
# parse_usersort(str::AbstractString) = str

# parse_useroperator(body::DictType) = parse_decl(body)
# parse_useroperator(str::AbstractString) = str

"Tags used in sort XML elements."
const sort_ids = (:usersort,
                  :dot, :bool, :integer, :natural, :positive,
                  :multisetsort, :productsort,
                  :partition, # :partition is over a :finiteenumeration
                  :list, :string,
                  :cyclicenumeration, :finiteenumeration, :finiteintrange)

function parse_sort(::Val{:dot}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    DotSort()
end
function parse_sort(::Val{:bool}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    BoolSort()
end

function parse_sort(::Val{:integer}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    IntegerSort()
end

function parse_sort(::Val{:natural}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    NaturalSort()
end

function parse_sort(::Val{:positive}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    PositiveSort()
end

function parse_sort(::Val{:usersort}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    UserSort(attribute(node, "declaration", "usersort missing declaration attribute. trail = $ids"))
end

function parse_sort(::Val{:cyclicenumeration}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    CyclicEnumerationSort(parse_feconstants(ids, node, pntd, idreg), first(ids))
end

function parse_sort(::Val{:finiteenumeration}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    FiniteEnumerationSort(parse_feconstants(ids, node, pntd, idreg), first(ids))
end

function parse_sort(::Val{:finiteintrange}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    nn = check_nodename(node, "finiteintrange")

    startstr = attribute(node, "start", "finiteintrange missing start. trail = $ids")
    start = tryparse(Int, startstr)
    isnothing(start) && throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`"))

    stopstr = attribute(node, "end", "finiteintrange missing end. trail = $ids") # XML Schema uses 'end', we use 'stop'.
    stop = tryparse(Int, stopstr)
    isnothing(stop) && throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`"))

    FiniteIntRangeSort(start, stop)
end

function parse_sort(::Val{:list}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    @error("IMPLEMENT ME: :list")
    ListSort()
end

function parse_sort(::Val{:string}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    @error("IMPLEMENT ME: :string")
    StringSort()
end

function parse_sort(::Val{:multisetsort}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    nn = check_nodename(node, "multisetsort")
    EzXML.haselement(node) || throw(ArgumentError("multisetsort missing basis sort. trail = $ids"))
    basis = EzXML.firstelement(node)
    srt = parse_sort(Val(Symbol(EzXML.nodename(basis))), basis, pntd, idreg; ids) #~ deduplicate sorts
    MultisetSort(srt)
end

#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort> element
function parse_sort(::Val{:productsort}, node::XMLNode, pntd::PnmlType, idreg::PIDR; ids::Tuple)
    check_nodename(node, "productsort")

    sorts = AbstractSort[] # Orderded collection of zero or more Sorts, not just UserSorts & ArbitrarySorts.
    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag in sort_ids
            push!(sorts, parse_sort(Val(tag), child, pntd, idreg; ids))
        else
            throw(MalformedException("<productsort> contains unexpected sort $tag. trail = $ids"))
        end
    end
    isempty(sorts) && throw(MalformedException("<productsort> contains no sorts. trail = $ids"))
    #@show sorts
    ProductSort(sorts)
end

"""
$(TYPEDSIGNATURES)

Sorts are found within an enclosing XML element, usually <structure>.
PNML maps the sort element name, frequently called a 'tag', to the body of the sort.
Heavily-used in the high-level abstract syntax tree.
Some nesting is used. Meaning that some sorts contain other sorts.

See also [`parse_sorttype_term`](@ref), [`parse_namedsort`](@ref), [`parse_variabledecl`](@ref).
"""
function parse_sort(node::XMLNode, pntd::PnmlType, idregistry::PIDR; ids::Tuple)
    # Note: Sorts are not PNML labels. Will not have <text>, <graphics>, <toolspecific>.
    #println("\nparse_sort $ids")
    sortid = Symbol(EzXML.nodename(node))
    if sortid in sort_ids
        sort = parse_sort(Val(sortid), node, pntd, idregistry; ids)::AbstractSort
    else
        @error("parse_sort $sortid not implemented: allowed: $sort_ids. trail = $ids")
    end
    #@show sortid sort
    return sort
end

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node::XMLNode, pntd::PnmlType, reg::PIDR; ids::Tuple)
    check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration", "usersort missing declaration attribute. trail = $ids")))
end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_arbitraryoperator(node::XMLNode, pntd::PnmlType, reg::PIDR)
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
# function parse_bool(node::XMLNode, pntd::PnmlType, reg::PIDR)
#     nn = check_nodename(node, "bool")
#     Term(unparsed_tag(node))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_mulitsetsort(node::XMLNode, pntd::PnmlType, reg::PIDR)
#     nn = check_nodename(node, "mulitsetsort")
#     Term(unparsed_tag(node))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_productsort(node::XMLNode, pntd::PnmlType, reg::PIDR)
#     nn = check_nodename(node, "productsort")
#     Term(unparsed_tag(node))
# end

# """
# $(TYPEDSIGNATURES)
# """
# function parse_useroperator(node::XMLNode, pntd::PnmlType, reg::PIDR)
#     check_nodename(node, "useroperator")
#     EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))
#     UserOperator(Symbol(node["declaration"]))
# end

"""
$(TYPEDSIGNATURES)
A reference to a variable declaration.
"""
function parse_variable(node::XMLNode, pntd::PnmlType, reg::PIDR; ids::Tuple)
    nn = check_nodename(node, "variable")
    # The 'primer' UML2 uses variableDecl instead of refvariable. References a VariableDeclaration.
    Variable(Symbol(attribute(node, "refvariable", "<variable> missing refvariable attribute. trail = $ids")), first(ids))
end
