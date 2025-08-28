using PNML, Test, SafeTestsets
using AbstractTrees
using OrderedCollections
using Documenter
using JET, Aqua

@show ARGS

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

include("TestUtils.jl")
using .TestUtils

"Return true if `ARGS` is empty or one of `y`  and none of `n` is found in `ARGS`."
select(y, n::Tuple=()) = isempty(ARGS) ? true : (any(∈(ARGS), y) && !any(∈(ARGS), n))
select(y, n) = select(y, tuple(n))

const FAILFAST = parse(Bool, get(ENV, "JULIA_TEST_FAILFAST", "true"))
@show FAILFAST

#############################################################################
@time "TESTS" begin
@testset verbose=true failfast=FAILFAST showtiming=true "PNML.jl" begin
    if !isempty(ARGS) && select("NONE")
        return nothing # Have chosen to bail before any tests.
    end
    if select(("ALL", "AQUA"))
        @testset "Aqua" begin
            Aqua.test_all(PNML;
                ambiguities=(recursive=false),
                #unbound_args=true,
                #undefined_exports=true,
                #project_extras=true,
                #stale_deps=(ignore=[:Metatheory],),
                #deps_compat=(ignore=[:Metatheory],),
                #project_toml_formatting=true,

                piracies=false,
                persistent_tasks=false, # Metatheory ale/3.0 is not in registry
            )
        end
    end
    if select(("ALL", "BASE"), "!BASE")
        println("# BASE #")
        @safetestset "typedefs"  begin include("typedefs.jl") end
        @safetestset "registry"  begin include("idregistry.jl") end
        @safetestset "utils"     begin include("utils.jl") end
    end
    if select(("ALL", "REWRITE"), "!REWRITE")
        println("# REWRITE #")
        @safetestset "rewrite"     begin include("rewrite.jl") end
    end
    if select(("ALL", "CORE"), "!CORE")
        println("# CORE #")
        @safetestset "graphics"     begin include("graphics.jl") end
        @safetestset "toolspecific" begin include("toolspecific.jl") end
        @safetestset "labels"       begin include("labels.jl") end
    end

    if select(("ALL", "HL"), ("!HL",))
        println("# HL #")
        @safetestset "labels_hl"    begin include("labels_hl.jl") end
    end

    if select(("ALL", "CORE2"), ("!CORE2",))
        println("# CORE2 #")
        @safetestset "declarations" begin include("declarations.jl") end
        @safetestset "nodes"        begin include("nodes.jl") end
        @safetestset "pages"        begin include("pages.jl") end
        @safetestset "exceptions"   begin include("exceptions.jl") end
    end
    if select(("ALL", "CORE2", "FLAT"), ("!CORE2", "!FLAT"))
        @safetestset "flatten"      begin include("flatten.jl") end
    end

    if select(("ALL", "EXPR"), ("!EXPR",))
        println("# EXPR #")
        @safetestset "pnmlexpr"     begin include("pnmlexpr.jl") end
    end

    if select(("ALL", "NET"), ("!NET",))
        println("# NET #")
        @safetestset "document"     begin include("document.jl") end
    end

    if select(("ALL", "NET1"), ("!NET1",))
        println("# NET1 #")
        @safetestset "parse_tree"   begin include("parse_tree.jl") end
    end

    if select(("ALL", "NET2"), ("!NET2",))
        println("# NET2 #")
        @safetestset "sampleSNPrio"   begin include("sampleSNPrio.jl") end
    end

     if select(("ALL", "NET3"), ("!NET3",))
        println("# NET3 #")
        @safetestset "rate"         begin include("rate.jl") end
        @safetestset "simplenet"    begin include("simplenet.jl") end
    end

    if select(("ALL", "DOC"), ("!DOC",))
        println("# DOC #")
        @testset "doctest" begin doctest(PNML, manual = true) end
    end
end
end # time
