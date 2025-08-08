push!(LOAD_PATH, "../src/")
using Pkg, Documenter, DocumenterPlantUML, PNML

the_repo() =  if isempty(get(ENV, "DOCUMENTER_KEY", ""))
    "github.com/strangehurst/PNML.jl"
else
    "/home/jeff/Jules/PNML"
end

DocMeta.setdocmeta!(PNML, :DocTestSetup, :(using PNML); recursive=true)

#println("Build documentation, repo = $(to_repo())")
mathengine = MathJax3(Dict(:loader => Dict("load" => ["[tex]/physics"]),
                           :tex => Dict("inlineMath" => [["\$", "\$"],
                                                         ["\\(", "\\)"]],
                                        "tags" => "ams",
                                        "packages" => ["base",
                                                       "ams",
                                                       "autoload",
                                                       "physics"],
                        ),))


pages=[
    "Petri Net Markup Language" => "index.md",
    "Status"                    => "status.md",
    "Structure" => [
        "Intermediate Representation" => "structure/layers.md",
        "Petri Net Type Definition" => "structure/pntd.md",
        "Labels"                    => "structure/labels.md",
        "Traits"                    => "structure/traits.md",
        "Type Hierarchies"          => "structure/type_hierarchies.md",
        "Interfaces"                => "structure/interface.md",
        "Math"                      => "structure/mathematics.md",
        "Default Values"            => "structure/defaults.md",
        "Parser"                    => "structure/parser.md",
        "Enabling & Firing Rules"   => "structure/enabling_firing.md",
    ],
    "Examples"                  => "examples.md",
    "Docstrings"                => "library.md",
    "acknowledgments.md",
]
#todo include("pages.jl")


################################################################################
# Building HTML documentation with Documenter
################################################################################

makedocs(;
         clean = true,
         doctest = false, # runtests.jl also does doctest
         modules = [PNML],
         authors = "Jeff Hurst",
         #repo="/home/jeff/Jules/PNML/{path}",
         #repo = Documenter.Remotes.GitHub("strangehurst","PNML.jl"),
         warnonly = [:docs_block, :missing_docs, :cross_references],

         checkdocs = :all,

         format=Documenter.HTML(;
                                edit_link=nothing,
                                # CI means publish documentation on GitHub.
                                prettyurls=get(ENV, "CI", nothing) == "true",
                                canonical="https://strangehurst.github.io/PNML.jl",
                                size_threshold_ignore=["library.md"],
                                mathengine,
                                ),
         sitename="PNML.jl",
         pages=pages,
         )

################################################################################
# Deploying documentation
################################################################################

if !isempty(get(ENV, "DOCUMENTER_KEY", ""))
    deploydocs(;
            # repo = Documenter.Remotes.GitHub("strangehurst","PNML.jl"),
            repo = "github.com/strangehurst/PNML.jl",
               devbranch = "main",
               push_preview = false,
               )
end
