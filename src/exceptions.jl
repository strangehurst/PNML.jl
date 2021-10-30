"""
$(TYPEDEF)

$(TYPEDFIELDS)
"""
abstract type PnmlException <: Exception end

"""
$(TYPEDEF)

$(TYPEDFIELDS)

Use exception to allow dispatch and additional data presentation to user.
"""
struct MissingIDException <: PnmlException
    msg::String
    node::EzXML.Node
end

"""
$(TYPEDEF)

$(TYPEDFIELDS)
"""
struct MalformedException <: PnmlException
    msg::String
    node::EzXML.Node
end

Base.showerror(e::MissingIDException) = showerror(stderr, e)
function Base.showerror(io::IO, e::MissingIDException)
    print(io, "MissingIDException: ", e.msg)
    #node_summary(io, e.node) # Print just the first 5 lines of the offending XML node.
end

Base.showerror(e::MalformedException) = showerror(stderr, e)
function Base.showerror(io::IO, e::MalformedException)
    print(io, "MalformedException: ", e.msg)
    #node_summary(io, e.node) # Print just the first 5 lines of the offending XML node.
end

"""
$(TYPEDSIGNATURES)

Pretty print the first `n` lines of the XML node.
If `io` is not supplied, prints to the default output stream `stdout`.
`pp` can be any pretty print method that takes (io::IO, node).
"""
function node_summary end
node_summary(node; n=5, pp=EzXML.prettyprint) = node_summary(stdout, node; n, pp)
function node_summary(io::IO, node; n=5, pp=EzXML.prettyprint)
    iobuf = IOBuffer()
    pp(iobuf, node)
    s = split(String(take!(iobuf)), "\n")
    head = @view s[begin:min(end,n)]
    println.(Ref(io), head)
    println(io, "...")
end
