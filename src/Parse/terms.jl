"""
    pnml_hl_operators(tag::Symbol) -> Callable(::Vector{PnmlExpr})

Map an operator tag to a method with one argument.
"""
function pnml_hl_operators(tag::Symbol)
    #haskey(hl_operators, tag) || throw(ArgumentError("term $tag is not a known operator"))
    #error("pnml_hl_operators not implemented")
    # Return anonymous function with a single argument.
    if tag === :or
        return in::Vector{PnmlExpr} -> boolean_or(in)
    elseif tag === :and
        return in::Vector{PnmlExpr} -> boolean_and(in)
    elseif tag === :equality
        return in::Vector{PnmlExpr} -> boolean_equality(in)
    else
        return in::Vector{PnmlExpr} -> null_function(in)
    end
end

"Dummy function"
function null_function(inputs::Vector{PnmlExpr})
    println("NULL_FUNCTION: ", inputs)
end

function boolean_or(inputs::Vector{PnmlExpr})
    println("boolean_or: ", inputs)
    return false #! Lie until we know how! XXX
end
function boolean_and(inputs::Vector{PnmlExpr})
    println("boolean_and: ", inputs)
    return false #! Lie until we know how! XXX
end

function boolean_equality(inputs::Vector{PnmlExpr})
    println("boolean_equality: ", inputs)
    return false #! Lie until we know how! XXX
end


"""
$(TYPEDSIGNATURES)

There will be no XML node <term>. Instead it is the interpertation of the child of some
<structure>, <subterm> or <def> elements. The Relax NG Schema does contain "Term".
Terms kinds are Variable and Operator.

All terms have a sort,
"""
function parse_term(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    tag = Symbol(EzXML.nodename(node))

    if tag === :variable # Expect only an attribute referencing the declaration.
        var = Variable(Symbol(attribute(node, "refvariable", "term $tag missing refvariable")))
       return (var, sortof(var))
    elseif tag === :booleanconstant # Has value "true"|"false" and is BoolSort.
        bc = BooleanConstant(attribute(node, "value", "term $tag missing value"))
        return (bc, sortof(bc))
    elseif tag === :numberconstant # Has a value and is a subsort of NumberSort.
        value = attribute(node, "value", "term $tag missing value")::String
        child = EzXML.firstelement(node) # Child is the sort of value
        isnothing(child) && throw(MalformedException("$tag missing sort element"))
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
    elseif tag === :dotconstant # does not have a value and is DotSort
        return (DotConstant(), DotSort())
    #elseif tag == :numberof
        # Return multiset containing multiplicity of elements of its basis sort.
        # <text>3`dot</text>
        # <structure>
        #     <numberof>
        #         <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
        #         <subterm><dotconstant/></subterm>
        #     </numberof>
        # </structure>

    elseif tag == :all
        # Return multiset that contains exactly one element of its basis sort.
        # This is often called the broadcast function.
        # <structure>
        #     <tuple>
        #         <subterm><all><usersort declaration="N1"/></all></subterm>
        #         <subterm><all><usersort declaration="N2"/></all></subterm>
        #     </tuple>
        # </structure>
        child = EzXML.firstelement(node) # Child is the sort of value
        isnothing(child) && throw(MalformedException("$tag missing content element"))
        us = parse_usersort(child, pntd, reg)::UserSort # Can there be anything else?
        ms = Multiset(us)
        @assert length(ms) == 1
        @show ms
        return (PnmlMultiset(ms), UserSort())
    elseif tag == :feconstant
    elseif tag == :unparsed
    elseif tag == :useroperator
        # <structure>
        #   <useroperator declaration="id4"/>
        # </structure>
        uo = UserOperator(attribute(node, "declaration", "$tag missing declaration"))
        # Sort of UserOperator is the sort of the NamedOperator referenced. #! XXX FIX ME XXX
        # Declarations are at net/page level.
        # Assume to have been parsed before any reference by Variable, UserOperatore, UserSort?
        return (uo, NullSort()) #! XXX FIX ME
    elseif tag == :finiteintrangeconstant
        value = attribute(node, "value", "term $tag missing value")::String
        child = EzXML.firstelement(node) # Child is the sort of value
        isnothing(child) && throw(MalformedException("$tag missing sort element"))
        sorttag = Symbol(EzXML.nodename(child))
        if sorttag == :finiteintrange
            startstr = attribute(child, "start", "$sorttag missing start")
            start = tryparse(Int, startstr)
            isnothing(start) &&
                throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`"))

            stopstr = attribute(child, "end", "$sorttag missing end") # XML Schema uses 'end', we use 'stop'.
            stop = tryparse(Int, stopstr)
            isnothing(stop) &&
                throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`"))

            sort = FiniteIntRangeSort(start, stop)
            return (FiniteIntRangeConstant(value, sort), sort)
        end
        throw(MalformedException("$tag <finiteintrange> sort expected, found $sorttag"))

    # TODO
    # TODO more arity == 0 operators
    # TODO
    else # arity > 0, build & return an Operator Functor (also a AbstractOperator)
        println("arity > 0 term: $tag")
        interms = Union{Variable,AbstractOperator}[] # todo tuple?
        insorts = AbstractSort[]
        func = pnml_hl_operators(tag) #TODO

        for child in EzXML.eachelement(node)
            check_nodename(child, "subterm")
            subterm = EzXML.firstelement(child)
            (t, s) = parse_term(subterm, pntd, reg) # extract & accumulate input
            push!(interms, t)
            push!(insorts, s) #~ sort may be inferred from place, variable, operator output
        end
        #!@assert arity(tag) == length(interms) #todo IMPLEMENT
        @assert length(interms) == length(insorts)

        outsort = IntegerSort() #!error("XXX IMPLEMENT ME XXX")
        return (Operator(tag, func, interms, insorts, outsort), outsort)
    end
    error("parse_term: $tag not a known term")
end

function parse_term_xvdt(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry) #! type-unstable
    println("parse_term_xvdt")
    tag, xdvt = unparsed_tag(node)
    xdvt isa DictType || throw(ArgumentError(string("expected DictType, found ", xdvt, "::", typeof(xdvt))))
    tag = Symbol(tag)
    terms = Vector{PnmlExpr}[]
    if isvariable(tag)
        # Expect only an attribute.
        Variable(Symbol(_attribute(xdvt, :refvariable)))
    elseif isoperator(tag)
        if tag === :booleanconstant # has value "true"|"false" and BoolSort
            @show xdvt
            BooleanConstant(_attribute(xdvt, :value))
        elseif tag === :numberconstant # has a value and is a subsort of Number (a Sort).
            # Child is the sort of value
            @show xdvt
            #sort =
            #number_value(_attribute(Int, :value))
            #NumberConstant(value, sort)
            #   Schema says sort of integer, natural, positive.
            #   We allow real as a sort, Will consider any text string that can be parsed as a Number (a Type).
            Term(tag, xdvt)
        elseif tag === :dotconstant # does not have a value and is DotSort
            @show xdvt
            DotConstant()
        else
            Term(tag, xdvt)
        end
    else
        error(string("tag not isvariable or isoperator: ", repr(tag)))
    end
end

#=


"""
$(TYPEDSIGNATURES)

Used to construct the syntax tree of multi-sorted algebra.
"""
function parse_subterm(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "parse_subterm")
    # contains one term (not subterm) as a child
    Term(unparsed_tag(node)...)
end

#-----------------------------------------------------------------------------
# Boolean
#-----------------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)
"""
function parse_and(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "and")
    # ordered list of subterms
    Term(unparsed_tag(node)...)
end


"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "booleanconstant")
    EzXML.haskey(node, "value") || throw(MalformedException("$nn missing value attribute"))
    # <booleanconstant value="false"/>
    # <booleanconstant value="false">zero or more subterms</booleanconstant> allowed by schema
    Term(unparsed_tag(node)...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "equality")
    Term(unparsed_tag(node)...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "imply")
    Term(unparsed_tag(node)...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "inequality")
    Term(unparsed_tag(node)...)
end


"""
$(TYPEDSIGNATURES)
"""
function parse_not(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "not")
    Term(unparsed_tag(node)...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "or")
    Term(unparsed_tag(node)...)
end

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "tuple")
    Term(unparsed_tag(node)...)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    check_nodename(node, "unparsed")
    Term(unparsed_tag(node)...)
end
 =#
