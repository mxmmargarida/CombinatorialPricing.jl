# State
struct KnapsackState <: DPState{KnapsackPricing}
    remaining::Int
end

Base.show(io::IO, s::KnapsackState) = print(io, s.remaining)
Base.hash(s::KnapsackState, h::UInt) = hash(s.remaining, h)
Base.:(==)(s::KnapsackState, t::KnapsackState) = s.remaining == t.remaining

# Graph
state_type(::Type{KnapsackPricing}) = KnapsackState

const KnapsackGraph = graph_type(KnapsackPricing)
const KnapsackNode = node_type(KnapsackPricing)
const KnapsackArc = arc_type(KnapsackPricing)

source_state(g::KnapsackGraph) = KnapsackState(g.prob.capacity)
sink_state(g::KnapsackGraph) = KnapsackState(0)

function max_remaining(dpgraph::KnapsackGraph, layer::Int)
    w, C = dpgraph.prob.weights, dpgraph.prob.capacity
    w_end = sum(sum(w[i] for i in partition(dpgraph, l+1)) for l in layer:(nl(dpgraph)-1); init=0)
    return min(w_end, C)
end

function transition(dpgraph::KnapsackGraph, node::KnapsackNode, action::DPAction)
    l, state = node
    ll = l + 1
    s = state.remaining

    part = partition(dpgraph, ll)
    @assert(action ⊆ part, "Action is invalid for the layer ($action ⊊ $part)")

    wa = sum(dpgraph.prob.weights[i] for i in action; init=0)
    @assert(wa ≤ s, "Action is invalid for the state ($wa ≰ $s)")

    C = max_remaining(dpgraph, ll)
    return (ll, KnapsackState(min(s - wa, C)))
end

function is_valid_transition(dpgraph::KnapsackGraph, source::KnapsackNode, target::KnapsackNode, action::DPAction)
    s, t = source[2].remaining, target[2].remaining
    wa = sum(dpgraph.prob.weights[i] for i in action; init=0)
    # The sum of weights in action must be less than the difference of the remaining capacities
    return wa ≤ s - t
end
