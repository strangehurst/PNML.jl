module TestUtils
using EzXML

const PRINT_PNML = parse(Bool, get(ENV, "PRINT_PNML", "true"))

const SHOW_SUMMARYSIZE = parse(Bool, get(ENV, "SHOW_SUMMARYSIZE", "false"))

function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

export PRINT_PNML, VERBOSE_PNML, SHOW_SUMMARYSIZE, printnode, header, showsize

end # module TestUtils
