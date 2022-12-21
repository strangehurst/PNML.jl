"""
$(TYPEDEF)
"""
abstract type PnmlException <: Exception end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Use exception to allow dispatch and additional data presentation to user.
"""
struct MissingIDException <: PnmlException
    msg::String
    node::XMLNode
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct MalformedException <: PnmlException
    msg::String
    node::XMLNode
end

Base.showerror(exc::MissingIDException) = showerror(stderr, exc)
function Base.showerror(io::IO, exc::MissingIDException)
    print(io, "MissingIDException: ", exc.msg)
end

Base.showerror(exc::MalformedException) = showerror(stderr, exc)
function Base.showerror(io::IO, exc::MalformedException)
    print(io, "MalformedException: ", exc.msg)
end
