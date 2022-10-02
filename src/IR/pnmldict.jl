pid(pdict::PnmlDict)::Symbol = pdict[:id]
tag(pdict::PnmlDict)::Symbol = pdict[:tag]
xmlnode(pdict::PnmlDict) = pdict[:xml]

has_labels(pdict::PnmlDict) = haskey(pdict, :labels)
has_label(d::PnmlDict, tagvalue::Symbol) = if has_labels(d)
    has_label(labels(d), tagvalue)
else
    false
end

labels(pdict::PnmlDict) = pdict[:labels]

get_label(d::PnmlDict, tagvalue::Symbol) = has_labels(d) ? get_label(labels(d), tagvalue) : nothing
get_labels(d::PnmlDict, tagvalue::Symbol) = get_labels(labels(d), tagvalue)

