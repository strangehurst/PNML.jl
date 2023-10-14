
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
    PnmlLabel(unparsed_tag(node, pntd, reg), node)
end


"""
$(TYPEDSIGNATURES)
"""
function parse_booleanconstant(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "booleanconstant")
    EzXML.haskey(node, "declaration") || throw(MalformedException("$nn missing declaration attribute"))

    PnmlLabel(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_equality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "equality")
    PnmlLabel(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_imply(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "imply")
    PnmlLabel(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inequality(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "inequality")
    PnmlLabel(unparsed_tag(node, pntd, reg))
end


"""
$(TYPEDSIGNATURES)
"""
function parse_not(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "not")
    PnmlLabel(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_or(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "or")
    PnmlLabel(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_tuple(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    nn = check_nodename(node, "tuple")
    PnmlLabel(unparsed_tag(node, pntd, reg))
end

"""
$(TYPEDSIGNATURES)
"""
function parse_unparsed(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)
    check_nodename(node, "unparsed")
    PnmlLabel(unparsed_tag(node, pntd, reg))
end
