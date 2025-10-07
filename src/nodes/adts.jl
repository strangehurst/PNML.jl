
using Moshi.Data:   @data
using Moshi.Derive: @derive
using Moshi.Match:  @match

@data NetNode{PNTD,M,C} begin
    struct Place #{PNTD,M}
        #pntd::PNTD
        id::Symbol
        namelabel::Maybe{Name} = nothing
        graphics::Maybe{Graphics} = nothing
        toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
        extralabels::Maybe{Vector{PnmlLabel}} = nothing
        net::RefValue{<:AbstractPnmlNet} # for pagedict netdata decldict

        sorttype::SortType
        initialMarking::Marking  #! expression label
    end

    struct Arc{PNTD,I}
        id::Symbol
        namelabel::Maybe{Name} = nothing
        graphics::Maybe{Graphics} = nothing
        toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
        extralabels::Maybe{Vector{PnmlLabel}} = nothing
        net::RefValue{<:AbstractPnmlNet} # for pagedict netdata decldict

        source::RefValue{Symbol} # REFID
        target::RefValue{Symbol} # REFID
        inscription::I #! expression label
    end

    struct Transition{PNTD,C}
        pntd::PNTD
        id::Symbol
        namelabel::Maybe{Name} = nothing
        graphics::Maybe{Graphics} = nothing
        toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
        extralabels::Maybe{Vector{PnmlLabel}} = nothing
        net::RefValue{<:AbstractPnmlNet} # for pagedict netdata decldict

        condition::C #! expression label
        vars::Set{REFID}
        varsubs::Vector{NamedTuple} # Cache of variable substutions
    end

    struct RefPlace
        id::Symbol
        namelabel::Maybe{Name} = nothing
        graphics::Maybe{Graphics} = nothing
        toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
        extralabels::Maybe{Vector{PnmlLabel}} = nothing
        net::RefValue{<:AbstractPnmlNet} # for pagedict netdata decldict

        ref::Symbol # Place or RefPlace REFID
    end

    struct RefTransition
        id::Symbol
        namelabel::Maybe{Name} = nothing
        graphics::Maybe{Graphics} = nothing
        toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
        extralabels::Maybe{Vector{PnmlLabel}} = nothing
        net::RefValue{<:AbstractPnmlNet} # for pagedict netdata decldict

        ref::Symbol # Transition or RefTransition REFID
    end

    struct Page{PNTD}
        pntd::PNTD
        id::Symbol
        namelabel::Maybe{Name} = nothing
        graphics::Maybe{Graphics} = nothing
        toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
        extralabels::Maybe{Vector{PnmlLabel}} = nothing
        net::RefValue{<:AbstractPnmlNet} # for pagedict netdata decldict

        netsets::PnmlNetKeys # This page's keys of items owned in netdata/pagedict.
    end

end

@derive NetNode[Show, Hash, Eq]
