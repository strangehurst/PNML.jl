# Created 2025-11-10
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Real valued label. An expected use is as a static transition Priority.
Expected XML: `<priority> <text>0.3</text> </priority>`.

Dynamic priority is a function with arguments of net marking and transition.
"""
@kwdef struct Priority{T<:PnmlExpr} <: Annotation
    #todo text
    term::T # Use the same mechanism as PTNet initialMarking and inscription.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    declarationdicts::DeclDict
end

value_type(::Type{Priority}) = Float64
value_type(::Type{Priority}, ::PnmlType) = Float64

Base.eltype(::Priority) = value_type(Priority)

decldict(i::Priority) = i.declarationdicts
term(i::Priority) = i.term
sortref(i::Priority) = _sortref(decldict(i), term(i))::AbstractSortRef
sortof(i::Priority) = sortdefinition(namedsort(decldict(i), sortref(i)))::Number

function (priority::Priority)(varsub::NamedTuple=NamedTuple())
    eval(toexpr(term(priority), varsub, decldict(priority)))::value_type(Priority)
end

value(r::Priority) = r()

function Base.show(io::IO, r::Priority)
    print(io, "Priority(", r.term, ", ", repr(r.graphics),  ", ", repr(r.toolspecinfos), ")")
end

"""
    priority_value(t) -> Real

Return value of a `Priority` label.  Missing priority labels are defaulted to one.

Expected label XML: `<priority> <text>0.3</text> </priority>`

# Arguments
    `t` is anything that supports `labelof(t, tag)`.
"""
function priority_value(t)
    label_value(t, :priority, value_type(Priority), one)::value_type(Priority)
end
