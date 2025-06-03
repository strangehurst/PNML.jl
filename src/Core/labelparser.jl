# LabelParser
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Maps a `Symbol` to a parser callable for a `<labeltag>` tag's well-formed contents.
The parser will be called as func(node, pntd) and return
"""
@auto_hash_equals struct LabelParser
    tag::Symbol
    func::Base.Callable
end

"Name of xml tag."
PNML.tag(lp::LabelParser) = lp.tag

"Callable."
func(lp::LabelParser) = lp.func
