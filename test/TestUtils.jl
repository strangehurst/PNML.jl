module TestUtils
using EzXML

const PRINT_PNML = parse(Bool, get(ENV, "PRINT_PNML", "true"))

"Print `node` prepended by optional label string."
function printnode(io::IO, node; label=nothing, kw...)
    if PRINT_PNML
        !isnothing(label) && print(io, label, " ")
        show(io, MIME"text/plain"(), node)
        println(io)
    end
end
function printnode(n; kw...)
    printnode(stdout, n; kw...)
end

const VERBOSE_PNML = parse(Bool, get(ENV, "VERBOSE_PNML", "true"))

header(s) = if VERBOSE_PNML
    println("##### ", s)
end

const SHOW_SUMMARYSIZE = parse(Bool, get(ENV, "SHOW_SUMMARYSIZE", "false"))

function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

export PRINT_PNML, VERBOSE_PNML, SHOW_SUMMARYSIZE, printnode, header, showsize

end # module TestUtils
