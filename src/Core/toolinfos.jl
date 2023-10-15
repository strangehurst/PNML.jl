"""
$(TYPEDEF)
$(TYPEDFIELDS)

ToolInfo holds a <toolspecific> tag.

It wraps a iteratable collection (currently vector) of well formed elements
parsed into [`AnyElement`](@ref)s for use by anything that understands
toolname, version tool specifics.
"""
@auto_hash_equals struct ToolInfo{T}
    toolname::String
    version::String
    infos::T
end

"Name of tool to for this tool specific information element."
name(ti::ToolInfo) = ti.toolname
"Version of tool for this tool specific information element."
version(ti::ToolInfo) = ti.version
"Content of a ToolInfo."
infos(ti::ToolInfo) = ti.infos

Base.eltype(::ToolInfo{T}) where {T} = T

###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content.
Combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics{T <: DecFP.DecimalFloatingPoint} <: AbstractPnmlTool
    positions::Vector{Coordinate{T}}
end

# Empty TokenGraphics is allowed in spec.
TokenGraphics{T}() where {T <: DecFP.DecimalFloatingPoint} = TokenGraphics{T}(Coordinate{T}[])

###############################################################################
"""
Return first toolinfo having a matching toolname and version.
"""
function get_toolinfo end

get_toolinfo(ti::ToolInfo, name::AbstractString) = get_toolinfo(ti, Regex(name))
get_toolinfo(ti::ToolInfo, name::AbstractString, version::AbstractString) =
    get_toolinfo(ti, Regex(name), Regex(version))
get_toolinfo(ti::ToolInfo, name::AbstractString, versionrex::Regex) =
    get_toolinfo(ti, Regex(name),  versionrex)

get_toolinfo(ti::ToolInfo, namerex::Regex, versionrex::Regex=r"^.*$") =
    _match(ti, namerex, versionrex) && ti #!get_toolinfo([ti], namerex, versionrex)


get_toolinfo(infos, name::AbstractString, version::AbstractString) =
    get_toolinfo(infos, Regex(name), Regex(version))
get_toolinfo(infos, name::AbstractString, versionrex::Regex) =
    get_toolinfo(infos, Regex(name), versionrex)

function get_toolinfo(infos, namerex::Regex, versionrex::Regex=r"^.*$")
    first(get_toolinfos(infos, namerex, versionrex))
end

function get_toolinfos(infos, namerex::Regex, versionrex::Regex=r"^.*$")
    Iterators.filter(ti -> _match(ti, namerex, versionrex), infos)
end

"""
    _match(ti::ToolInfo, name::AbstractString)
    _match(ti::ToolInfo, name::String, version::String)
    _match(ti::ToolInfo, namerex::Regex, versionrex::Regex)

Match toolname and version. Default is any version.
"""
function _match end
_match(ti::ToolInfo, name::AbstractString) = _match(ti.info, Regex(name))
_match(ti::ToolInfo, name::AbstractString, version::AbstractString) = _match(ti.inf, Regex(name), Regex(version))

function _match(ti::ToolInfo, namerex::Regex, versionrex::Regex = r"^.*$")
    match_name = match(namerex, name(ti))
    match_version = match(versionrex, version(ti))
    !isnothing(match_name) && !isnothing(match_version)
end
