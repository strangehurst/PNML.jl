module TestUtils
using PNML, .PnmlCore
using EzXML, Preferences

const PRINT_PNML = parse(Bool, get(ENV, "PRINT_PNML", "true"))

const SHOW_SUMMARYSIZE = parse(Bool, get(ENV, "SHOW_SUMMARYSIZE", "false"))

function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

runopt::Bool = false

const target_modules = (PNML, PnmlCore)

# ignore some dynamically-designed functions
function pnml_function_filter(@nospecialize(ft))
    #@show ft
    if ft === typeof(PnmlIDRegistrys.register_id!) ||
       ft === typeof(PNML.EzXML.nodename)
       false
        return false
    end
    return true
end

export PRINT_PNML, VERBOSE_PNML, SHOW_SUMMARYSIZE, printnode, header, showsize,
        pnml_function_filter, target_modules, runopt

end # module TestUtils
