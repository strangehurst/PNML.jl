module TestUtils
using PNML, .PnmlCore, .PnmlIDRegistrys, .PnmlTypeDefs
using EzXML

const PRINT_PNML = parse(Bool, get(ENV, "PRINT_PNML", "true"))

const SHOW_SUMMARYSIZE = parse(Bool, get(ENV, "SHOW_SUMMARYSIZE", "false"))

function showsize(ob,k)
    if SHOW_SUMMARYSIZE && PRINT_PNML
        summarysz = Base.summarysize(ob[k])
        @show k,summarysz
    end
end

const target_modules = (PNML, PnmlCore, PnmlIDRegistrys, PnmlTypeDefs,)

# ignore some dynamically-designed functions
function pnml_function_filter(@nospecialize ft)
    #@show ft
    if ft === typeof(Base.lock) ||
       ft === typeof(EzXML.findall) ||
       ft === typeof(allchildren) ||
       false
        return false
    end
    return true
end

export PRINT_PNML, VERBOSE_PNML, SHOW_SUMMARYSIZE, printnode, header, showsize,
        pnml_function_filter, target_modules

end # module TestUtils
