
"""
$(TYPEDSIGNATURES)

There will be no XML node <term>. Instead it is the interpertation of the child of some
<structure>, <subterm> or <def> elements. The Relax NG Schema does contain "Term".
Terms kinds are Variable and Operator.
"""
function parse_term(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    tag, xdvt = unparsed_tag(node)
    xdvt isa DictType ||
        throw(ArgumentError(string("expected DictType, found ", xdvt, "::", typeof(xdvt))))
    tag = Symbol(tag)
    if isvariable(tag)
        # Expect only an attribute.
        Variable(Symbol(_attribute(xdvt, :refvariable)))
    elseif isoperator(tag)

        Term(tag, xdvt) #! This will be type-unstable
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
