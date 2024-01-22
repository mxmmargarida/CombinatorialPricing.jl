# State
struct KnapsackInterdictionState <: DPState{KnapsackInterdiction}
    remaining::Int
end

Base.show(io::IO, s::KnapsackInterdictionState) = print(io, s.remaining)
Base.hash(s::KnapsackInterdictionState, h::UInt) = hash(s.remaining, h)
Base.:(==)(s::KnapsackInterdictionState, t::KnapsackInterdictionState) = s.remaining == t.remaining

# Graph
state_type(::Type{KnapsackInterdiction}) = KnapsackInterdictionState

const KnapsackInterdictionGraph = graph_type(KnapsackInterdiction)
const KnapsackInterdictionNode = node_type(KnapsackInterdiction)
const KnapsackInterdictionArc = arc_type(KnapsackInterdiction)

source_state(g::KnapsackInterdictionGraph) = KnapsackInterdictionState(g.prob.lower_cap)
sink_state(::KnapsackInterdictionGraph) = KnapsackInterdictionState(0)

function max_remaining(dpgraph::KnapsackInterdictionGraph, layer::Int)
    w, C = dpgraph.prob.lower_weights, dpgraph.prob.lower_cap
    w_end = sum(sum(w[i] for i in partition(dpgraph, l+1)) for l in layer:(nl(dpgraph)-1); init=0)
    return min(w_end, C)
end

function transition(dpgraph::KnapsackInterdictionGraph, node::KnapsackInterdictionNode, action::DPAction)
    l, state = node
    ll = l + 1
    s = state.remaining

    part = partition(dpgraph, ll)
    @assert(action ⊆ part, "Action is invalid for the layer ($action ⊊ $part)")

    wa = sum(dpgraph.prob.lower_weights[i] for i in action; init=0)
    @assert(wa ≤ s, "Action is invalid for the state ($wa ≰ $s)")

    C = max_remaining(dpgraph, ll)
    return (ll, KnapsackInterdictionState(min(s - wa, C)))
end

function is_valid_transition(dpgraph::KnapsackInterdictionGraph, source::KnapsackInterdictionNode, target::KnapsackInterdictionNode, action::DPAction)
    s, t = source[2].remaining, target[2].remaining
    wa = sum(dpgraph.prob.lower_weights[i] for i in action; init=0)
    # The sum of weights in action must be less than the difference of the remaining capacities
    return wa ≤ s - t
end
