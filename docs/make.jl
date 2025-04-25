push!(LOAD_PATH, "../src/")
using Pkg, Documenter, PNML

the_repo() =  if isempty(get(ENV, "DOCUMENTER_KEY", ""))
    "github.com/strangehurst/PNML.jl"
else
    "/home/jeff/Jules/PNML"
end
#println("Build documentation, repo = $(to_repo())")

################################################################################
#                 Building HTML documentation with Documenter                  #
################################################################################

makedocs(;
         clean = true,
         doctest=false, # runtests.jl also does doctest
         modules=[PNML],
         authors="Jeff Hurst <strangehurst@users.noreply.github.com>",
         #repo="/home/jeff/Jules/PNML/{path}",
         #repo = Documenter.Remotes.GitHub("strangehurst","PNML.jl"),

         checkdocs = :all,

         format=Documenter.HTML(;
                                edit_link=nothing,
                                # CI means publish documentation on GitHub.
                                #prettyurls=true,
                                prettyurls=get(ENV, "CI", nothing) == "true",
                                canonical="https://strangehurst.github.io/PNML.jl",
                                size_threshold_ignore=["library.md"],
                                mathengine = MathJax3(Dict(
                                    :loader => Dict("load" => ["[tex]/physics"]),
                                    :tex => Dict(
                                            "inlineMath" => [["\$","\$"], ["\\(","\\)"]],
                                            "tags" => "ams",
                                            "packages" => ["base", "ams", "autoload", "physics"],
                                            ),
                                    ))
                                #assets=String[],
                                #prerender=false,
                                #no highlight.js
                                ),
         sitename="PNML.jl",
         pages=[
            "Petri Net Markup Language" => "pnml.md",
            "Status"                    => "status.md",
            "Layers of Abstraction"     => "layers.md",
            #"Subpackages" => "subpackages.md",
            #"Intermediate Representation" => "IR.md",
            "Type Hierarchies"          => "type_hierarchies.md",
            "Interfaces"                => "interface.md",
            "Math"                      => "mathematics.md",
            "Default Values"            => "defaults.md",
            "Evaluate"                  => "evaluate.md",
            "Parser"                    => "parser.md",
            "Examples"                  => "examples.md",
            "Docstrings"                => "library.md",
            "Index"                     => "index.md",
            "acknowledgments.md",
          ],
         )


################################################################################
#                           Deploying documentation                            #
################################################################################

if !isempty(get(ENV, "DOCUMENTER_KEY", ""))
    deploydocs(;
            # repo = Documenter.Remotes.GitHub("strangehurst","PNML.jl"),
            repo = "github.com/strangehurst/PNML.jl",
               devbranch = "main",
               push_preview = false,
               )
end
