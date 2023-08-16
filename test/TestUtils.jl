"Utilities shared by SafeTestSets"
module TestUtils
using PNML, EzXML, Preferences

"Run @test_opt, expect many dynamic dispatch reports."
const runopt::Bool = false

"Print a lot of information as tests run."
const noisy::Bool = false

"Only report for our module."
const target_modules = (PNML,)

"Allow test of show methods without creating a file."
const testshow = devnull # nothing turns off redirection

"Ignore some dynamically-designed functions."
function pnml_function_filter(@nospecialize(ft))
    if ft === typeof(PnmlIDRegistrys.register_id!) ||
       ft === typeof(Preferences.load_preference) ||
       ft === typeof(EzXML.nodename) ||
       ft === typeof(Base.string) ||
       false
        return false
    end
    return true
end

export VERBOSE_PNML, pnml_function_filter, target_modules, runopt, testshow, noisy

end # module TestUtils
