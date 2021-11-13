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
end

Base.showerror(e::MalformedException) = showerror(stderr, e)
function Base.showerror(io::IO, e::MalformedException)
    print(io, "MalformedException: ", e.msg)
end
