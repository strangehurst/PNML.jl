#=
There are many attribute-label elements.
The common usage is that 'label' usually be read as annotation-label.

Attribute-labels do not have associated graphics elements. Since <graphics> are
optional for annotation-labels they share the same implementation.

Unknown tags get parsed by `xmldict`.
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
    D()&& println("## parse_declaration! $(length(nodes)) <declaration> node(s)")

    text = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}}  = nothing
    for node in nodes
        check_nodename(node, "declaration")
        for child in EzXML.eachelement(node)
            tag = EzXML.nodename(child)
            if tag == "structure" # accumulate '<declarations>'
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
    D()&& println("Declaration '$text'")
    D()&& println(ctx.ddict)
    Declaration(; text, ctx.ddict, graphics, toolspecinfos)
end

"""
    fill_decl_dict!(ctx::ParseContext, node::XMLNode, pntd::PnmlType) -> ParseContext

Add a `<declaration><structure><declarations>` to ParseContext.
`<declaration>` may be attached to `<net>` and `<page>` elements.
Are network-level values even if attached to pages.
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
        if tag == "namedsort"
            ns = parse_namedsort(child, pntd; parse_context=ctx)::SortDeclaration
            PNML.namedsorts(ctx.ddict)[pid(ns)] = ns # fill_decl_dict! namedsort
        elseif tag == "namedoperator"
            no = parse_namedoperator(child, pntd; parse_context=ctx) #::NamedOperator
            PNML.namedoperators(ctx.ddict)[pid(no)] = no # fill_decl_dict! namedoperator
        elseif tag == "variabledecl"
            vardecl = parse_variabledecl(child, pntd; parse_context=ctx)
            PNML.variabledecls(ctx.ddict)[pid(vardecl)] = vardecl # fill_decl_dict! variabledecl
        elseif tag == "partition"
            # NB: partiton is a declaration of a new sort refering to the partitioned sort.
            part = parse_partition(child, pntd; parse_context=ctx)::AbstractSortRef
            @assert isa_variant(part, PartitionSortRef)

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
    # Will have created namedsort for builtin sorts.
    # Replacement of those, in particular, :dot, will trigger a duplicate id error
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

    D()&& println("## parse_namedsort $sortid $name")
    # Sort can be built-in, multiset, product.
    def = parse_sort(EzXML.firstelement(node), pntd, sortid, name; parse_context)::AbstractSortRef
    isnothing(def) &&
        error("failed to parse sort definition for namedsort $(repr(sortid)) $name")

    #? check for loops?
    # convert SortRef to concrete sort object.
    sort = to_sort(def; ddict)
    if isa(sort, NamedSort)
        sort = sortdefinition(sort)
    end
    NamedSort(sortid, name, sort, ddict) #^ Concrete sort object.

    # AbstractSortRef concrete type holds REFID and implicit dictionary of `DeclDict`.
    # Examples: `arbitrarysorts`, 'partitionsorts`, `productsorts`, `multisetsorts`.
    # Symmetric nets use `EnumerationSort`s.
    # `PartitionSort` uses a namedsort to identify the `EnumerationSort`
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
    D()&& println("parse_namedoperator $(repr(nopid)) $(repr(name))") #! debug

    #^ ePNK uses inline variabledecl, variable in namedoperator declaration
    #! Must register id of variabledecl before seeing variable: `<parameter>` before `<def>`.
    parameters = VariableDeclaration[]
    pnode = firstchild(node, "parameter")
    if !isnothing(pnode)
        # Zero or more parameters for operator (arity). Map from id to sort object.
        for vdeclnode in EzXML.eachelement(pnode)
            vardecl = parse_variabledecl(vdeclnode, pntd; parse_context)
            PNML.variabledecls(parse_context.ddict)[pid(vardecl)] = vardecl # parse_namedoperator
            push!(parameters, vardecl)
        end
    end
    D()&& @show parameters #! debug, empty vector allowed

    def = nothing
    dnode = firstchild(node, "def")
    # NamedOperators have a def element that is a  term/expression of existing
    # operators &/or variable parameters that define the operation.
    # The sortof the operator is the output sort of def.
    if !isnothing(dnode)
        # contains 1 term
        def = parse_term(EzXML.firstelement(dnode), pntd; parse_context, vars=())::TermJunk
    else
        error("<namedoperator name=$(repr(name)) id=$(repr(nopid))> does not have a <def> element")
    end

    isempty(def.vars) ||
        @error("<namedoperator name=$(repr(name)) id=$(repr(nopid))> has variables: ",  def)

    NamedOperator(nopid, name, parameters, def.exp, parse_context.ddict)
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
    D()&& println("## parse_variabledecl $(repr(varid)) $(repr(name))") #! debug

    # firstelement throws on nothing. Ignore more than 1.
    vsortref = parse_sort(EzXML.firstelement(node), pntd, varid, name; parse_context)::AbstractSortRef
    isnothing(vsortref) &&
        error("failed to parse sort definition for variabledecl $(repr(varid)) $name")
    # There is a namedsort created for every built-in sort, #todo multisetsorts, productsorts
    VariableDeclaration(varid, name, vsortref, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unknowndecl(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) #? just a label?
    nn = EzXML.nodename(node)
    unkid = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    unkncontent = anyelement(unkid, node)
    #!unkncontent = [anyelement(x) for x in EzXML.eachelement(node) if x !== nothing]
    @warn("parse unknown declaration: tag = $nn, id = $unkid, name = $name", unkncontent)
    return UnknownDeclaration(unkid, name, nn, unkncontent, parse_context.ddict)
end

"""
    parse_feconstants(::XMLNode, ::PnmlType, ::REFID; ddict) -> Tuple{<:AbstractSortRef}

Place the constants into feconstants(ddict).
Return tuple of finite enumeration constant REFIDs.

Access as 0-ary operator indexed by REFID
"""
function parse_feconstants(node::XMLNode, pntd::PnmlType, sortref::AbstractSortRef; parse_context::ParseContext)
    sorttag = EzXML.nodename(node)
    @assert sorttag in ("finiteenumeration", "cyclicenumeration") #? partition also?
    EzXML.haselement(node) || error("$sorttag has no child element")

    fec_refids = Symbol[]
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag != "feconstant"
            throw(PNML.MalformedException("$sorttag has unexpected child element $tag"))
        else
            fecid = register_idof!(parse_context.idregistry, child)
            name = attribute(child, "name")
            PNML.feconstants(parse_context.ddict)[fecid] =
                PNML.FEConstant(fecid, name, sortref,  parse_context.ddict) #= sortref =#
            push!(fec_refids, fecid)
        end
    end
    return fec_refids #todo NTuple?
end

"""
$(TYPEDSIGNATURES)

Returns concrete [`AbstractSortRef`](@ref) wraping the REFID of a
[`NamedSort`](@ref), [`ArbitrarySort`](@ref). or [`PartitionSort`](@ref).
"""
function parse_usersort(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "usersort")
    declid = Symbol(attribute(node, "declaration"))

    # <usersort> holds a reference to a declaration: named, partition, arbitrary.
    # We extract that information and encode it in the SortRef ADT.
    if PNML.has_namedsort(parse_context.ddict, declid)
        NamedSortRef(declid)
    elseif PNML.has_partitionsort(parse_context.ddict, declid)
        PartitionSortRef(declid)
    elseif PNML.has_arbitrarysort(parse_context.ddict, declid)
        ArbitrarySortRef(declid)
    else
        error("Did not find sort declaration for $(repr(declid)) in $(repr(parse_context.ddict))")
    end
end

"""
$(TYPEDSIGNATURES)

Returns concrete [`AbstractSortRef`](@ref) wraping the REFID of a [`ArbitrarySort`](@ref).
"""
function parse_arbitrarysort(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "arbitrarysort")
    arbid = register_idof!(parse_context.idregistry, node)
    name = attribute(node, "name")
    @warn("parse unparse_arbitrarysort: id = $arbid, name = $name")
    return ArbitrarySort(arbid, name, parse_context.ddict)
end

#=
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
function parse_sort(node::XMLNode, pntd::PnmlType, sortid::Maybe{REFID}=nothing,  name::String=""; parse_context::ParseContext)
    # Note: Sorts are NOT PNML labels. Will NOT have <text>, <graphics>, <toolspecific>.
    sorttag = Symbol(EzXML.nodename(node))
    # !isnothing(sortid) || !isempty(name) &&
    D()&& println("## parse_sort $sorttag id=$sortid name=$name tag=$(repr(sorttag))") #! debug
    return parse_sort(Val(sorttag), node, pntd, sortid, name; parse_context)::AbstractSortRef
end

# Built-ins sorts
# ! 2025-07-21 AbstractSortRef refactor, make these return a direct NamedSortRef.
#! The insertion into decldict in done in `fill_sort_tag!` from `fill_nonhl!`
#! as initial part of `PnmlNet` parsing.
#! Followed by parsing all declarations where `parse_sort is used`.
#! Then the net where terms use sorts.

function parse_sort(::Val{:bool}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext)
    NamedSortRef(:bool)
end

function parse_sort(::Val{:integer}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext)
    NamedSortRef(:integer)
end

function parse_sort(::Val{:natural}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext)
    NamedSortRef(:natural)
end

function parse_sort(::Val{:positive}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext)
    NamedSortRef(:positive)
end

function parse_sort(::Val{:real}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext)
    NamedSortRef(:real)
end

# In the ISO 15909 standard <usersort> wraps a REFID to a
# NamedSort , ArbitrarySort, or PartitionSort declaration.
#
# We use `NamedSort` declarations to instantiate built-in sorts. The user assumes they
# have the expected and obvious REFID/name duo.

# NB: ePNK examples uses some inlined sorts

function parse_sort(::Val{:dot}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext)
    NamedSortRef(:dot) # The user overrides in a declaration.
end

function parse_sort(::Val{:usersort}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext) #! see parse_namedsort
    parse_usersort(node, pntd; parse_context) #check_nodename(node, "usersort")
end


#!##########################################################and AbstractSortRef#
#! XXX TODO Sorts that are not singletons. Must be wrapped in a NamedSort or Partition.
#! XXX Invent id/name duo to wrap anonymous inline sorts.
# Any REFID in the input XML must take precedence.
# ? Can multiple REFIDs refer to the same sort? Yes, ISO 15909 says id/name are optional.
# Sorts are expected to be comapproductsort\(arable for equality, that is what matters,
# and specificially inline sorts are allowed and expected in some places.
# Assume parsing is a smallish up-front cost; enabling & firing rules is the big work.
# It is more important (for the big work) to be cache-friendly.
#
#? When is the REFID of a sort meaninful?
#  - Index into DeclDict to access concrete sort object
#       2 or more concrete sort objects (2 entries in dictionary) may be `equalSorts`
#  -



# is a finiteenumeration with additional operators: successor, predecessor
function parse_sort(::Val{:cyclicenumeration}, node::XMLNode, pntd::PnmlType, parentid, name; parse_context::ParseContext)
    check_nodename(node, "cyclicenumeration")
    #D()&& println("cyclicenumeration $(repr(parentid)), $(repr(name))") #! debug
    fecs = parse_feconstants(node, pntd, NamedSortRef(parentid); parse_context) # pared
    ces = CyclicEnumerationSort(fecs, parse_context.ddict)
    sref = make_sortref(parse_context, PNML.namedsorts, ces, "cyclicenumeration", parentid, name)
    return sref
end

function parse_sort(::Val{:finiteenumeration}, node::XMLNode, pntd::PnmlType, parentid, name; parse_context::ParseContext)
    check_nodename(node, "finiteenumeration")
    #D()&& println("finiteenumeration $(repr(parentid)), $(repr(name))") #! debug
    fecs = parse_feconstants(node, pntd, NamedSortRef(parentid); parse_context)
    fes = FiniteEnumerationSort(fecs, parse_context.ddict)
    sref = make_sortref(parse_context, PNML.namedsorts, fes, "finiteenumeration", parentid, name)
    return sref
end

function parse_sort(::Val{:finiteintrange}, node::XMLNode, pntd::PnmlType, parentid, name; parse_context::ParseContext)
    check_nodename(node, "finiteintrange")

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
        # Did not find namedsort, will instantiate named,user duo for one. See fill_nonhl!
        sort = FiniteIntRangeSort(startval, stopval, parse_context.ddict)
        sref = make_sortref(parse_context, PNML.namedsorts, sort, "finiteintrange", sorttag, name)
        #D()&& @show sref
        @assert isa_variant(sref, NamedSortRef)
        return sref
    end
end

#   <namedsort id="id2" name="MESSAGE">
#     <productsort>
#       <usersort declaration="id1"/>
#       <natural/>
#     </productsort>
#   </namedsort>

#TODO inline sort like FiniteIntRangeSort, but <tuple> may use non-ground terms to deduce.
#TODO tuples may be nested.
#TODO <tuple> is operator, subterms are expressions (terms) that have sortrefs.
function parse_sort(::Val{:productsort}, node::XMLNode, pntd::PnmlType, sortid, name; parse_context::ParseContext)
    check_nodename(node, "productsort")

    isnothing(sortid) && error("parse_sort(::Val{:productsort} sortid is $(repr(sortid))") #! debug

    sorts = [] # Orderded collection of zero or more Sorts in ISO 15909 Standard.
    for child in EzXML.eachelement(node)
        tag = Symbol(EzXML.nodename(child))
        asr = parse_sort(Val(tag), child, pntd, nothing, ""; parse_context)::AbstractSortRef
        push!(sorts, asr)
    end
    isempty(sorts) &&
        @warn "ISO 15909 Standard allows a <productsort> to be empty. And somebody did!"
    # What is the use of an empty productsort? bottom?

    prodsort = ProductSort(tuple(sorts...), parse_context.ddict)

    # See if there exists a matching sort. #! debug?
    for (id,ps) in pairs(productsorts(parse_context.ddict))
        if PNML.Sorts.equalSorts(ps, prodsort)
            @info "Found product sort $id while looking for $prodsort for sortid=$sortid name=$name" productsorts(parse_context.ddict)
         end
    end


    fill_sort_tag!(parse_context, sortid, prodsort) # add to productsorts without a sortref
    return make_sortref(parse_context, namedsorts, prodsort, "product", sortid, name)
end


function parse_sort(::Val{:list}, node::XMLNode, pntd::PnmlType, sortid, u2; parse_context::ParseContext)
    @error("IMPLEMENT ME: :list")
    #make_sort!(dict, :list, "List",
    ListSort(parse_context.ddict)
end

function parse_sort(::Val{:string}, node::XMLNode, pntd::PnmlType, parentid, name; parse_context::ParseContext)
    ss = StringSort(parse_context.ddict)
    sref = make_sortref(parse_context, PNML.namedsorts, ss, "string", parentid, name)
    return sref
end

function parse_sort(::Val{:multisetsort}, node::XMLNode, pntd::PnmlType, sortid, name; parse_context::ParseContext)
    check_nodename(node, "multisetsort")
    EzXML.haselement(node) || throw(ArgumentError("multisetsort missing basis sort"))

    # Expect basis to be a <usersort> wrapping <namedsort> for symmetricnet,
    # but not <partition> or <partitionelement>. Definitely not another multiset.
    # NB: We wrap built-in sorts in a user/named duo.
    #^ ePNK highlevelnet inlines product sort inside a place `<type><structure><multisetsort>`
    # maybe someday <arbitrary## parse_sort multisetsort id=nothing name= tag=:multisetsortsort>

    basisnode = EzXML.firstelement(node) # Assume basis sort will be first and only child.
    tag = Symbol(EzXML.nodename(basisnode))

    tag in (:partition, :partitionelement, :multisetsort) &&
        throw(ArgumentError("multisetsort basis $tag not allowed")) #todo test this!
    basissort = parse_sort(Val(tag), basisnode, pntd, nothing, ""; parse_context)::AbstractSortRef # of multisetsort
    @assert isa_variant(basissort, NamedSortRef)
    #D()&& @warn "parse_sort(::Val{:multisetsort}" basissort sortdefinition(to_sort(basissort; parse_context.ddict))
    #!isnothing(sortid) && @error "inlined multiset" parse_context.ddict
    ms = MultisetSort(basissort, parse_context.ddict)
    return make_sortref(parse_context, PNML.multisetsorts, ms, "multiset", sortid, name)
end

"""
    to_sort(sortref::AbstractSortRef; ddict::DeclDict) -> AbstractSort

Return concrete sort from `ddict` using the `REFID` in `sortref`,
"""
function to_sort(sr::AbstractSortRef; ddict::DeclDict)
    #@show sr
    is_data_type(sr) || error("!isdata_type($sr)")
    # NamedSort, PatritionSort, ArbitrarySort are declarations
    isa_variant(sr, SortRef.NamedSortRef) && return PNML.namedsort(ddict, refid(sr)) # todo unwrap namedsort
    isa_variant(sr, SortRef.ProductSortRef) && return PNML.productsort(ddict, refid(sr)) #! named sort
    isa_variant(sr, SortRef.MultisetSortRef) && return PNML.multisetsort(ddict, refid(sr)) #! named sort
    isa_variant(sr, SortRef.PartitionSortRef) && return PNML.partition(ddict, refid(sr))
    isa_variant(sr, SortRef.ArbitrarySortRef) && return PNML.arbitrarysort(ddict, refid(sr))
    error("not isa_variant $(repr(sr))")

    # s = @match sr begin
    #     # NamedSort, PatritionSort, ArbitrarySort are declarations
    #     SortRef.NamedSortRef(refid)     => PNML.namedsort(ddict, refid) # todo unwrap namedsort
    #     SortRef.ProductSortRef(refid)   => PNML.productsort(ddict, refid) #! named sort
    #     SortRef.MultisetSortRef(refid)  => PNML.multisetsort(ddict, refid) #! named sort
    #     SortRef.PartitionSortRef(refid) => PNML.partition(ddict, refid)
    #     SortRef.ArbitrarySortRef(refid) => PNML.arbitrarysort(ddict, refid)
    #     _ => error("to_sort SortRef not expected: $sr")
    # end
    return s
end
to_sort(s::AbstractSort; ddict::DeclDict) = s

#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_partition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) #! a sort declaration!
    partid = register_idof!(parse_context.idregistry, node)
    nameval = attribute(node, "name")
    D()&& println("## parse_partition $(repr(partid)) $nameval")
    partitioned_sortref::Maybe{AbstractSortRef} = nothing
    elements = PartitionElement[] # References into partitioned_sortref that form a equivalance class.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # The sort that partitionelements reference into.
            # The only non-partitionelement child possible,
            partitioned_sortref = parse_usersort(child, pntd; parse_context)::AbstractSortRef
            #! RelaxNG Schema says: "defined over a NamedSort which it refers to."
            @assert isa_variant(partitioned_sortref, NamedSortRef)
        elseif tag === "partitionelement" # Each holds REFIDs to sort elements of the enumeration.
            parse_partitionelement!(elements, child, partid; parse_context) # pass REFID to partition
        else
            throw(PNML.MalformedException(string("partition child element unknown: ", tag,
                                " allowed are usersort, partitionelement")))
        end
    end
    isnothing(partitioned_sortref) &&
        throw(ArgumentError("<partition id=$partid, name=$nameval> <usersort> element missing"))

    # One or more partitionelements.
    isempty(elements) &&
        error("partitions must have at least one partition element, found none: ",
                "id = ", repr(partid),
                ", name = ", repr(nameval),
                ", sort = ", repr(partitioned_sortref))

    #~verify_partition(sort, elements)
    partsort = PNML.PartitionSort(partid, nameval, partitioned_sortref, elements, parse_context.ddict) # A Declaraion named Sort!

    # add to productsorts
    fill_sort_tag!(parse_context, partid, partsort)
    @assert partitionsorts(parse_context.ddict)[partid] == partsort
    # make a user/named sort duo
    namedsorts(parse_context.ddict)[partid] = NamedSort(partid, string(partid), partsort, parse_context.ddict)
    return make_sortref(parse_context, PNML.partitionsorts, partsort, "partition", partid, "")
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
