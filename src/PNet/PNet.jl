module PNet
import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import XMLDict
using DocStringExtensions
using NamedTupleTools
import Multisets: Multisets, Multiset
using TermInterface
using Logging, LoggingExtras
using LabelledArrays #Todo beware namespace pollution

using PNML
#using PNML: XMLNode
import PNML: initial_marking, PnmlMultiset, pid

#using ..PnmlIDRegistrys
using ..PnmlTypeDefs
using ..Labels
using ..Sorts
using ..PnmlGraphics
using ..Declarations

export AbstractPetriNet, SimpleNet, initial_markings

include("petrinet.jl")
include("transition_function.jl")
include("metagraph.jl")
include("firing_rule.jl")

end # module PNet
