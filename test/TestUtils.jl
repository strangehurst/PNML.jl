"Utilities shared by SafeTestSets"
module TestUtils
using PNML, EzXML, Preferences, Reexport
using GarishPrint: GarishPrint

"Overide GarishPrint options"
const garishswitches = (:color=>false, :show_indent=>false)

pprint(s::AbstractString, x; kw...) = pprint(stdout, s, x; kw...)
function pprint(io::IO, s::AbstractString, x; kw...)
    println(io, s; kw...)
    pprint(io, x; kw...)
end

pprint(x; kw...) = pprint(stdout, x; kw...)
pprintln(x; kw...) = pprintln(stdout, x; kw...)

pprint(io::IO, x; kw...) = GarishPrint.pprint(io, MIME"text/plain"(), x; kw..., garishswitches...)

# Prints a comment on the line before, and a newline after.
pprintln(s::AbstractString, x; kw...) = pprintln(stdout, s, x; kw...)
function pprintln(io::IO, s::AbstractString, x; kw...)
    println(io, s; kw...)
    pprintln(io, x; kw...)
end

pprintln(io::IO, x; kw...) = pprintln(io::IO, MIME"text/plain"(), x; kw...)
function pprintln(io::IO, m::MIME, x; kw...)
    GarishPrint.pprint(io, m, x; kw..., garishswitches...)
    println(io)
end



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
        jet_broke, runopt, testshow, noisy,
        pprint, pprintln

end # module TestUtils
