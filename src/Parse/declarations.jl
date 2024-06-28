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
parse_declaration(node::XMLNode, pntd::PnmlType; ids::Tuple) = parse_declaration([node], pntd; ids)

function parse_declaration(nodes::Vector{XMLNode}, pntd::PnmlType; ids::Tuple)
    #println("\nparse_declaration, trail = $ids")
    isempty(ids) && throw(ArgumentError("`ids` trail tuple cannot be empty"))
    dd = decldict(netid(ids)) # Lookup DeclDict for PnmlNet. #TODO better error if missing

    text = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    for node in nodes
        check_nodename(node, "declaration")
        for child in EzXML.eachelement(node)
            tag = EzXML.nodename(child)
            if tag == "structure" # accumulate declarations
                _parse_decl_structure!(dd, child, pntd; ids)
            elseif tag == "text" # may overwrite
                text = string(strip(EzXML.nodecontent(child)))::String
                @info "declaration text: $text" # Do not expect text here, so it must be important.
            elseif tag == "graphics"# may overwrite
                graphics = parse_graphics(child, pntd)
            elseif tag == "toolspecific" # accumulate tool specific
                if isnothing(tools)
                    tools = ToolInfo[]
                end
                add_toolinfo!(tools, child, pntd)
            else
                @warn "ignoring unexpected child of <declaration>: '$tag'"
            end
        end
    end

    Declaration(; text, ddict=dd, graphics, tools)
end

#"Assumes high-level semantics until someone specializes."
function _parse_decl_structure!(dd::DeclDict, node::XMLNode, pntd::T; ids::Tuple) where {T <: PnmlType}
    fill_decl_dict!(dd, node, pntd; ids)
end

function fill_decl_dict!(dd::DeclDict, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "structure")
    EzXML.haselement(node) || throw(ArgumentError("missing <declaration> <structure> element"))
    declarations = EzXML.firstelement(node)
    check_nodename(declarations, "declarations")
    unknown_decls = AbstractDeclaration[]

    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        if tag == "namedsort"
            ns = parse_namedsort(child, pntd; ids)
            dd.namedsorts[pid(ns)] = ns
        elseif tag == "namedoperator"
            no = parse_namedoperator(child, pntd; ids)
            dd.namedoperators[pid(no)] = no
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(child, pntd; ids)
            dd.variabledecls[pid(vardecl)] = vardecl

        elseif tag == "partition"
            part = parse_sort(Val(:partition), child, pntd; ids)
            dd.partitionsorts[pid(part)] = part
        #TODO Where do we find these things? Is this were they are de-duplicated?
        #! elseif tag === :partitionoperator # PartitionLessThan, PartitionGreaterThan, PartitionElementOf
        #!    partop = parse_partition_op(child, pntd)
        #!     dd.partitionops[pid(partop)] = partop

        #elseif tag == "arbitrarysort"
        else
            #TODO  add to DeclDict
            push!(unknown_decls, parse_unknowndecl(child, pntd; ids))
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps a Sort, adding an ID and name.
"""
function parse_namedsort(node::XMLNode, pntd::PnmlType; ids::Tuple)
    nn = check_nodename(node, "namedsort")
    id = register_idof!(idregistry[], node) # use ScopedValue
    ids = tuple(ids..., id)
    name = attribute(node, "name", "$nn $id missing name attribute. trail = $ids")
    child = EzXML.firstelement(node)
    isnothing(child) && error("no sort definition element for namedsort $(repr(id)) $name")
    def = parse_sort(EzXML.firstelement(node), pntd; ids) #! deduplicate sort
    isnothing(def) && error("failed to parse sort definition for namedsort $(repr(id)) $name")
    NamedSort(id, name, def; ids)
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps an operator by giving a name to a definition term (expression in many-sorted algebra).

An operator of arity 0 is a constant.
When arity > 0, where is the parameter value stored? With operator or variable declaration
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType; ids::Tuple)
    nn = check_nodename(node, "namedoperator")
    id = register_idof!(idregistry[], node)
    name = attribute(node, "name", "$nn $id missing name attribute. trail = $ids")

    def::Maybe{NumberConstant} = nothing
    parameters = VariableDeclaration[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "def"
            # NamedOperators have a def element that is a expression of existing
            # operators &/or variable parameters that define the operation.
            # The sortof the operator is the output sort of def.
            def, defsort = parse_term(EzXML.firstelement(child), pntd; ids) #todo
        elseif tag == "parameter"
            # Zero or more parameters for operator (arity). Map from id to sort object.
            #! Allocate here? What is difference in Declarations and NamedOperator VariableDeclrations
            #! Is def restricted to just parameters? Can others access parameters?
            for vdecl in EzXML.eachelement(child)
                push!(parameters, parse_variabledecl(vdecl, pntd; ids))
            end
        else
            @warn string("ignoring child of <namedoperator name=", name,", id=", id,"> ",
                    "with tag ", tag, ", allowed: 'def', 'parameter'. trail = $ids")
        end
    end
    isnothing(def) &&
        throw(ArgumentError(string("<namedoperator name=", text(name), ", id=", id,
                                    "> does not have a <def> element. trail = $ids")))
    NamedOperator(id, name, parameters, def, ids)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "variabledecl")
    id = register_idof!(idregistry[], node)
    name = attribute(node, "name", "<variabledecl> missing name attribute. trail = $ids")
    # firstelement throws on nothing. Ignore more than 1.
    #! There should be an actual way to store the value of the variable!
    #! Indexed by the id.  id can also map to (possibly de-duplicated) sort. And a eltype.
    #! All that work can be defered to a post-parse phase. Followed by the verification phase.
    sort = parse_sort(EzXML.firstelement(node), pntd; ids)
    VariableDeclaration(id, name, sort)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType; ids::Tuple)
    nn = EzXML.nodename(node)
    id = register_idof!(idregistry[], node)
    name = attribute(node, "name", "$nn $id missing name attribute. trail = $ids")
    @warn("parse unknown declaration: tag = $nn, id = $id, name = $name")
    content = AnyElement[anyelement(x, pntd) for x in EzXML.eachelement(node) if x !== nothing]
    return UnknownDeclaration(id, name, nn, content)
end

"""
Return ordered vector of finite enumeration constant IDs.
Place the constants into feconstants(decldict(netid)).
"""
function parse_feconstants(node::XMLNode, pntd::PnmlType; ids::Tuple)
    sorttag = EzXML.nodename(node)
    @assert sorttag in ("finiteenumeration", "cyclicenumeration")
    EzXML.haselement(node) || error("$sorttag has no child element. trail = $ids")
    dd = decldict(netid(ids)) # Declarations are at net level.

    fec_refs = Symbol[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag != "feconstant"
            throw(MalformedException("$sorttag has unexpected child element $tag. trail = $ids"))
        else
            id = register_idof!(idregistry[], child)
            name = attribute(child, "name", "$sorttag <feconstant id=$id> missing name attribute. trail = $ids")
            dd.feconstants[id] = FEConstant(id, name, ids) #! XXX partition id XXXX
            push!(fec_refs, id)
        end
    end
    return tuple(fec_refs...)
end

"Tags used in sort XML elements."
const sort_ids = (:usersort,
                  :dot, :bool, :integer, :natural, :positive, :real,
                  :multisetsort, :productsort,
                  :partition, # :partition is over a :finiteenumeration
                  :list, :string,
                  :cyclicenumeration, :finiteenumeration, :finiteintrange)

function parse_sort(::Val{:dot}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    DotSort()
end
function parse_sort(::Val{:bool}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    BoolSort()
end

function parse_sort(::Val{:integer}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    IntegerSort()
end

function parse_sort(::Val{:natural}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    NaturalSort()
end

function parse_sort(::Val{:positive}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    PositiveSort()
end

function parse_sort(::Val{:real}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    RealSort()
end

function parse_sort(::Val{:usersort}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration", "<usersort> missing declaration attribute. trail = $ids")); ids)
end

function parse_sort(::Val{:cyclicenumeration}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "cyclicenumeration")
    CyclicEnumerationSort(parse_feconstants(node, pntd; ids); ids)
end

function parse_sort(::Val{:finiteenumeration}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "finiteenumeration")
    FiniteEnumerationSort(parse_feconstants(node, pntd; ids); ids)
end

function parse_sort(::Val{:finiteintrange}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "finiteintrange")

    startstr = attribute(node, "start", "<finiteintrange> missing start. trail = $ids")
    start = tryparse(Int, startstr)
    isnothing(start) && throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`, trail = $ids"))

    stopstr = attribute(node, "end", "<finiteintrange> missing end. trail = $ids") # XML Schema uses 'end', we use 'stop'.
    stop = tryparse(Int, stopstr)
    isnothing(stop) && throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`. trail = $ids"))

    FiniteIntRangeSort(start, stop; ids)
end

function parse_sort(::Val{:list}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    @error("IMPLEMENT ME: :list", ids)
    ListSort()
end

function parse_sort(::Val{:string}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    @error("IMPLEMENT ME: :string", ids)
    StringSort()
end

function parse_sort(::Val{:multisetsort}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "multisetsort")
    EzXML.haselement(node) || throw(ArgumentError("multisetsort missing basis sort. trail = $ids"))
    basisnode = EzXML.firstelement(node) # Assume basis sort will be first and only child.
    # Expect this to be a <usersort>, or built-in sort, maybe someday <abstractsort>,
    # but not <partition> or <partitionelement>. Definitely not another multiset.
    tag = Symbol(EzXML.nodename(basisnode))
    part_tags = (:partition , :partitionelement)
    tag in part_tags && throw(ArgumentError("multisetsort basis $tag not allowed: $part_tags"))
    @show basissort = parse_sort(Val(tag), basisnode, pntd; ids) #~ deduplicate sorts
    MultisetSort(basissort)
end

#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort> element
function parse_sort(::Val{:productsort}, node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "productsort")

    sorts = AbstractSort[] # Orderded collection of zero or more Sorts, not just UserSorts & ArbitrarySorts.
    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag in sort_ids
            push!(sorts, parse_sort(Val(tag), child, pntd; ids))
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
function parse_sort(node::XMLNode, pntd::PnmlType; ids::Tuple)
    # Note: Sorts are not PNML labels. Will not have <text>, <graphics>, <toolspecific>.
    sortid = Symbol(EzXML.nodename(node))
    println("parse_sort $(repr(sortid)) $ids")
    sort = if sortid in sort_ids
        parse_sort(Val(sortid), node, pntd; ids)::AbstractSort
    else
        @error("parse_sort $(repr(sortid)) not implemented: allowed: $sort_ids. trail = $ids")
    end
    #@show sortid sort
    return sort
end

"""
$(TYPEDSIGNATURES)
"""
function parse_usersort(node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration", "<usersort> missing declaration attribute. trail = $ids")); ids)
end

"""
$(TYPEDSIGNATURES)
A reference to a variable declaration.
"""
function parse_variable(node::XMLNode, pntd::PnmlType; ids::Tuple)
    check_nodename(node, "variable")
    # References a VariableDeclaration. The 'primer' UML2 uses variableDecl.
    # Corrected to refvariable by Technical Corrigendum 1 to ISO/IEC 15909-2:2011.
    Variable(Symbol(attribute(node, "refvariable", "<variable> missing refvariable attribute. trail = $ids")), netid(ids))
end
