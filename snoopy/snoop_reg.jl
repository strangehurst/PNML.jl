# SnoopCompile
using SnoopCompileCore

invalidations = @snoopr begin
    using PnmlIDRegistrys

    tinf = @snoopi_deep begin
        reg = PnmlIDRegistry()
        register_id!(reg, :p)
        register_id!(reg, :p)
        !isregistered_id(reg, "p")
        !isregistered_id(reg, :p)
    end
end

using SnoopCompile

trees = SnoopCompile.invalidation_trees(invalidations);
staletrees = precompile_blockers(trees, tinf)

@show length(SnoopCompile.uinvalidated(invalidations)) # show total invalidations

if !isempty(trees)
    show(trees[end]) # show the most invalidating method

    # Count number of children (number of invalidations per invalidated method)
    n_invalidations = map(SnoopCompile.countchildren, trees)

    import Plots
    Plots.plot(
        1:length(trees),
        n_invalidations;
        markershape=:circle,
        xlabel="i-th method invalidation",
        label="Number of children per method invalidations"
    )
end
