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
parse_declaration(node::XMLNode, pntd::PnmlType) = parse_declaration([node], pntd)

function parse_declaration(nodes::Vector{XMLNode}, pntd::PnmlType)
    #println("\nparse_declaration")
    dd = PNML.DECLDICT[] #! ScopedValue

    text = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    for node in nodes
        check_nodename(node, "declaration")
        for child in EzXML.eachelement(node)
            tag = EzXML.nodename(child)
            if tag == "structure" # accumulate declarations
                # @show idregistry[]
                _parse_decl_structure!(dd, child, pntd)
            elseif tag == "text" # may overwrite
                text = string(strip(EzXML.nodecontent(child)))::String
                @info "declaration text: $text" # Do not expect text here, so it must be important.
            elseif tag == "graphics"# may overwrite
                graphics = parse_graphics(child, pntd)
            elseif tag == "toolspecific" # accumulate tool specific
                tools = add_toolinfo(tools, child, pntd)
            else
                @warn "ignoring unexpected child of <declaration>: '$tag'"
            end
        end
    end

    Declaration(; text, ddict=dd, graphics, tools)
end

#"Assumes high-level semantics until someone specializes."
function _parse_decl_structure!(dd::DeclDict, node::XMLNode, pntd::T) where {T <: PnmlType}
    fill_decl_dict!(dd, node, pntd)
end

function fill_decl_dict!(dd::DeclDict, node::XMLNode, pntd::PnmlType)
    check_nodename(node, "structure")
    EzXML.haselement(node) || throw(ArgumentError("missing <declaration> <structure> element"))
    declarations = EzXML.firstelement(node)
    check_nodename(declarations, "declarations")
    unknown_decls = AbstractDeclaration[]

    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        if tag == "namedsort"
            ns = parse_namedsort(child, pntd)
            namedsorts(dd)[pid(ns)] = ns
            usersorts(dd)[pid(ns)] = UserSort(pid(ns)) # make usersort, namedsort duo
        elseif tag == "namedoperator"
            no = parse_namedoperator(child, pntd)
            namedoperators(dd)[pid(no)] = no
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(child, pntd)
            variabledecls(dd)[pid(vardecl)] = vardecl
        elseif tag == "partition"
            part = parse_partition(child, pntd)::SortDeclaration
            partitionsorts(dd)[pid(part)] = part
            usersorts(dd)[pid(part)] = part #! usersort, partition duo.

        #TODO Where do we find these things? Is this were they are de-duplicated?
        #! elseif tag === :partitionoperator # PartitionLessThan, PartitionGreaterThan, PartitionElementOf
        #!    partop = parse_partition_op(child, pntd)
        #!     dd.partitionops[pid(partop)] = partop

        #elseif tag == "arbitrarysort"
        else
            #TODO  add unknown_decls to DeclDict
            push!(unknown_decls, parse_unknowndecl(child, pntd))
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps a Sort, adding an ID and name.
"""
function parse_namedsort(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "namedsort")
    # Will have created usersort, namedsort duos for builtin sorts.
    # Replacement of those duos, in particular, :dot, will trigger a duplicate id error
    # unless the `(builtinsorts)` are excluded from the register_idof! check.
    # Note: builtin sort definitions are all singleton types.
    EzXML.haskey(node, "id") || throw(MissingIDException(EzXML.nodename(node)))
    id = Symbol(@inbounds(node["id"]))
    if !isbuiltinsort(id)
        # Rest of register_idof! Needed the ID to replace the duo.
        if isregistered(idregistry[], id)
            @warn "trying to register existing id $id in registry $(objectid(idregistry[]))" idregistry[]
        end
        register_id!(idregistry[], id)
    end

    name = attribute(node, "name")
    child = EzXML.firstelement(node)
    isnothing(child) && error("no sort definition element for namedsort $(repr(id)) $name")
    def = parse_sort(EzXML.firstelement(node), pntd, id)::AbstractSort # check for loops?
    isnothing(def) && error("failed to parse sort definition for namedsort $(repr(id)) $name")
    NamedSort(id, name, def)
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps an operator by giving a name to a definition term (expression in many-sorted algebra).

An operator of arity 0 is a constant.
When arity > 0, where is the parameter value stored? With operator or variable declaration
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "namedoperator")
    id = register_idof!(idregistry[], node)
    name = attribute(node, "name")

    def = nothing
    parameters = VariableDeclaration[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "def"
            # NamedOperators have a def element that is a expression of existing
            # operators &/or variable parameters that define the operation.
            # The sortof the operator is the output sort of def.
            def, _ = parse_term(EzXML.firstelement(child), pntd) #! todo term rewrite
        elseif tag == "parameter"
            # Zero or more parameters for operator (arity). Map from id to sort object.
            #! Allocate here? What is difference in Declarations and NamedOperator VariableDeclrations
            #! Is def restricted to just parameters? Can others access parameters?
            for vdecl in EzXML.eachelement(child)
                push!(parameters, parse_variabledecl(vdecl, pntd))
            end
        else
            @warn string("ignoring child of <namedoperator name=", name,", id=", id,"> ",
                    "with tag ", tag, ", allowed: 'def', 'parameter'")
        end
    end
    isnothing(def) &&
        throw(ArgumentError(string("<namedoperator",
                                    " name=", repr(name),
                                    " id=", repr(id),
                                    "> does not have a <def> element")))
    @warn "<namedoperator name=$(repr(name)) id=$(repr(id))>"
    NamedOperator(id, name, parameters, def) #! todo TermInterface rewrite
end




#=  From ePNK-pnml-examples/NetworkAlgorithms/runtimeValueEval.pnml

#? how do operators share variables as part of a firing rule?

<namedoperator id="id3" name="sum">
    <parameter> <!-- as many variabledecls as operator has variable subterms. -->
        <variabledecl id="id4" name="x">
            <integer/>
        </variabledecl>
        <variabledecl id="id5" name="y">
            <integer/>
        </variabledecl>
    </parameter>
    <def>
        <addition><!-- existing operator -->
            <subterm>
                <variable refvariable="id4"/>
            </subterm>
            <subterm>
                <variable refvariable="id5"/>
            </subterm>
        </addition>
    </def>
</namedoperator>
=#

#=

=#


#########################################################################################
"""
$(TYPEDSIGNATURES)
"""
function parse_variabledecl(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "variabledecl")
    id = register_idof!(idregistry[], node)
    name = attribute(node, "name")
    # firstelement throws on nothing. Ignore more than 1.
    #! There should be an actual way to store the value of the variable!
    #! Indexed by the id.  id can also map to (possibly de-duplicated) sort. And a eltype.
    #! All that work can be defered to a post-parse phase. Followed by the verification phase.

    # Variables are used during firing a transition to
    # identify tokens removed from input place marking to 1 or more output place markins.

    vsort = parse_sort(EzXML.firstelement(node), pntd, id)::UserSort
    isnothing(vsort) &&
        error("failed to parse sort definition for variabledecl $(repr(id)) $name")
    @warn "VariableDeclaration" id name vsort

    VariableDeclaration(id, name, vsort)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType)
    nn = EzXML.nodename(node)
    id = register_idof!(idregistry[], node)
    name = attribute(node, "name")
    @warn("parse unknown declaration: tag = $nn, id = $id, name = $name")
    content = AnyElement[anyelement(x, pntd) for x in EzXML.eachelement(node) if x !== nothing]
    return UnknownDeclaration(id, name, nn, content)
end

"""
    parse_feconstants(::XMLNode, ::PnmlType, ::REFID) -> Tuple{Symbols}

Place the constants into feconstants(). Return tuple of finite enumeration constant REFIDs.

Access as 0-ary operator indexed by REFID
"""
function parse_feconstants(node::XMLNode, pntd::PnmlType, sortrefid::REFID=:nothing)
    sorttag = EzXML.nodename(node)
    @assert sorttag in ("finiteenumeration", "cyclicenumeration") #? partition
    EzXML.haselement(node) || error("$sorttag has no child element")

    fec_refs = Symbol[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag != "feconstant"
            throw(MalformedException("$sorttag has unexpected child element $tag"))
        else
            id = register_idof!(idregistry[], child)
            name = attribute(child, "name")
            feconstants()[id] = FEConstant(id, name, sortrefid) #TODO partition/enumeration id?
            push!(fec_refs, id)
        end
    end
    return tuple(fec_refs...)
end

"Tags used in sort XML elements."
const sort_ids = (:usersort,
                  :dot, :bool, :integer, :natural, :positive, :real, # builtins
                  :multisetsort, :productsort,
                  :partition, # :partition is over a :finiteenumeration
                  :list, :strings,
                  :cyclicenumeration, :finiteenumeration, :finiteintrange)
"""
    make_usersort(tag::Symbol, name::String, sort) -> sort

Fill the declaration dictionary with a namedsort and usersort.
"""
function make_usersort(tag::Symbol, name::String, sort)
    fill_sort_tag!(tag, name, sort)
    return sort #usersort(tag) # Lookup and return.
end

# Singleton sorts map to unique named sorts. Some are built-ins.
function parse_sort(::Val{:dot}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    make_usersort(:dot, "Dot", DotSort())
end
function parse_sort(::Val{:bool}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    make_usersort(:bool, "Bool", BoolSort())
end

function parse_sort(::Val{:integer}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    make_usersort(:integer, "Integer", IntegerSort())
end

function parse_sort(::Val{:natural}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    make_usersort(:natural, "Natural", NaturalSort())
end

function parse_sort(::Val{:positive}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    make_usersort(:positive, "Positive", PositiveSort())
end

function parse_sort(::Val{:real}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    make_usersort(:real, "Real", RealSort())
end

# ############################################################
# # User Sort wraps a REFID to a NamedSort , AbstractSort, PartitionSort sort declaration.
function parse_sort(::Val{:usersort}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing) #! see parse_namedsort
    check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration")))
end

#!###########################################################
#! XXX TODO Sorts that are not singletons. Must be wrapped in a NamedSort or Partition

# is a finiteenumeration with additional operators: successor, predecessor
function parse_sort(::Val{:cyclicenumeration}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    check_nodename(node, "cyclicenumeration")
    CyclicEnumerationSort(parse_feconstants(node, pntd, refid))
end

function parse_sort(::Val{:finiteenumeration}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    check_nodename(node, "finiteenumeration")
    FiniteEnumerationSort(parse_feconstants(node, pntd, refid))
end

function parse_sort(::Val{:finiteintrange}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    check_nodename(node, "finiteintrange")
    start = parse(Int, attribute(node, "start"))
    stop = parse(Int, attribute(node, "end")) # XML Schema uses 'end', we use 'stop'.
    FiniteIntRangeSort(start, stop)
end

function parse_sort(::Val{:list}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    @error("IMPLEMENT ME: :list")
    #make_usersort(:list, "List", #TODO Wrap in UserSort,NamedSort duo.
    ListSort()
end

function parse_sort(::Val{:strings}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    @error("IMPLEMENT ME: :string")
    #make_usersort(:strings, "Strings", #TODO Wrap in UserSort,NamedSort duo.
    StringSort()
end

function parse_sort(::Val{:multisetsort}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    check_nodename(node, "multisetsort")
    EzXML.haselement(node) || throw(ArgumentError("multisetsort missing basis sort"))

    basisnode = EzXML.firstelement(node) # Assume basis sort will be first and only child.
    # Expect this to be a <usersort> wrapping <namedsort>, maybe someday <abstractsort>,
    # but not <partition> or <partitionelement>. Definitely not another multiset.

    tag = Symbol(EzXML.nodename(basisnode))
    println(":multisetsort basis tag = $tag")
    part_tags = (:partition, :partitionelement) #! XXX look inside usersort definition XXX
    tag in part_tags &&
        throw(ArgumentError("multisetsort basis $tag not allowed: $part_tags"))

    basissort = parse_sort(Val(tag), basisnode, pntd)::AbstractSort
    #! need to become a UserSort
    basissort = to_usersort(basissort)::UserSort
    MultisetSort(basissort)
end

to_usersort(x::UserSort) = x # identity
to_usersort(::IntegerSort) = usersort(:integer)
to_usersort(::NaturalSort) = usersort(:natural)
to_usersort(::PositiveSort) = usersort(:reapositivel)
to_usersort(::RealSort) = usersort(:real)
to_usersort(::DotSort) = usersort(:dot)
to_usersort(::NullSort) = usersort(:null)
to_usersort(::BoolSort) = usersort(:bool)

function to_usersort(x::AbstractSort)
    println("to_usersort($(nameof(typeof(x))))")
    error("XXX IMPLEMENT ME XXX")
end

#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort> element
function parse_sort(::Val{:productsort}, node::XMLNode, pntd::PnmlType, rid::REFID=:nothing)
    check_nodename(node, "productsort")

    sorts = REFID[] # Orderded collection of zero or more Sorts
    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        if tag === :usersort
            us = parse_sort(Val(tag), child, pntd, rid)::UserSort
            push!(sorts, refid(us)) # need REFID
        else
            throw(MalformedException("<productsort> contains unexpected sort $tag"))
        end
    end
    isempty(sorts) && throw(MalformedException("<productsort> contains no sorts"))
    #make_usersort(:productsort, "ProductSort",
    productsort = ProductSort(sorts)
    @show productsort; flush(stdout)
    return productsort
end

############################################################
"""
$(TYPEDSIGNATURES)

Sorts are found within an enclosing XML element, usually <structure>.
PNML maps the sort element name, frequently called a 'tag', to the body of the sort.
Heavily-used in the high-level abstract syntax tree.
Some nesting is used. Meaning that some sorts contain other sorts.

See also [`parse_sorttype_term`](@ref), [`parse_namedsort`](@ref), [`parse_variabledecl`](@ref).
"""
function parse_sort(node::XMLNode, pntd::PnmlType, refid::REFID=:nothing)
    # Note: Sorts are not PNML labels. Will not have <text>, <graphics>, <toolspecific>.
    sortid = Symbol(EzXML.nodename(node))
    sort = if sortid in sort_ids
        parse_sort(Val(sortid), node, pntd, refid)::AbstractSort #Union{NamedSort, UserSort}
    else
        @error("parse_sort $(repr(sortid)) not implemented: allowed: $sort_ids.")
    end
    return sort
end

"""
$(TYPEDSIGNATURES)

Returns [`UserSort`](@ref) wraping the REFID of a [`NamedSort`](@ref) or [`AbstractSort`](@ref).
"""
function parse_usersort(node::XMLNode, pntd::PnmlType)
    check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration")))
end
