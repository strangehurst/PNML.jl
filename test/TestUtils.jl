"Utilities shared by SafeTestSets"
module TestUtils
using PNML, EzXML, Preferences

"Run @test_opt, expect many dynamic dispatch reports."
const runopt::Bool = false

"Only report for our module."
const target_modules = (PNML,)

"Ignore some dynamically-designed functions."
function pnml_function_filter(@nospecialize(ft))
    if ft === typeof(PnmlIDRegistrys.register_id!) ||
       ft === typeof(Preferences.load_preference) ||
       ft === typeof(EzXML.nodename) ||
       false
        return false
    end
    return true
end

export VERBOSE_PNML, pnml_function_filter, target_modules, runopt

end # module TestUtils
