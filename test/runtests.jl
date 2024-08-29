using PNML, Test, SafeTestsets
using AbstractTrees
using OrderedCollections
using Documenter
using JET, Aqua

println("ARGS = ", ARGS)

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

include("TestUtils.jl")
using .TestUtils

"Return true if `ARGS` is empty or one of `v` is found in `ARGS`."
select(v...) = isempty(ARGS) || any(∈(ARGS), v)

if select("none", "NONE")
    return nothing # Have chosen to bail before any tests.
end

#############################################################################
@time "TESTS" begin

@testset verbose=true failfast=true showtiming=true "PNML.jl" begin
    if select("ALL", "AQUA")
        @testset "Aqua" begin
            Aqua.test_all(PNML;
              ambiguities=(recursive=false),
              #unbound_args=true,
              #undefined_exports=true,
              #project_extras=true,
              stale_deps=(ignore=[:Metatheory],),
              deps_compat=(ignore=[:Metatheory],),
              #project_toml_formatting=true,

              piracies=false,
              persistent_tasks=false, # Metatheory ale/3.0 is not in registry
            )
          end
    end
    if select("ALL", "BASE")
        println("BASE")
        @safetestset "typedefs"  begin include("typedefs.jl") end
        @safetestset "registry"  begin include("idregistry.jl") end
        @safetestset "utils"     begin include("utils.jl") end
    end
    if select("ALL", "REWRITE")
        println("REWRITE")
        @safetestset "rewrite"     begin include("rewrite.jl") end
    end
    if select("ALL", "CORE")
        println("CORE")
        @safetestset "graphics"     begin include("graphics.jl") end
        @safetestset "toolspecific" begin include("toolspecific.jl") end
        @safetestset "labels"       begin include("labels.jl") end
    end
    if select("ALL", "CORE2")
        @safetestset "declarations" begin include("declarations.jl") end
        @safetestset "nodes"        begin include("nodes.jl") end
        @safetestset "pages"        begin include("pages.jl") end
        @safetestset "exceptions"   begin include("exceptions.jl") end
        @safetestset "flatten"      begin include("flatten.jl") end
    end

    if select("ALL2", "NET")
        println("NET")
        @safetestset "document"     begin include("document.jl") end
        @safetestset "parse_tree"   begin include("parse_tree.jl") end
    end

     if select("ALL2", "NET2")
        @safetestset "rate"         begin include("rate.jl") end
        @safetestset "simplenet"    begin include("simplenet.jl") end
    end

    if select("ALL", "DOC")
        println("DOC")
        @testset "doctest" begin doctest(PNML, manual = true) end
    end
end
end # time
