

"""
$(TYPEDSIGNATURES)

There will be no XML node <term>. Instead it is the interpertation of the child of some
<structure>, <subterm> or <def> elements. The Relax NG Schema does contain "Term".
Terms kinds are Variable and Operator.

There _IS_ the `TermInterface` from Symbolics.jl, et al.
Yes, we will be using it as soon as we figure things out.

All terms have a sort, #TODO
"""
function parse_term(node::XMLNode, pntd::PnmlType)
    tag = Symbol(EzXML.nodename(node))
    # See `TermInterface.jl`, `Metatheory.jl`
    if tag in  [:variable, # 0 arity? Or trivial to reduce to such? # TODO more?
                :booleanconstant,
                :numberconstant,
                :dotconstant,
                :all,
                :numberof,
                # :feconstant,
                # :unparsed,
                :useroperator,
                :finiteintrangeconstant]
        # These must follow the Operator interface. See operators.jl.
        #
        #~ printstyled("parse_term"; color=:green);  println(": $(repr(tag))")
        (term,sort) = parse_term(Val(tag), node, pntd) # (AbstractTerm, Sort)
        return (term, sort)

    else # arity > 0, build & return an Operator Functor that has a vector of inputs.
        (term,sort) = parse_operator_term(tag, node, pntd) # (AbstractOperator, Sort)
        return (term, sort)
    end
end

"""
$(TYPEDSIGNATURES)

Build an Operator Functor.

"""
function parse_operator_term(tag::Symbol, node::XMLNode, pntd::PnmlType)
    #~ printstyled("parse_operator_term"; color=:green);
    #~ println(": $(repr(tag)))
    isoperator(tag) || @error "tag $tag is not an operator"

    func = pnml_hl_operator(tag) #TODO  built-in operators, other operators

    interms = Union{AbstractVariable, AbstractOperator}[] # todo tuple?
    insorts = AbstractSort[]

    # Extract the input term and sort from each <subterm>
    for child in EzXML.eachelement(node)
        check_nodename(child, "subterm")
        subterm = EzXML.firstelement(child)
        (t, s) = parse_term(subterm, pntd) # extract & accumulate input
        push!(interms, t)
        push!(insorts, s) #~ sort may be inferred from place, variable, operator output
    end
    @assert length(interms) == length(insorts)
    # for (t,s) in zip(interms,insorts) # Lots of output. Leave this here for debug, bring-up
    #     @show t s
    #     println()
    # end
    #^ Is last(ids) different for partition, partition element, FEC, EnumSort
    outsort = pnml_hl_outsort(tag; insorts) #! some sorts need content

    #~ println("parse_operator_term returning $(repr(tag)) $(func)")
    #~ println("   interms ", interms)
    #~ println("   insorts ", insorts)
    #~ println("   outsort ", outsort)
    #~ println()
    return (Operator(tag, func, interms, insorts, outsort), outsort)
end

#----------------------------------------------------------------------------------------
# Expect only an attribute referencing the declaration.
function parse_term(::Val{:variable}, node::XMLNode, pntd::PnmlType)
    var = Variable(Symbol(attribute(node, "refvariable", "<variable> missing refvariable")))
    return (var, sortof(var)) #! does DeclDict lookup
end

# Has value "true"|"false" and is BoolSort.
function parse_term(::Val{:booleanconstant}, node::XMLNode, pntd::PnmlType)
    bc = BooleanConstant(attribute(node, "value", "<booleanconstant> missing value"))
    return (bc, sortof(bc))
end

# Has a value and is a subsort of NumberSort.
function parse_term(::Val{:numberconstant}, node::XMLNode, pntd::PnmlType)
    value = attribute(node, "value", "term $tag missing value")::String
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(MalformedException("<numberconstant> missing sort element"))
    sorttag = Symbol(EzXML.nodename(child))
    if sorttag in (:integer, :natural, :positive, :real) #  We allow non-standard real.
        sort = parse_sort(Val(sorttag), child, pntd)
    else
        throw(MalformedException("$tag sort unknown: $sorttag"))
    end
    @assert sort isa NumberSort
    nv = number_value(eltype(sort), value)
    if sort isa NaturalSort
        nv >= 0 || throw(ArgumentError("not a Natural Number: $nv"))
    elseif sort isa PositiveSort
        nv > 0 || throw(ArgumentError("not a Positive Number: $nv"))
    end
    # IntegerSort, RealSort do not need bounds checks.
    nc = NumberConstant(nv, sort)
    return (nc, sort)
end

# Does not have a value and is DotSort.
function parse_term(::Val{:dotconstant}, node::XMLNode, pntd::PnmlType)
    return (DotConstant(), DotSort())
end

# All returns multiset that contains exactly one of each element of its basis set/sort.
# <structure>
#     <tuple>
#         <subterm><all><usersort declaration="N1"/></all></subterm>
#         <subterm><all><usersort declaration="N2"/></all></subterm>
#     </tuple>
# </structure>
function parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType)
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(MalformedException("$tag missing content element"))

    us = parse_usersort(child, pntd)::UserSort # Can there be anything else?
    b = sortof(us) # IDREF -> sort instance
    e = sortelements(b) # iterator over an instance of every element of the set/sort

    #@show us b e typeof(e)
    # dot: dotconstant
    # bool: true, false #todo tuple of BooleanConstants
    # finite int range: start:1:stop
    # enumeration: sequence of objects

    M = Multiset(e) # also Multiset(Set(us)) to copy Multiset with multiplicity changed to 1
    all = PnmlMultiset(b, M)
    #@warn repr(M) # prints decldict
    #@warn typeof(M)
    #@warn repr(all) # M is a set, example {(DotConstant(),)}
    #println()

    # A multiset created from one object, a multiplicity, and the sort of the object.
    # Eventually the Metatheory rewrite engine, SymbolicUtils will expand the this.
    #~ What lie do we tell now?
    #
    # Here, <all> operator produces a multiset with multiplicity = 1 of all the elements of
    # a multiset identified by a usersort's IDREF to a sort declaration.
    #
    # NamedSort declaration gives a name (and ID) to built-in sorts (and multisets,
    # product sorts, partition sorts). Someday, ArbitrarySorts will also be supported.
    #
    # Think of _sort_ as a finite* set (example finite range of integers, enumeration) *SymmetricNet restriction
    # and/or datatype (as in `DataType`, the mechanism implementing the concept).
    return (all, b)
end

# Return multiset containing multiplicity of elements of its basis sort.
# <text>3`dot</text>
# <structure>
#     <numberof>
#         <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
#         <subterm><dotconstant/></subterm>
#     </numberof>
# </structure>

#multiset in which the element occurs exactly in the given number and no other elements in it.
# context NumberOf inv:
#   self.input->size() = 2 and
#   self.input->forAll{c, d | c.oclIsTypeOf(Integers::Natural) and d.oclIsKindOf(Terms::Sort)} and
#   self.output.oclIsKindOf(Terms::MultisetSort)

# c TypeOF sort of multiplicity
# d KindOf (instance of this sort)

function parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType)
    multiplicity = nothing
    instance = nothing
    #!multiplicity::Maybe{NumberConstant} = nothing
    #!instance::Maybe{AbstractTerm} = nothing
    for (i,subterm) in enumerate(EzXML.eachelement(node))
        check_nodename(subterm, "subterm")
        stnode = first(EzXML.elements(subterm))
        tag = Symbol(EzXML.nodename(stnode))
        if tag == :numberconstant && isnothing(multiplicity)
            (multiplicity, ncsort) = parse_term(Val(tag), stnode, pntd)
            # RealSort as first numberconstant might confuse `Multiset.jl`.
        else
            # If 2 numberconstants, first is `multiplicity`, this is `instance`.
            # A constant/0-arity operator returning a constant of sort, that, with `multiplicity`, forms a multiset.
            # Can be a n-ary operator, like tuple, or a variable.
            (instance, isort) = parse_term(stnode, pntd)
            #@show typeof(instance) instance sortof(instance) isort
            isa(instance, MultisetSort) && throw(ArgumentError("numberof's output sort cannot be MultisetSort"))
        end
    end
    isnothing(multiplicity) && throw(ArgumentError("Missing numberof numberconstant subterm"))
    isnothing(instance) && throw(ArgumentError("Missing numberof sort instance subterm. Expected `dotconstant` or similar."))
    #@show multiplicity multiplicity() instance sortof(instance)
    return (pnmlmultiset(instance, sortof(instance), multiplicity()), sortof(instance))
end

function parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType)
    @error "parse_term(::Val{:feconstant} not implemented"
end

function parse_term(::Val{:unparsed}, node::XMLNode, pntd::PnmlType)
    @error "parse_term(::Val{:unparsed} not implemented"
end

function parse_term(::Val{:tuple}, node::XMLNode, pntd::PnmlType)
    @error "parse_term(::Val{:tuple} not implemented"
end

# <structure>
#   <useroperator declaration="id4"/>
# </structure>
function parse_term(::Val{:useroperator}, node::XMLNode, pntd::PnmlType)
    uo = UserOperator(Symbol(attribute(node, "declaration", "<useroperator> missing declaration")))
    #@warn "returning $uo"
    return (uo, sortof(uo))
end

function parse_term(::Val{:finiteintrangeconstant}, node::XMLNode, pntd::PnmlType)
    valuestr = attribute(node, "value", "<finiteintrangeconstant> missing value")::String
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(MalformedException("<finiteintrangeconstant> missing sort element"))
    sorttag = Symbol(EzXML.nodename(child))
    if sorttag == :finiteintrange
        startstr = attribute(child, "start", "<finiteintrange> missing start")
        startval = tryparse(Int, startstr)
        isnothing(startval) &&
            throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`"))

        stopstr = attribute(child, "end", "<finiteintrange> missing end") # XML Schema uses 'end', we use 'stop'.
        stopval = tryparse(Int, stopstr)
        isnothing(stopval) &&
            throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`"))

        sort = FiniteIntRangeSort(startval, stopval) #! de-duplicate

        value = tryparse(Int, valuestr)
        isnothing(value) &&
            throw(ArgumentError("value '$valuestr' failed to parse as `Int`"))

        value in start(sort):stop(sort) || throw(ArgumentError("$value not in range $(start(sort)):$(stop(sort))"))
        return (FiniteIntRangeConstant(value, sort), sort)
    end
    throw(MalformedException("<finiteintrangeconstant> <finiteintrange> sort expected, found $sorttag"))
end

#====================================================================================#
#! partition is a sort!
#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_sort(::Val{:partition}, node::XMLNode, pntd::PnmlType)
    id = register_idof!(idregistry[], node)
    nameval = attribute(node, "name", "<partition id=$id missing name attribute")
    @warn "partition $(repr(id)) $nameval"
    sort::Maybe{UserSort} = nothing
    elements = PartitionElement[] # References into sort that form a equivalance class.
    # First harvest the sort,
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # This is the sort that partitionelements reference.
            sort = parse_usersort(child, pntd)::UserSort #~ ArbitrarySort?
            #! @show sort
        elseif tag === "partitionelement"
            # Need to go up the tree so a element can access its parent partition.
            # last(ids) == pid(PartitionWeAreCreating)
            parse_partitionelement!(elements, child)
        else
            throw(MalformedException(string("partition child element unknown: $tag, ",
                                "allowed are usersort, partitionelement")))
        end
    end
    isnothing(sort) &&
        throw(ArgumentError("<partition id=$id, name=$nameval> <usersort> element missing"))

    # One or more partitionelements.
    isempty(elements) &&
        error("partitions must have at least one partition element, found none: ",
                "id = ", repr(id), ", name = ", repr(nameval), ", sort = ", repr(sort))

    #~verify_partition(sort, elements)

    return PartitionSort(id, nameval, sort, elements)
end

function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode)
    check_nodename(node, "partitionelement")
    id = register_idof!(idregistry[], node)
    nameval = attribute(node, "name", "partitionelement $id missing name attribute")
    terms = AbstractTerm[] # ordered collection, usually useroperators (as constants)
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag === "useroperator"
            # decl is a reference into enclosing partition's sort
            decl = attribute(child, "declaration", "<useroperator id=$id name=name> missing declaration")::String
            refid = Symbol(decl)
            PNML.has_useroperator(PNML.DECLDICT[], refid) ||
                error("refid $refid not found in useroperators")
            push!(terms, UserOperator(refid))
        else
            throw(MalformedException("partitionelement child element unknown: $tag"))
        end
    end
    isempty(terms) && throw(ArgumentError("<partitionelement id=$id, name=$nameval> has no terms"))

    push!(elements, PartitionElement(id, nameval, terms))
    return nothing
end
