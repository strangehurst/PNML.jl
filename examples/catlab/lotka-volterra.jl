# Start with a copy of Petri.jl examples/lotka-volterra.jl.
 see #https://algebraicjulia.github.io/AlgebraicPetri.jl/dev/generated/predation/lotka-volterra/
using PNML: PNML, SimpleNet, place_idset, transition_function, initial_markings, rates

using Petri: Petri, Model, Graph, ODEProblem
using LabelledArrays
using Plots: Plots
using OrdinaryDiffEq: OrdinaryDiffEq, Tsit5


"""
PNML model for the original example below. Note that the type is "continuous"!
"""
 str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="continuous">
        <page id="page0">
            <place id="rabbits"> <initialMarking> <text>100.0</text> </initialMarking> </place>
            <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
            <transition id ="birth">     <rate> <text>0.3</text> </rate> </transition>
            <transition id ="death">     <rate> <text>0.7</text> </rate> </transition>
            <transition id ="predation"> <rate> <text>0.015</text> </rate> </transition>
            <arc id="a1" source="rabbits"   target="birth">     <inscription><text>1</text> </inscription> </arc>
            <arc id="a2" source="birth"     target="rabbits">   <inscription><text>2</text> </inscription> </arc>
            <arc id="a3" source="wolves"    target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a4" source="rabbits"   target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a5" source="predation" target="wolves">    <inscription><text>2</text> </inscription> </arc>
            <arc id="a6" source="wolves"    target="death">     <inscription><text>1</text> </inscription> </arc>
        </page>
        </net>
    </pnml>
"""

net = PNML.SimpleNet(str)

# **Step 1:** Define the states and transitions of the Petri Net
#
# Here we have 2 states, wolves and rabbits, and transitions to
# model predation between the two species in the system

S = PNML.place_idset(net) # [:rabbits, :wolves]
Δ = PNML.transition_function(net)
# keys are transition ids,
# values are tuple of input, output vectors
#       with keys of place id and values of inscription value .
#LVector(
#       birth=(LVector(rabbits=1), LVector(rabbits=2)),
#       predation=(LVector(wolves=1, rabbits=1), LVector(wolves=2)),
#       death=(LVector(wolves=1), LVector()),
#     )

# AlgebraicJulia wants LabelledPetriNet constructed with
# with Varargs pairs of transition_name=>((input_states)=>(output_states))
# example LabelledPetriNet([:S, :I, :R], :inf=>((:S,:I)=>(:I,:I)), :rec=>(:I=>:R))

lotka = Petri.Model(S, Δ)

display(Petri.Graph(lotka))


# **Step 2:** Define the parameters and transition rates
#
# Once a model is defined, we can define out initial parameters `u0`, a time
# span `tspan`, and the transition rates of the interactions `β`

u0 = PNML.initial_markings(net) #LVector(wolves=10.0, rabbits=100.0)
tspan = (0.0,100.0)
β = PNML.rates(net) #LVector(birth=.3, predation=.015, death=.7); # transition rate

# **Step 3:** Generate a solver and solve
#
# Finally we can generate a solver and solve the simulation

# AlgebraicPetri.ODEProblem uses a AlgebraicPetri.AbstractetriNet a C-Set
prob = Petri.ODEProblem(lotka, u0, tspan, β) # transform using Petri.vectorfield(m)
#prob = OrdinaryDiffEq.ODEProblem(vectorfield(m), u0, tspan, β)
sol = OrdinaryDiffEq.solve(prob, Tsit5(), reltol=1e-8, abstol=1e-8)

display(Plots.plot(sol))

#! switch Δ = PNML.transition_function(net) for a reimplementation of TransitionMatrices
#=
function vectorfield(S = place_idset(net), outmatrix = output_matrix(), inmatrix = input_matrix())
  dt = output - input # incidence_matrix
  (du, u, p, t) -> begin # closure over dt, tm.input # signature f!(du,u,p,t)
    rates = zeros(valtype(du), nt(pn))
    u_m = [u[sname(pn, i)] for i in 1:ns(pn)] # place marking (number?)
    p_m = [p[tname(pn, i)] for i in 1:nt(pn)] # transition rate label value vector
    for i in 1:nt(pn) # ntransitions
      rates[i] = valueat(p_m[i], u, t) * prod(u_m[j]^tm.input[i, j] for j in 1:ns(pn))
    end
    for j in 1:ns(pn) # nplaces
      du[sname(pn, j)] = sum(rates[i] * dt[i, j] for i in 1:nt(pn); init=0.0)
    end
    du
  end
end

transitionrate(S, T, k, rate, t) = exp(reduce((x,y)->x+log(S[y] <= 0 ? 0 : S[y]),
                                       keys(first(T[k]));
                                       init=log(valueat(rate[k],S,t))))
valueat(f::Function, u, t) = try f(u,t) catch e f(t) end

# Petri.jl
function vectorfield(m::Model)
    S = m.S
    T = m.Δ
    ϕ = Dict()
    f(du, u, p, t) = begin
        for k in keys(u)
          ϕ[k] = #!transitionrate(u, T, k, p, t)
          exp(reduce((x,y) -> x + log(du[y] <= 0 ? 0 : du[y]), keys(first(u[k])); init=log(valueat(rate[k], du, t))))
        end
        for s in S
          du[s] = 0
        end
        for k in keys(T)
            l,r = T[k] # ins, outs
            for s in keys(l)
              #funcindex!(du, s, -, ϕ[k] * l[s])
              du[s] = -(du[s], (ϕ[k] * l[s]))
            end
            for s in keys(r)
              #funcindex!(du, s, +, ϕ[k] * r[s])
              du[s] = +(du[s], (ϕ[k] * r[s]))
            end
        end
        return du
    end
    return f
end

# AlgebraicPetri.jl

struct TransitionMatrices
  input::Matrix{Int} #
  output::Matrix{Int}
  TransitionMatrices(p::AbstractPetriNet) = begin
    input, output = zeros(Int, (nt(p), ns(p))), zeros(Int, (nt(p), ns(p)))
    for i in 1:ni(p) # arc from transition to place
      input[subpart(p, i, :it), subpart(p, i, :is)] += 1
    end
    for o in 1:no(p) # arc from place to transition
      output[subpart(p, o, :ot), subpart(p, o, :os)] += 1
    end
    new(input, output)
  end
end

vectorfield(pn::AbstractPetriNet) = begin
  tm = TransitionMatrices(pn)
  dt = tm.output - tm.input # dt is incidence matrix
  (du, u, p, t) -> begin
    rates = zeros(valtype(du), nt(pn))
    u_m = [u[sname(pn, i)] for i in 1:ns(pn)]
    p_m = [p[tname(pn, i)] for i in 1:nt(pn)]
    for i in 1:nt(pn)
      rates[i] = valueat(p_m[i], u, t) * prod(u_m[j]^tm.input[i, j] for j in 1:ns(pn))
    end
    for j in 1:ns(pn)
      du[sname(pn, j)] = sum(rates[i] * dt[i, j] for i in 1:nt(pn); init=0.0)
    end
    du
  end
end
=#
