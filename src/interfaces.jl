# Declare&Document interface functions of PNML.jl
# Any method defined in this file should operate on `Any`.

"""
    pid(x) -> Symbol

Return pnml id symbol.
"""
function pid end

"""
    tag(x) -> Symbol

Return tag symbol.
"""
function tag end

"""
    name(x) -> Union{Name,String}

Return name String.
"""
function name end

"""
    has_xml(x) -> Bool

Return `true` if has XML attached. Defaults to `false`.
"""
function has_xml end
has_xml(x::Any) = hasproperty(x, :xml)

"""
    xmlnode(x) -> XMLNode

Return attached xml node.
"""
function xmlnode end

