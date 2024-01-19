"Utilities shared by SafeTestSets"
module TestUtils
using PNML, EzXML, Preferences

"Often JET has problems with beta julia versions:("
const jet_broke = (VERSION < v"1.10-") ? false : true

"Run @test_opt, expect many dynamic dispatch reports."
const runopt::Bool = false

"Print a lot of information as tests run."
const noisy::Bool = false

"Only report for our module."
const target_modules = (PNML,)

"Allow test of show methods without creating a file."
const testshow = devnull # nothing turns off redirection

"Ignore some dynamically-designed functions."
function pff(@nospecialize(ft))
    if ft === typeof(PnmlIDRegistrys.register_id!) ||
       ft === typeof(Preferences.load_preference) ||
       ft === typeof(EzXML.nodename) ||
       ft === typeof(Base.string) ||
       ft === typeof(Base.println) ||
       #ft === typeof(FunctionWrappers.convert_ret) ||
       false
        return false
    end
    return true
end

export VERBOSE_PNML, pff, target_modules,
        jet_broke, runopt, testshow, noisy

end # module TestUtils
