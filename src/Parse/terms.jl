"""
    pnml_hl_operators(tag::Symbol) -> Callable(::Vector{AbstractTerm})

Map an operator tag to a method with one argument.
"""
function pnml_hl_operators(tag::Symbol)
    #haskey(hl_operators, tag) || throw(ArgumentError("term $tag is not a known operator"))
    #error("pnml_hl_operators not implemented")
    # Return anonymous function with a single argument.
    if tag === :or
        return v -> boolean_or(v)
    elseif tag === :and
        return v -> boolean_and(v)
    elseif tag === :equality
        return v -> boolean_equality(v)
    else
        return v -> null_function(v)
        #return v::Vector{AbstractTerm} -> null_function(v)
    end
end

"Dummy function"
function null_function(inputs)#::Vector{AbstractTerm})
    println("NULL_FUNCTION: ", inputs)
end

function boolean_or(inputs)#::Vector{AbstractTerm})
    println("boolean_or: ", inputs)
    return false #! Lie until we know how! XXX
end
function boolean_and(inputs)#::Vector{AbstractTerm})
    println("boolean_and: ", inputs)
    return false #! Lie until we know how! XXX
end

function boolean_equality(inputs)#::Vector{AbstractTerm})
    println("boolean_equality: ", inputs)
    return false #! Lie until we know how! XXX
end


"""
$(TYPEDSIGNATURES)

There will be no XML node <term>. Instead it is the interpertation of the child of some
<structure>, <subterm> or <def> elements. The Relax NG Schema does contain "Term".
Terms kinds are Variable and Operator.

There _IS_ the `TermInterface` from Symbolics.jl, et al.
Yes, we will be using it as soon as we figure things out.

All terms have a sort, #TODO
"""
function parse_term(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    tag = Symbol(EzXML.nodename(node))
    # See `TermInterface.jl`, `Metatheory.jl`
    if tag in  [:variable, # 0 arity? Or trivial to reduce to such? # TODO more?
                :booleanconstant,
                :numberconstant,
                :dotconstant,
                :all,
                # :numberof,
                # :feconstant,
                # :unparsed,
                :useroperator,
                :finiteintrangeconstant]
        # These must follow the Operator interface. See operators.jl.
        return parse_term(Val(tag), node, pntd, reg; ids) # (AbstractOperator, Sort)

    else # arity > 0, build & return an Operator Functor
        return parse_term(tag, node, pntd, reg; ids) # (AbstractOperator, Sort)
    end
end

#=
    Build an Operator Functor
=#
function parse_term(tag::Symbol, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    println("parse_term: $tag")
    @assert isoperator(tag)
    interms = Union{AbstractVariable, AbstractOperator}[] # todo tuple?
    insorts = AbstractSort[]
    func = pnml_hl_operators(tag) #TODO

    for child in EzXML.eachelement(node)
        check_nodename(child, "subterm")
        subterm = EzXML.firstelement(child)
        (t, s) = parse_term(subterm, pntd, reg; ids) # extract & accumulate input
        push!(interms, t)
        push!(insorts, s) #~ sort may be inferred from place, variable, operator output
    end
    @assert length(interms) == length(insorts)

    outsort = IntegerSort() #!error("XXX IMPLEMENT ME XXX") should be sortof(func)
    return (Operator(tag, func, interms, insorts, outsort), outsort)
end
#----------------------------------------------------------------------------------------
# Expect only an attribute referencing the declaration.
function parse_term(::Val{:variable}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    var = Variable(Symbol(attribute(node, "refvariable", "<variable> missing refvariable. trail = $ids")), ids)
    return (var, sortof(var)) #! does DeclDict lookup
end
# Has value "true"|"false" and is BoolSort.
function parse_term(::Val{:booleanconstant}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    bc = BooleanConstant(attribute(node, "value", "<booleanconstant> missing value. trail = $ids"))
    return (bc, sortof(bc))
end
# Has a value and is a subsort of NumberSort.
function parse_term(::Val{:numberconstant}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    value = attribute(node, "value", "term $tag missing value")::String
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(MalformedException("<numberconstant> missing sort element. trail = $ids"))
    sorttag = EzXML.nodename(child)
    if sorttag == "integer"
        sort = IntegerSort()
    elseif sorttag == "natural"
        sort = NaturalSort()
    elseif sorttag == "positive"
        sort = PositiveSort()
    elseif sorttag == "real" # Schema says integer, natural, positive. We allow real.
        sort = RealSort()
    else
        throw(MalformedException("$tag sort unknown: $sorttag"))
    end
    @assert sort isa NumberSort
    nc = NumberConstant(number_value(eltype(sort), value), sort)
    return (nc, sort)
end
# Does not have a value and is DotSort.
function parse_term(::Val{:dotconstant}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    return (DotConstant(), DotSort())
end

# Return multiset that contains exactly one element of its basis sort.
# This is often called the broadcast function.
# <structure>
#     <tuple>
#         <subterm><all><usersort declaration="N1"/></all></subterm>
#         <subterm><all><usersort declaration="N2"/></all></subterm>
#     </tuple>
# </structure>
function parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(MalformedException("$tag missing content element. trail = $ids"))
    @show basis = parse_usersort(child, pntd, reg; ids)::UserSort # Can there be anything else?
    ms = Multiset()
    @assert isempty(ms)
    #~ @show ms
    return (PnmlMultiset(1,basis), sortof(basis)) #todo what is sort of a usersort
 end

# Return multiset containing multiplicity of elements of its basis sort.
# <text>3`dot</text>
# <structure>
#     <numberof>
#         <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
#         <subterm><dotconstant/></subterm>
#     </numberof>
# </structure>
function parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    @info "parse_term(::Val{:numberof}"
    tag == :numberconstant

    tag == :dotconstant
end

function parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    @info "parse_term(::Val{:feconstant}"
end

function parse_term(::Val{:unparsed}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    @info "parse_term(::Val{:unparsed}"
end

# <structure>
#   <useroperator declaration="id4"/>
# </structure>
function parse_term(::Val{:useroperator}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    uo = UserOperator(attribute(node, "declaration", "<useroperator> missing declaration"), ids)
    # Sort of UserOperator is the sort of the NamedOperator referenced. #! XXX FIX ME XXX
    dd = decldict(first(ids)) # Declarations are at net/page level.
    # Assume to have been parsed before any reference by Variable, UserOperatore, UserSort?
    return (uo, NullSort()) #! XXX FIX ME
end

function parse_term(::Val{:finiteintrangeconstant}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
    valuestr = attribute(node, "value", "<finiteintrangeconstant> missing value. trail = $ids")::String
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

        sort = FiniteIntRangeSort(startval, stopval; ids) #! de-duplicate

        value = tryparse(Int, valuestr)
        isnothing(value) &&
            throw(ArgumentError("value '$valuestr' failed to parse as `Int`"))

        value in start(sort):stop(sort) || throw(ArgumentError("$value not in range $(start(sort)):$(stop(sort))"))
        return (FiniteIntRangeConstant(value, sort), sort)
    end
    throw(MalformedException("<finiteintrangeconstant> <finiteintrange> sort expected, found $sorttag"))
end

# function parse_term(::Val{:}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
# end

# function parse_term(::Val{:}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
# end

# function parse_term(::Val{:}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
# end

# function parse_term(::Val{:}, node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry; ids::Tuple)
# end



#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_term(::Val{:partition}, node::XMLNode, pntd::PnmlType, reg::PIDR; ids::Tuple)
    id = register_idof!(reg, node)
    ids = tuple(ids..., id)
    nameval = attribute(node, "name","<partition id=$id missing name attribute. trail = $ids")
    sort::Maybe{UserSort} = nothing
    elements = PartitionElement[] # References into sort that form a equivalance class.
    PartitionSort
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # This is the sort that partitionelements reference.
            sort = parse_usersort(child, pntd, reg; ids)::UserSort #~ ArbitrarySort?
        elseif tag === "partitionelement"
            # Need to go up the tree so a element can access its parent partition.
            # last(ids) == pid(PartitionWeAreCreating)
            parse_partitionelement!(elements, child, reg; ids)
        else
            throw(MalformedException("partition child element unknown: $tag. trail = $ids"))
        end
    end
    isnothing(sort) && throw(ArgumentError("<partition id=$id, name=$nameval> <usersort> element is missing. trail = $ids"))

    # One or more partitionelements.
    isempty(elements) &&
        throw(string("partitions must have at least one partition element, found none: ",
                "id = ", repr(id), ", name = ", repr(nameval), ", sort = ", repr(sort)), " trail = $ids")

    #TODO verify_partition(sort, elements; ids)

    return PartitionSort(id, nameval, sort, elements; ids)
end

function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode, reg::PIDR; ids::Tuple)
    check_nodename(node, "partitionelement")
    id = register_idof!(reg, node)
    partid = last(ids) # The Parent of a element is the partition.
    ids = tuple(ids..., id) # The element is now the last id in the trail.
    nameval = attribute(node, "name", "partitionelement $id missing name attribute. trail = $ids")
    terms = AbstractTerm[] # ordered collection, usually useroperators (as constants)
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag === "useroperator"
            decl = attribute(child, "declaration", "<useroperator id=$id name=name> missing declaration. trail = $ids")::String
            push!(terms, UserOperator(decl, ids)) # decl is a reference into enclosing partition's sort
        else
            throw(MalformedException("partitionelement child element unknown: $tag. trail = $ids"))
        end
    end
    isempty(terms) && throw(ArgumentError("<partitionelement id=$id, name=$nameval> has no terms. trail = $ids"))

    push!(elements, PartitionElement(id, nameval, terms; ids))
    return nothing
end
