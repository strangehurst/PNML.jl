module PNet
__precompile__(true)

using Base: Fix1, Fix2, @kwdef, RefValue, isempty, length
using DocStringExtensions
using NamedTupleTools
using TermInterface
using Logging, LoggingExtras
#!using LabelledArrays #Todo beware namespace pollution
using SciMLLogging: @SciMLMessage

import OrderedCollections: OrderedDict, LittleDict, freeze, OrderedSet
import Base: eltype
import AutoHashEquals: @auto_hash_equals
import XMLDict
import Multisets: Multisets, Multiset

using PNML
using PNML: DeclDict, pntd
using PNML.PnmlTypes
using PNML.Labels
using PNML.Sorts
using PNML.PnmlGraphics
using PNML.Declarations

import PNML: initial_marking, PnmlMultiset, pid
import PNML: metagraph
import PNML: ToolParser, LabelParser
import PNML: input_matrix, output_matrix
import PNML: nettype, rates

export AbstractPetriNet, SimpleNet
export initial_markings, input_matrix, output_matrix, transition_function, pnmlnet
export labeled_transitions, counted_transitions

include("petrinet.jl")
include("transition_function.jl")
include("firing_rule.jl")

end # module PNet
