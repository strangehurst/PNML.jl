
"""
$(TYPEDSIGNATURES)

There will be no XML node 'term'. Instead it is the interpertation of the child of some 'structure' or `def` elements.
"""
function parse_term(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    Term(unparsed_tag(node, pntd, reg))
end

#! TODO Terms kinds are Variable and Operator


"""
$(TYPEDSIGNATURES)

Used to construct the syntax tree of multi-sorted algebra.
"""
function parse_subterm(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    #tag, value = unparsed_tag(node, pntd, reg)
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_and(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "and")
    Term(unparsed_tag(node, pntd, reg))
end


"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "booleanconstant")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))

    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "equality")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "imply")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "inequality")
    Term(unparsed_tag(node, pntd, reg))
end


"""
$(TYPEDSIGNATURES)
"""
function parse_not(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "not")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "or")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "tuple")
    Term(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    check_nodename(node, "unparsed")
    Term(unparsed_tag(node, pntd, reg))
end