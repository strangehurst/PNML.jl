#=
There are many attribute-label elements.
The common usage is that 'label' usually be read as annotation-label.

Attribute-labels do not have associated graphics elements. Since <graphics> are
optional for annotation-labels they share the same implementation.

Unknown tags get parsed by `unparsed_tag`.
=#


"""
$(TYPEDSIGNATURES)

Fill `dd::[`DeclDict`](@ref)` from one or more `<declaration>` labels.

Expected format: `<declaration> <structure> <declarations> <namedsort/> <namedsort/> ...`

Assume behavior with the meaning in a <structure> for all nets.

Note the use of both declaration and declarations.
We allow repeated declaration (without the s) here.
All fill the same `DeclDict`. See [`fill_decl_dict!`](@ref)
"""
function parse_declaration! end
function parse_declaration!(ctx::ParseContext, node::XMLNode, pntd::PnmlType)
    parse_declaration!(ctx, [node], pntd)
end
function parse_declaration!(ctx::ParseContext, nodes::Vector{XMLNode}, pntd::PnmlType)
    #println("\nparse_declaration")

    text = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}}  = nothing
    for node in nodes
        check_nodename(node, "declaration")
        for child in EzXML.eachelement(node)
            tag = EzXML.nodename(child)
            if tag == "structure" # accumulate declarations
                fill_decl_dict!(ctx, child, pntd) # Assumes high-level semantics.
            elseif tag == "text" # may overwrite
                text = string(strip(EzXML.nodecontent(child)))::String
                #@info "declaration text: $text" # Do not expect text here, so it must be important.
            elseif tag == "graphics"# may overwrite
                graphics = parse_graphics(child, pntd)
            elseif tag == "toolspecific" # accumulate tool specific
                tools = add_toolinfo(tools, child, pntd, ctx) # declarations are labels
            else
                @warn "ignoring unexpected child of <declaration>: '$tag'"
            end
        end
    end

    Declaration(; text, ctx.ddict, graphics, tools)
end

"""
    fill_decl_dict!(ctx::ParseContext, node::XMLNode, pntd::PnmlType) -> ParseContext

Add `<declaration>` `<declarations>` to ParseContext.
`<declaration>` may be attached to `<net>` and `<page>` elements.
Each will have contents in a `<structure>` element.
Are net-level values.
"""
function fill_decl_dict!(ctx::ParseContext, node::XMLNode, pntd::PnmlType)
    check_nodename(node, "structure")
    EzXML.haselement(node) ||
        throw(ArgumentError("missing <declaration><structure> element"))
    declarations = EzXML.firstelement(node) # Only child node must be `<declarations>`.
    check_nodename(declarations, "declarations")
    unknown_decls = AbstractDeclaration[]

    for child in EzXML.eachelement(declarations)
        tag = EzXML.nodename(child)
        if tag == "namedsort" # make usersort, namedsort duo
            ns = parse_namedsort(child, pntd; parse_context=ctx)::SortDeclaration
            PNML.namedsorts(ctx.ddict)[pid(ns)] = ns
            PNML.usersorts(ctx.ddict)[pid(ns)] = UserSort(pid(ns), ctx.ddict)
        elseif tag == "namedoperator"
            no = parse_namedoperator(child, pntd; parse_context=ctx)
            PNML.namedoperators(ctx.ddict)[pid(no)] = no
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(child, pntd; parse_context=ctx)
            PNML.variabledecls(ctx.ddict)[pid(vardecl)] = vardecl
        elseif tag == "partition" # usersort, partitionsort duo.
            part = parse_partition(child, pntd; parse_context=ctx)::SortDeclaration
            PNML.partitionsorts(ctx.ddict)[pid(part)] = part
            PNML.usersorts(ctx.ddict)[pid(part)] = part

        #TODO Where do we find these things? Is this were they are de-duplicated?
        #! elseif tag === :partitionoperator # PartitionLessThan, PartitionGreaterThan, PartitionElementOf
        #!    partop = parse_partition_op(child, pntd)
        #!     dd.partitionops[pid(partop)] = partop

        elseif tag == "arbitrarysort" # TODO
            @warn "arbitrarysort declaration not supported yet"
            # arb = parse_arbitrarysort(child, pntd)
            # PNML.variabledecls(dd)[pid(arb)] = arb
       else
            #TODO add unknown_decls to DeclDict
            push!(unknown_decls, parse_unknowndecl(child, pntd; parse_context=ctx))
        end
    end
    return ctx
end

"""
$(TYPEDSIGNATURES)

Declaration that wraps a Sort, adding an ID and name.
"""
function parse_namedsort(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "namedsort")
    # Will have created usersort, namedsort duos for builtin sorts.
    # Replacement of those duos, in particular, :dot, will trigger a duplicate id error
    # unless the `(builtinsorts)` are excluded from the register_idof! check.
    # Note: builtin sort definitions are all singleton types.
    EzXML.haskey(node, "id") || throw(PNML.MissingIDException(EzXML.nodename(node)))
    id = Symbol(@inbounds(node["id"]))
    if !Sorts.isbuiltinsort(id)
        # Rest of register_idof! Needed the ID to replace the duo.
        if isregistered(parse_context.idregistry, id)
            @warn "registering existing id $id in $(objectid(parse_context.idregistry))" parse_context.idregistry
        end
        register_id!(parse_context.idregistry, id)
    end

    name = attribute(node, "name")
    child = EzXML.firstelement(node)
    isnothing(child) && error("no sort definition element for namedsort $(repr(id)) $name")
    def = parse_sort(EzXML.firstelement(node), pntd, id; parse_context)::AbstractSort # check for loops?
    isnothing(def) && error("failed to parse sort definition for namedsort $(repr(id)) $name")
    NamedSort(id, name, def, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)

Declaration of an operator expression in many-sorted algebra.

An operator of arity 0 is a constant (ground-term, literal).
When arity > 0, the parameters are variables, using a NamedTuple for values.
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "namedoperator")
    id = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    #^ ePNK uses inline variabledecl, variable in namedoperator declaration
    #! Must register id of variabledecl before seeing variable: `<parameter>` before `<def>`.
    parameters = VariableDeclaration[]
    def = nothing

    pnode = firstchild(node, "parameter")
    if !isnothing(pnode)
        # Zero or more parameters for operator (arity). Map from id to sort object.
        for vdecl in EzXML.eachelement(pnode)
            push!(parameters, parse_variabledecl(vdecl, pntd; parse_context))
        end
    end
    @show parameters parse_context.idregistry

    dnode = firstchild(node, "def")
    if !isnothing(dnode)
        # NamedOperators have a def element that is a expression of existing
        # operators &/or variable parameters that define the operation.
        # The sortof the operator is the output sort of def.
        def, _, vars = parse_term(EzXML.firstelement(dnode), pntd; vars=(), parse_context)
        if !isempty(vars)
            @error "named operator has variables" id name def vars
            #! length(vars) == arity(def)
        end
    else
        throw(ArgumentError(string("<namedoperator",
                                    " name=", repr(name),
                                    " id=", repr(id),
                                    "> does not have a <def> element")))
    end
    @warn "<namedoperator name=$(repr(name)) id=$(repr(id))>" parameters #! debug
    NamedOperator(id, name, parameters, def, parse_context.ddict)

    # for child in EzXML.eachelement(node)
    #     tag = EzXML.nodename(child)
    #     if tag == "def"
    #         # NamedOperators have a def element that is a expression of existing
    #         # operators &/or variable parameters that define the operation.
    #         # The sortof the operator is the output sort of def.
    #         def, _, vars = parse_term(EzXML.firstelement(child), pntd; vars=(), parse_context)
    #         if !isempty(vars)
    #             @error "named operator has variables" id name def vars
    #             #! length(vars) == arity(def)
    #         end
    #     elseif tag == "parameter"
    #         # Zero or more parameters for operator (arity). Map from id to sort object.
    #         #! Allocate here? What is difference in Declarations and NamedOperator VariableDeclarations
    #         #! Is def restricted to just parameters? Can others access parameters?
    #         for vdecl in EzXML.eachelement(child)
    #             push!(parameters, parse_variabledecl(vdecl, pntd; parse_context))
    #         end
    #         # Create the object in declaration that is referenced by VariableEx's REFID.
    #     else
    #         @warn string("ignoring child of <namedoperator name=", name,", id=", id,"> ",
    #                 "with tag ", tag, ", allowed: 'def', 'parameter'")
    #     end
    # end
end




#=
From ePNK-pnml-examples/NetworkAlgorithms/runtimeValueEval.pnml
<namedoperator id="id3" name="sum">
    <parameter> <!-- as many variabledecls as operator has variable subterms. -->
        <variabledecl id="id4" name="x"> <integer/> </variabledecl>
        <variabledecl id="id5" name="y"> <integer/> </variabledecl>
    </parameter>
    <def>
        <addition><!-- existing operator -->
            <subterm> <variable refvariable="id4"/> </subterm>
            <subterm> <variable refvariable="id5"/> </subterm>
        </addition>
    </def>
</namedoperator>
=#

#########################################################################################
"""
    parse_variabledecl(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) -> VariableDeclaration

Variables are used during firing a transition to identify tokens
removed from input place markings, added to output place markings.
"""
function parse_variabledecl(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "variabledecl")
    id = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    # firstelement throws on nothing. Ignore more than 1.
    vsort = parse_sort(EzXML.firstelement(node), pntd, id; parse_context)
    @show vsort
    isnothing(vsort) &&
        error("failed to parse sort definition for variabledecl $(repr(id)) $name")
    # There is a usersort created for every built-in sort, #todo multisetsorts, productsorts
    ddict = parse_context.ddict
    #!VariableDeclaration(id, name, vsort, ddict)
    VariableDeclaration(id, name, to_usersort(vsort; ddict)::Sort, ddict)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) #? just a label?
    nn = EzXML.nodename(node)
    id = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    unkncontent = [anyelement(x, pntd) for x in EzXML.eachelement(node) if x !== nothing]
    @warn("parse unknown declaration: tag = $nn, id = $id, name = $name", unkncontent)
    return UnknownDeclaration(id, name, nn, unkncontent, parse_context.ddict)
end

"""
    parse_feconstants(::XMLNode, ::PnmlType, ::REFID; ddict) -> Tuple{Symbols}

Place the constants into feconstants(). Return tuple of finite enumeration constant REFIDs.

Access as 0-ary operator indexed by REFID
"""
function parse_feconstants(node::XMLNode, pntd::PnmlType, sortrefid::REFID=:nothing; parse_context::ParseContext)
    sorttag = EzXML.nodename(node)
    @assert sorttag in ("finiteenumeration", "cyclicenumeration") #? partition also?
    EzXML.haselement(node) || error("$sorttag has no child element")

    fec_refs = Symbol[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag != "feconstant"
            throw(PNML.MalformedException("$sorttag has unexpected child element $tag"))
        else
            id = register_idof!(parse_context.idregistry, child)
            name = attribute(child, "name")
            PNML.feconstants(parse_context.ddict)[id] =
                PNML.FEConstant(id, name, sortrefid, parse_context.ddict)
            #TODO partition/enumeration id?
            push!(fec_refs, id)
        end
    end
    return tuple(fec_refs...) #todo NTuple?
end

"""
$(TYPEDSIGNATURES)

Returns [`UserSort`](@ref) wraping the REFID of a [`NamedSort`](@ref),
 [`ArbitrarySort`](@ref). or [`PartitionSort`](@ref)
"""
function parse_usersort(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration")), parse_context.ddict)
end

"""
    make_usersort!(dd::DeclDict, tag::Symbol, name::String, sort) -> sort

Fill the declaration dictionary with a namedsort and usersort.
"""
function make_usersort!(ctx::ParseContext, tag::Symbol, name::String, sort)
    PNML.fill_sort_tag!(ctx, tag, name, sort)
    return sort #usersorts(ddict)[tag] # Lookup and return.
end

"Tag names of sort XML elements."
const sort_ids = (:usersort,
                  :dot, :bool, :integer, :natural, :positive, :real, # builtins
                  :multisetsort, :productsort,
                  :cyclicenumeration, :finiteenumeration, :finiteintrange,
                  :partition, # over a :finiteenumeration or :cyclicenumeration
                  :list, :strings,
                  )

"""
$(TYPEDSIGNATURES)

Sorts are found within an enclosing XML element, usually <structure>.
PNML maps the sort element name, frequently called a 'tag', to the body of the sort.
Heavily-used in the high-level abstract syntax tree.
Some nesting is used. Meaning that some sorts contain other sorts.

See also [`parse_sorttype_term`](@ref), [`parse_namedsort`](@ref), [`parse_variabledecl`](@ref).
"""
function parse_sort(node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    # Note: Sorts are not PNML labels. Will not have <text>, <graphics>, <toolspecific>.
    sortid = Symbol(EzXML.nodename(node))
    sort = if sortid in sort_ids
        parse_sort(Val(sortid), node, pntd, refid; parse_context)::AbstractSort #Union{NamedSort, UserSort}
    else
        @error("parse_sort $(repr(sortid)) not implemented: allowed: $sort_ids.")
    end
    return sort
end

# Singleton sorts map to named sorts that have no type parameters. Some are built-ins.
function parse_sort(::Val{:dot}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    make_usersort!(parse_context, :dot, "Dot", DotSort(parse_context.ddict))
end
function parse_sort(::Val{:bool}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    make_usersort!(parse_context, :bool, "Bool", BoolSort())
end

function parse_sort(::Val{:integer}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    make_usersort!(parse_context, :integer, "Integer", IntegerSort())
end

function parse_sort(::Val{:natural}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    make_usersort!(parse_context, :natural, "Natural", NaturalSort())
end

function parse_sort(::Val{:positive}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    make_usersort!(parse_context, :positive, "Positive", PositiveSort())
end

function parse_sort(::Val{:real}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    make_usersort!(parse_context, real, "Real", RealSort())
end

# ############################################################
# # User Sort wraps a REFID to a NamedSort , AbstractSort, PartitionSort sort declaration.
function parse_sort(::Val{:usersort}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext) #! see parse_namedsort
    check_nodename(node, "usersort")
    UserSort(Symbol(attribute(node, "declaration")), parse_context.ddict)
end

#!###########################################################
#! XXX TODO Sorts that are not singletons. Must be wrapped in a NamedSort or Partition

# is a finiteenumeration with additional operators: successor, predecessor
function parse_sort(::Val{:cyclicenumeration}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    check_nodename(node, "cyclicenumeration")
    CyclicEnumerationSort(parse_feconstants(node, pntd, refid; parse_context), nothing, parse_context.ddict)
end

function parse_sort(::Val{:finiteenumeration}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    check_nodename(node, "finiteenumeration")
    FiniteEnumerationSort(parse_feconstants(node, pntd, refid; parse_context), nothing, parse_context.ddict)
end

function parse_sort(::Val{:finiteintrange}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    check_nodename(node, "finiteintrange")
    start = parse(Int, attribute(node, "start"))
    stop = parse(Int, attribute(node, "end")) # XML Schema uses 'end', we use 'stop'.
    FiniteIntRangeSort(start, stop, refid, parse_context.ddict)
end

function parse_sort(::Val{:list}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    @error("IMPLEMENT ME: :list")
    #make_usersort!(dict, :list, "List", #TODO Wrap in UserSort,NamedSort duo.
    ListSort()
end

function parse_sort(::Val{:strings}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    @error("IMPLEMENT ME: :string")
    #make_usersort!(ddict, :strings, "Strings", #TODO Wrap in UserSort,NamedSort duo.
    StringSort()
end

function parse_sort(::Val{:multisetsort}, node::XMLNode, pntd::PnmlType, refid::REFID=:nothing; parse_context::ParseContext)
    check_nodename(node, "multisetsort")
    EzXML.haselement(node) || throw(ArgumentError("multisetsort missing basis sort"))

    # Expect basis to be a <usersort> wrapping <namedsort> for symmetricnet,
    # but not <partition> or <partitionelement>. Definitely not another multiset.
    # NB: We wrap built-in sorts in a user/named duo.
    #^ ePNK highlevelnet inlines product sort inside a place `<type><structure><multisetsort>`
    # maybe someday <arbitrarysort>

    basisnode = EzXML.firstelement(node) # Assume basis sort will be first and only child.
    tag = Symbol(EzXML.nodename(basisnode))
    invalid_basis = (:partition, :partitionelement, :multisetsort)

    tag in invalid_basis && #! look inside usersort basis definition XXX
        throw(ArgumentError("multisetsort basis $tag not allowed")) #todo test this!

    basissort = parse_sort(Val(tag), basisnode, pntd; parse_context)::AbstractSort

    #
    us = to_usersort(basissort; parse_context.ddict)::UserSort

    MultisetSort(us, parse_context.ddict)
end

to_usersort(x::Sorts.UserSort; ddict) = identity(x)
to_usersort(::Sorts.IntegerSort; ddict) = usersorts(ddict)[:integer]
to_usersort(::Sorts.NaturalSort; ddict) = usersorts(ddict)[:natural]
to_usersort(::Sorts.PositiveSort; ddict) = usersorts(ddict)[:positive]
to_usersort(::Sorts.RealSort; ddict) = usersorts(ddict)[:real]
to_usersort(::Sorts.DotSort; ddict)  = usersorts(ddict)[:dot]
to_usersort(::Sorts.NullSort; ddict) = usersorts(ddict)[:null]
to_usersort(::Sorts.BoolSort; ddict) = usersorts(ddict)[:bool]
to_usersort(x::Sorts.AbstractSort; ddict) = identity(x)


#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort> element
function parse_sort(::Val{:productsort}, node::XMLNode, pntd::PnmlType, rid::REFID=:nothing; parse_context::ParseContext)
    check_nodename(node, "productsort")
    sorts = REFID[] # Orderded collection of zero or more Sorts
    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        s = parse_sort(Val(tag), child, pntd, rid; parse_context)::AbstractSort
        # @show s # @assert Base.isconcretetype(s)
        push!(sorts, PNML.refid(s)) # requires there to be a REFID
    end
    isempty(sorts) && throw(PNML.MalformedException("<productsort> contains no sorts"))
    return ProductSort(tuple(sorts...), parse_context.ddict)
end


#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_partition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) #! partition is a sort declaration!
    id = register_idof!(parse_context.idregistry, node)
    nameval = attribute(node, "name")
    #@warn "partition $(repr(id)) $nameval"; flush(stdout);  #! debug
    psort::Maybe{UserSort} = nothing
    elements = PartitionElement[] # References into psort that form a equivalance class.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # The sort that partitionelements reference into.
            #TODO pass REFID?
            psort = parse_usersort(child, pntd; parse_context)::UserSort #? sortof isa EnumerationSort
        elseif tag === "partitionelement" # Each holds REFIDs to sort elements of the enumeration.
            parse_partitionelement!(elements, child, id; parse_context) # pass REFID to partition
        else
            throw(PNML.MalformedException(string("partition child element unknown: ", tag,
                                " allowed are usersort, partitionelement")))
        end
    end
    isnothing(psort) &&
        throw(ArgumentError("<partition id=$id, name=$nameval> <usersort> element missing"))

    # One or more partitionelements.
    isempty(elements) &&
        error("partitions must have at least one partition element, found none: ",
                "id = ", repr(id), ", name = ", repr(nameval), ", sort = ", repr(psort))

    #~verify_partition(sort, elements)

    return PNML.PartitionSort(id, nameval, psort.declaration, elements, parse_context.ddict) # A Declaraion named Sort!
end

"""
    parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode; ddict)

Parse `<partitionelement>`, add FEConstant refids to the element and append element to the vector.
"""
function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode, rid::REFID; parse_context::ParseContext)
    check_nodename(node, "partitionelement")
    id = register_idof!(parse_context.idregistry, node)
    nameval = attribute(node, "name")
    terms = REFID[] # Ordered collection, usually feconstant.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag === "useroperator"
            # PartitionElements refer to the FEConstants of the referenced finite sort.
            # UserOperator here holds an REFID to a FEConstant callable object.
            refid = Symbol(attribute(child, "declaration"))
            PNML.has_feconstant(parse_context.ddict, refid) ||
                error("refid $refid not found in feconstants") #! move to verify?
            push!(terms, refid)
        else
            # Are ProductSorts allowed?
            throw(PNML.MalformedException("partitionelement child element unknown: $tag"))
        end
    end
    isempty(terms) && throw(ArgumentError("<partitionelement id=$id, name=$nameval> has no terms"))

    push!(elements, PartitionElement(id, nameval, terms, rid, parse_context.ddict)) # rid is REFID to enclosing partition
    return elements
end

############################################################
