module PNet

using Base.ScopedValues
using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using TermInterface
using Logging, LoggingExtras
using LabelledArrays #Todo beware namespace pollution

import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import XMLDict
import Multisets: Multisets, Multiset

using PNML
using PNML: Context
using PNML: DeclDict
#using ..PnmlIDRegistrys
using ..PnmlTypeDefs
using ..Labels
using ..Sorts
using ..PnmlGraphics
using ..Declarations

import PNML: initial_marking, PnmlMultiset, pid
import PNML: metagraph
import PNML: ToolParser, LabelParser

export AbstractPetriNet, SimpleNet, initial_markings

include("petrinet.jl")
include("transition_function.jl")
include("metagraph.jl")
include("firing_rule.jl")

end # module PNet
