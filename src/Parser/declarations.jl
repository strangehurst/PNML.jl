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
    toolspecinfos::Maybe{Vector{ToolInfo}}  = nothing
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
                toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, ctx) # declarations are labels
            else
                @warn "ignoring unexpected child of <declaration>: '$tag'"
            end
        end
    end

    Declaration(; text, ctx.ddict, graphics, toolspecinfos) # context ddict
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
            PNML.namedsorts(ctx.ddict)[pid(ns)] = ns # fill_decl_dict! namedsort
            PNML.usersorts(ctx.ddict)[pid(ns)] = UserSort(pid(ns), ctx.ddict) # fill_decl_dict!
        elseif tag == "namedoperator"
            no = parse_namedoperator(child, pntd; parse_context=ctx) #::NamedOperator
            PNML.namedoperators(ctx.ddict)[pid(no)] = no # fill_decl_dict! namedoperator
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(child, pntd; parse_context=ctx)
            PNML.variabledecls(ctx.ddict)[pid(vardecl)] = vardecl # fill_decl_dict! variabledecl
        elseif tag == "partition" # usersort, partitionsort duo.
            # NB: partiton is a declaration of a new sort refering to the partitioned sort.
            part = parse_partition(child, pntd; parse_context=ctx)::PartitionSortRef
            #PNML.partitionsorts(ctx.ddict)[refid(part)] = part
            #!@show ctx.ddict
            #PNML.usersorts(ctx.ddict)[pid(part)] = part # fill_decl_dict! partitionsort duo

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
    sortid = Symbol(@inbounds(node["id"]))
    if !Sorts.isbuiltinsort(sortid)
        # Rest of register_idof! Needed the ID to replace the duo.
        if isregistered(parse_context.idregistry, sortid)
            @warn "registering existing id $sortid in $(objectid(parse_context.idregistry))" parse_context.idregistry
        end
        register_id!(parse_context.idregistry, sortid)
    end

    name = attribute(node, "name")
    child = EzXML.firstelement(node)
    isnothing(child) && error("no sort definition element for namedsort $(repr(sortid)) $name")
    ddict = parse_context.ddict

    # Sort can be built-in, multiset, product.
    nameddef = parse_sort(EzXML.firstelement(node), pntd, sortid, name; parse_context)::SortRef
    isnothing(nameddef) && error("failed to parse sort definition for namedsort $(repr(sortid)) $name")

    #? check for loops?
    #@show nameddef
    sort = to_sort(nameddef; ddict)
    if isa(sort, NamedSort)
        #@error "nameddef isa NamedSortRef" refid(nameddef)
        sort = sortdefinition(sort)
    end

    NamedSort(sortid, name, sort, ddict) #! 2025-07-21 use SortRef

    # SortRef concrete type holds REFID and implicit dictionary of `DeclDict`
    # `usersorts, and `namedsorts` are some of the dictionaries.
    # Others: `arbitrarysorts`, 'partitionsorts`, `productsorts`, `multisetsorts`.
    # NB: The user/named duo is used for built-in sorts.
    # Symmetric nets use `EnumerationSort`s & the duo mechanism to add id and name.
    # `PartitionSort` uses a usersort to identify the `EnumerationSort`
    # `MultisetSort`
end

"""
$(TYPEDSIGNATURES)

Declaration of an operator expression in many-sorted algebra.

An operator of arity 0 is a constant (ground-term, literal).
When arity > 0, the parameters are variables, using a NamedTuple for values.
"""
function parse_namedoperator(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "namedoperator")
    nopid = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    println("parse_namedoperator $(repr(nopid)) $(repr(name))") #! debug

    #^ ePNK uses inline variabledecl, variable in namedoperator declaration
    #! Must register id of variabledecl before seeing variable: `<parameter>` before `<def>`.
    parameters = VariableDeclaration[]
    def = nothing

    pnode = firstchild(node, "parameter")
    if !isnothing(pnode)
        # Zero or more parameters for operator (arity). Map from id to sort object.
        for vdeclnode in EzXML.eachelement(pnode)
            vardecl = parse_variabledecl(vdeclnode, pntd; parse_context)
            PNML.variabledecls(parse_context.ddict)[pid(vardecl)] = vardecl # parse_namedoperator
            push!(parameters, vardecl)
        end
    end
    # @show parameters parse_context.idregistry #! debug

    dnode = firstchild(node, "def")
    # NamedOperators have a def element that is a expression of existing
    # operators &/or variable parameters that define the operation.
    # The sortof the operator is the output sort of def.
    isnothing(dnode) &&
        error("<namedoperator name=$(repr(name)) id=$(repr(nopid))>",
                " does not have a <def> element")

    tj = parse_term(EzXML.firstelement(dnode), pntd; vars=(), parse_context)
    isempty(tj.vars) ||
        error("<namedoperator name=$(repr(name)) id=$(repr(nopid))>",
                "  has variables: ",  tj)

    NamedOperator(nopid, name, parameters, tj.exp, parse_context.ddict)

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

Variables are used in evaluating an `<namedoperator.>`

Variabledecls provide a name and sort.

Variabledecls may appear in the definition of an operator
as well as directly in a declaration.
"""
function parse_variabledecl(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "variabledecl")
    varid = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    # firstelement throws on nothing. Ignore more than 1.
    vsortref = parse_sort(EzXML.firstelement(node), pntd, varid, name; parse_context)::SortRef
    #println("parse_variabledecl $(repr(varid)) $(repr(name)) $(repr(vsortref))") #! debug
    isnothing(vsortref) &&
        error("failed to parse sort definition for variabledecl $(repr(varid)) $name")
    # There is a usersort created for every built-in sort, #todo multisetsorts, productsorts
    VariableDeclaration(varid, name, vsortref, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) #? just a label?
    nn = EzXML.nodename(node)
    unkid = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    unkncontent = [anyelement(x) for x in EzXML.eachelement(node) if x !== nothing]
    @warn("parse unknown declaration: tag = $nn, id = $unkid, name = $name", unkncontent)
    return UnknownDeclaration(unkid, name, nn, unkncontent, parse_context.ddict)
end

"""
    parse_feconstants(::XMLNode, ::PnmlType, ::REFID; ddict) -> Tuple{<:SortRef}

Place the constants into feconstants(). Return tuple of finite enumeration constant REFIDs.

Access as 0-ary operator indexed by REFID
"""
function parse_feconstants(node::XMLNode, pntd::PnmlType, sortref::SortRef; parse_context::ParseContext)
    sorttag = EzXML.nodename(node)
    @assert sorttag in ("finiteenumeration", "cyclicenumeration") #? partition also?
    EzXML.haselement(node) || error("$sorttag has no child element")

    fec_refs = Symbol[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag != "feconstant"
            throw(PNML.MalformedException("$sorttag has unexpected child element $tag"))
        else
            fecid = register_idof!(parse_context.idregistry, child)
            name = attribute(child, "name")
            PNML.feconstants(parse_context.ddict)[fecid] =
                PNML.FEConstant(fecid, name, sortref,  parse_context.ddict) #= sortref =#
            push!(fec_refs, fecid)
        end
    end
    return fec_refs #todo NTuple?
end

"""
$(TYPEDSIGNATURES)

Returns concrete [`SortRef`](@ref) wraping the REFID of a
[`NamedSort`](@ref), [`ArbitrarySort`](@ref). or [`PartitionSort`](@ref).
"""
function parse_usersort(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "usersort")
    #UserSort(Symbol(attribute(node, "declaration")), parse_context.ddict) #todo UserSortRef
    declid = Symbol(attribute(node, "declaration"))
    if PNML.has_namedsort(parse_context.ddict, declid)
        NamedSortRef(declid)
    elseif PNML.has_partitionsort(parse_context.ddict, declid)
        PartitionSortRef(declid)
    elseif PNML.arbitrarysort(parse_context.ddict, declid)
        ArbitrarySortRef(declid)
    else
        error("Did not find sort declaration for $(repr(declid))")
    end
end

"Tag names of sort XML elements."
const sort_ids = (:usersort, :dot, :bool, :integer, :natural, :positive, :real,
                  :multisetsort, :productsort, # have sortref as content
                  :cyclicenumeration, :finiteenumeration, :finiteintrange,
                  :partition, # over a :finiteenumeration or :cyclicenumeration
                  :list, :strings,
                  )
#=
Sorts are found within an enclosing XML element, usually <structure>.
PNML maps the sort element name, frequently called a 'tag', to the body of the sort.
Heavily-used in the high-level abstract syntax tree.
Some nesting is used. Meaning that some sorts contain other sorts.

Most sorts are enclosed in a UserSort/NamedSort duo.
Some sorts are anonymous (have no id) in the XML.
NB: sort equality is structural (`==` not `===`).
We invent a REFID/name duo for anonymous sorts (and built-in sorts)
with a NamedSort holding the concrete sort.
=#

"""
    parse_sort(node::XMLNode, pntd::PnmlType,
                id::Maybe{REFID}=nothing, name::String="";
                parse_context::ParseContext)
    parse_sort(::Val{:tag}, node::XMLNode, pntd::PnmlType, id, name;
                parse_context::ParseContext)


Where `tag` is the XML element tag name for a parser invoked using Val{:tag}.

See also [`parse_sorttype_term`](@ref), [`parse_namedsort`](@ref), [`parse_variabledecl`](@ref).
"""
function parse_sort(node::XMLNode, pntd::PnmlType, id::Maybe{REFID}=nothing,  name::String=""; parse_context::ParseContext)
    # Note: Sorts are NOT PNML labels. Will NOT have <text>, <graphics>, <toolspecific>.
    sorttag = Symbol(EzXML.nodename(node))
    #println("\n## parse_sort $id $name tag = $(repr(sorttag))") #! debug
    return parse_sort(Val(sorttag), node, pntd, id, name; parse_context)::SortRef
end

# Built-ins sorts
# ! 2025-07-21 SortRef refactor, make these return a direct UserSortRef.
#! The insertion into decldict in done in `fill_sort_tag!` from `fill_nonhl!`
#! as initial part of `PnmlNet` parsing.
#! Followed by parsing all declarations where `parse_sort is used`.
#! Then the net where terms use sorts.

function parse_sort(::Val{:bool}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    UserSortRef(:bool)
end

function parse_sort(::Val{:integer}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    UserSortRef(:integer)
end

function parse_sort(::Val{:natural}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    UserSortRef(:natural)
end

function parse_sort(::Val{:positive}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    UserSortRef(:positive)
end

function parse_sort(::Val{:real}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    UserSortRef(:real)
end

#############################################################
# In the ISO 15909 standard UserSort wraps a REFID to a
# NamedSort , AbstractSort, or PartitionSort sort declaration.
#
# To reduce coupling `SortRef` abstract type is introduced.
#
# Concrete `SortRef` subtypes hold a REFID
# and implicitly identify the dictionary in the `DeclDict` that holds the sort.

# We use `NamedSort` declarations to instantiate built-in sorts. The user assumes they
# have the expected and obvious REFID/name duo.

# NamedSorts can be used to instantiate non-singleton sorts, see `EnumerationSort`s.
# Here the user is accessing a built-in or a defined sort by REFID.
#
# NB: ePNK examples uses some inlined sorts

function parse_sort(::Val{:dot}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    NamedSortRef(:dot) # The user overrides in a declaration.
end

function parse_sort(::Val{:usersort}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext) #! see parse_namedsort
    check_nodename(node, "usersort")
    # The name "declaration" reminds that this is the REFID of a
    # NamedSort, PartitionSort, or ArbitrarySort declaration. Open to more in the future.
    us = UserSort(Symbol(attribute(node, "declaration")), parse_context.ddict) # <usersort
    usersorts(parse_context.ddict)[refid(us)] = us # parse_sort usersort
    return UserSortRef(refid(us)) #! NOT ALWAYS a NamedSort, we do not know flavor of refid.
end


#!##########################################################and SortRef#
#! XXX TODO Sorts that are not singletons. Must be wrapped in a NamedSort or Partition.
#! XXX Invent id/name duo to wrap anonymous inline sorts.
# Any REFID in the input XML must take precedence.
# ? Can multiple REFIDs refer to the same sort? Yes, ISO 15909 says id/name are optional.
# Sorts are expected to be comaparable for equality, that is what matters,
# and specificially inline sorts are allowed and expected in some places.
# Assume parsing is a smallish up-front cost; enabling & firing rules is the big work.
# It is more important (for the big work) to be cache-friendly.
#
#? When is the REFID of a sort meaninful?
#  - Index into DeclDict to access concrete sort object
#       2 or more concrete sort objects (2 entries in dictionary) may be `equalSorts`
#  -



# is a finiteenumeration with additional operators: successor, predecessor
function parse_sort(::Val{:cyclicenumeration}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    check_nodename(node, "cyclicenumeration")
    println("cyclicenumeration $(repr(id)), $(repr(name))") #! debug
    fecs = parse_feconstants(node, pntd, UserSortRef(id); parse_context)
    ces = CyclicEnumerationSort(fecs, nothing, parse_context.ddict)
    sref = make_sortref(parse_context, PNML.namedsorts, ces, "cyclicenumeration", id, name)::NamedSortRef
    return sref
end

function parse_sort(::Val{:finiteenumeration}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    check_nodename(node, "finiteenumeration")
    println("finiteenumeration $(repr(id)), $(repr(name))") #! debug
    fecs = parse_feconstants(node, pntd, UserSortRef(id); parse_context)
    fes = FiniteEnumerationSort(fecs, nothing, parse_context.ddict)
    sref = make_sortref(parse_context, PNML.namedsorts, fes, "finiteenumeration", id, name)::NamedSortRef
    return sref
end

function parse_sort(::Val{:finiteintrange}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    check_nodename(node, "finiteintrange")

    # start = parse(Int, attribute(node, "start"))
    # stop = parse(Int, attribute(node, "end")) # XML Schema uses 'end', we use 'stop'.
    startstr = attribute(node, "start")
    startval = tryparse(Int, startstr)
    isnothing(startval) &&
        throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`"))

    stopstr = attribute(node, "end") # XML Schema uses 'end', we use 'stop'.
    stopval = tryparse(Int, stopstr)
    isnothing(stopval) &&
        throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`"))

    # See function parse_term(::Val{:finiteintrangeconstant} for inline sort use.
    # Look for `sort` in `namedsorts(ddict)`, else create named/user duo.
    sorttag = Symbol("FiniteIntRange_",startstr,"_",stopstr)
    if haskey(namedsorts(parse_context.ddict), sorttag)
        return NamedSortRef(sorttag)
    else
        # Did not find namedsort, will instantiate named,user duo for one.
        # See fill_nonhl!
        @show sort = FiniteIntRangeSort(startval, stopval, parse_context.ddict)
        # fill_sort_tag!(parse_context, sorttag, NamedSort(sorttag, string(sorttag), sort, parse_context.ddict))::NamedSortRef
        # usersorts(parse_context.ddict)[sorttag] = UserSort(sorttag, parse_context.ddict)
        # return UserSortRef(sorttag)
        sref = make_sortref(parse_context, PNML.namedsorts, sort, "finiteintrange", sorttag, name)::NamedSortRef
        return sref
    end
end

function parse_sort(::Val{:list}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    @error("IMPLEMENT ME: :list")
    #make_sort!(dict, :list, "List", #TODO Wrap in UserSort,NamedSort duo.
    ListSort()
end

function parse_sort(::Val{:strings}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    @error("IMPLEMENT ME: :string")
    #make_sort!(ddict, :strings, "Strings", #TODO Wrap in UserSort,NamedSort duo.
    StringSort()
end

function parse_sort(::Val{:multisetsort}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
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

    basissort = parse_sort(Val(tag), basisnode, pntd, nothing, ""; parse_context)::SortRef # of multisetsort

    ms = MultisetSort(basissort, parse_context.ddict)
    return make_sortref(parse_context, PNML.multisetsorts, ms, "multiset", id, name)::MultisetSortRef
end

"""
    to_sort(sortref::SortRef; ddict::DeclDict) -> AbstractSort

Return concrete sort from `ddict` using the `REFID` in `sortref`,
"""
function to_sort end #TODO make part of the ADT
to_sort(sortref::UserSortRef; ddict::DeclDict)      = PNML.usersorts(ddict)[refid(sortref)]
to_sort(sortref::NamedSortRef; ddict::DeclDict)     = PNML.namedsorts(ddict)[refid(sortref)]
to_sort(sortref::ProductSortRef; ddict::DeclDict)   = PNML.productsorts(ddict)[refid(sortref)]
to_sort(sortref::PartitionSortRef; ddict::DeclDict) = PNML.partition(ddict)[refid(sortref)]
to_sort(sortref::MultisetSortRef; ddict::DeclDict)  = PNML.multisetsorts(ddict)[refid(sortref)]
to_sort(sortref::ArbitrarySortRef; ddict::DeclDict) = PNML.arbitrarysorts(ddict)[refid(sortref)]

#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort>

function parse_sort(::Val{:productsort}, node::XMLNode, pntd::PnmlType, id, name; parse_context::ParseContext)
    check_nodename(node, "productsort")
    #println("\nparse_sort :productsort} $(repr(id)), $(repr(name))") #! debug
    sorts = REFID[] # Orderded collection of zero or more Sorts
    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        s = parse_sort(Val(tag), child, pntd, id, name; parse_context)::SortRef #! debug
        push!(sorts, PNML.refid(s)) # requires there to be a REFID #! use SortRef?
    end
    isempty(sorts) && throw(PNML.MalformedException("<productsort> contains no sorts"))

    @show ps = ProductSort(tuple(sorts...), parse_context.ddict) #! debug
    return make_sortref(parse_context, PNML.productsorts, ps, "product", id, name)::ProductSortRef
end



#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_partition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) #! partition is a sort declaration!
    partid = register_idof!(parse_context.idregistry, node)
    nameval = attribute(node, "name")
    #@warn "partition $(repr(id)) $nameval"; flush(stdout);  #! debug
    psort::Maybe{NamedSortRef} = nothing
    elements = PartitionElement[] # References into psort that form a equivalance class.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # The sort that partitionelements reference into.
            #! RelaxNG Schema says: "defined over a NamedSort which it refers to."
            # The only non-partitionelement child possible,
            psort = parse_usersort(child, pntd; parse_context)::NamedSortRef #? sortof isa EnumerationSort
        elseif tag === "partitionelement" # Each holds REFIDs to sort elements of the enumeration.
            parse_partitionelement!(elements, child, partid; parse_context) # pass REFID to partition
        else
            throw(PNML.MalformedException(string("partition child element unknown: ", tag,
                                " allowed are usersort, partitionelement")))
        end
    end
    isnothing(psort) &&
        throw(ArgumentError("<partition id=$partid, name=$nameval> <usersort> element missing"))

    # One or more partitionelements.
    isempty(elements) &&
        error("partitions must have at least one partition element, found none: ",
                "id = ", repr(partid), ", name = ", repr(nameval), ", sort = ", repr(psort))

    #~verify_partition(sort, elements)
    ps = PNML.PartitionSort(partid, nameval, refid(psort), elements, parse_context.ddict) # A Declaraion named Sort!
    return make_sortref(parse_context, PNML.partitionsorts, ps, "partition", partid, nameval)::PartitionSortRef
end

"""
    parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode; ddict)

Parse `<partitionelement>`, add FEConstant refids to the element and append element to the vector.
"""
function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode, rid::REFID; parse_context::ParseContext)
    check_nodename(node, "partitionelement")
    peid = register_idof!(parse_context.idregistry, node)
    nameval = attribute(node, "name")
    terms = REFID[] # Ordered collection, usually feconstant.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag === "useroperator"
            # PartitionElements refer to the FEConstants of the referenced enumeration sort.
            # UserOperator here holds an REFID to a FEConstant callable object.
            declid = Symbol(attribute(child, "declaration"))
            PNML.has_feconstant(parse_context.ddict, declid) ||
                error("declid $declid not found in feconstants") #! move to verify?
            push!(terms, declid)
        else
            # Are ProductSorts allowed?
            throw(PNML.MalformedException("partitionelement child element unknown: $tag"))
        end
    end
    isempty(terms) && throw(ArgumentError("<partitionelement id=$peid, name=$nameval> has no terms"))

    push!(elements, PartitionElement(peid, nameval, terms, rid, parse_context.ddict)) # rid is REFID to enclosing partition
    return elements
end

############################################################
