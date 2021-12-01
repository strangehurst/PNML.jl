# Ideas from MathML.jl

#TODO: use pnml tag names instead of mathml?
"$(TYPEDEF)"
applymap = Dict{String,Function}(
    "times" => Base.prod, # arity 2, but prod fine
    # "prod" => Base.prod,
    "divide" => x -> Base.:/(x...),
    "power" => x -> Base.:^(x...),
    "plus" => x -> Base.:+(x...),
    "minus" => x -> Base.:-(x...),
    # Lots more functions possible
)


"""
$(TYPEDEF)

Map XML tag names to parser functions.
"""
tagmap = Dict{String,Function}(
    # Assumes all child elements have an entry in tagmap
    #""  => x -> map(parse_node, elements(x)),

    "arc"  => parse_arc,
    "condition" => parse_condition,
    "declaration" => parse_declaration,
    "declarations"  => parse_declarations,
    "graphics" => parse_graphics,
    "hlinitialMarking" => parse_hlinitialMarking,
    "hlinscription" => parse_hlinscription,
    "initialMarking" => parse_initialMarking,
    "inscription" => parse_inscription,
    "label" => parse_label,
    "name" => parse_name,
    "net" => parse_net,
    "page"  => parse_page,
    "place"  => parse_place,
    "pnml" => parse_pnml,
    "referencePlace"  => parse_refPlace,
    "referenceTransition"  => parse_refTransition,
    "sort" => parse_sort,
    "structure" => parse_structure,
    "term" => parse_term, #TODO is this valid?
    "text" => parse_text,
    "tokengraphics"  => parse_tokengraphics,
    "tokenposition" => parse_tokenposition,
    "toolspecific"  => parse_toolspecific,
    "transition"  => parse_transition,
    "type" => parse_type,
    
    # Parts of declaratuons, types, sorts, inscription, condition, marking
    # These are expected to be under a structure element.
    "and" => parse_and,
    "arbitraryoperator" => parse_arbitraryoperator,
    "arbitrarysort" => parse_arbitrarysort,
    "bool" => parse_bool,
    "booleanconstant" => parse_booleanconstant,
    "equality" => parse_equality,
    "imply" => parse_imply,
    "inequality" => parse_inequality,
    "mulitsetsort" => parse_mulitsetsort,
    "namedoperator" => parse_namedoperator,
    "not" => parse_not,
    "or" => parse_or,
    "productsort" => parse_productsort,
    "tuple" => parse_tuple,
    "unparsed" => parse_unparsed,
    "useroperator" => parse_useroperator,
    "usersort" => parse_usersort,
    "variable" => parse_variable,
    "variabledecl" => parse_variabledecl,
)

#TODO: add bits from allowed children

#=
~/Projects/Resources/PetriNet/PNML$ find . -type f \( -name '*.pnml' \) -exec grep -hPo '<(\w+)' \{\} + | sed -e 's/^<//' | sort -u
~/Projects/Resources/PetriNet/PNML/grammar$ grep -P 'element name="(.*)"' * | sed -e 's/^[^"]*"//' -e 's/".*$//'  | sort -u


# Then remove values already in the tagmap:
add
addition
all
and
arbitraryoperator
arbitrarysort
arctype
ArrowMode
b
bendpoints
bool
booleanconstant
cardinality
cardinalityof
children
cn
colors
comment
contains
cyclicenumeration
def
delay
diagram
div
dot
dotconstant
edges
element
empty
emptylist
end
equality
feconstant
FillColor
finiteenumeration
finiteintrange
finiteintrangeconstant
FontName
FontSize
FontStyle
FrameColor
g
geq
greaterthan
greaterthanorequal
gt
gtp
guard
imply
inequality
info
input
integer
interval
jointype
labelProxy
layoutConstraint
leq
lessthan
lessthanorequal
list
listappend
listconcatenation
listlength
logevent
lt
ltp
makelist
memberatindex
mod
mult
multisetsort
namedoperator
namedsort
natural
not
numberconstant
numberof
object
or
output
pageLabelProxy
parameter
partition
partitionelement
partitionelementof
placeCapacity
places
point
positive
predecessor
productsort
r
rgbcolor
rotation
scalarproduct
setting
silent
size
sourceAnchor
spline
splitType
string
stringconcatenation
stringconstant
styles
sublist
subterm
subtract
subtraction
subunits
successor
targetAnchor
tokencolor
tokencolors
toolinfo
tuple
unit
useroperator
usersort
value
variable
variabledecl
visible
x
=#


#=
#pnml76 lists these. Above may include non-standard, non-HLnet.

and
arbitraryoperator
arbitrarysort
bool
booleanconstant
#condition
#declaration
#declarations
equality
#hlinitialmarking
#hlinscription
imply
inequality
multisetsort
namedoperator
namedsort
not
or
productsort
tuple
unparsed
useroperator
usersort
variable
variabledecl

=#
