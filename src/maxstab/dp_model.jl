# State
struct MaxStableSetState <: DPState{MaxStableSetPricing}
    available::BitSet
    num_items::Int
end

Base.show(io::IO, s::MaxStableSetState) = print(io, bitset_braille(s.available, s.num_items))
Base.hash(s::MaxStableSetState, h::UInt) = hash(s.available, h)
Base.:(==)(s::MaxStableSetState, t::MaxStableSetState) = s.available == t.available

# Graph
state_type(::Type{MaxStableSetPricing}) = MaxStableSetState

const MaxStableSetGraph = graph_type(MaxStableSetPricing)
const MaxStableSetNode = node_type(MaxStableSetPricing)
const MaxStableSetArc = arc_type(MaxStableSetPricing)

source_state(g::MaxStableSetGraph) = MaxStableSetState(union_sets(g.partition), num_items(g))
sink_state(g::MaxStableSetGraph) = MaxStableSetState(BitSet(), num_items(g))

@memoize Dict function transition(dpgraph::MaxStableSetGraph, node::MaxStableSetNode, action::DPAction)
    l, state = node
    ll = l + 1
    s = state.available
    g = graph(dpgraph.prob)
    part = partition(dpgraph, ll)
    @assert(action ⊆ part, "Action is invalid for the layer ($action ⊊ $part)")
    @assert(action ⊆ s, "Action is invalid for the state ($action ⊊ $s)")

    # All neighbors become unavailable, also all nodes in current layer
    ss = setdiff(s, partition(dpgraph, ll))
    for i in action
        setdiff!(ss, neighbors(g, i))
    end

    return (ll, MaxStableSetState(ss, state.num_items))
end

@memoize Dict function is_valid_transition(dpgraph::MaxStableSetGraph, from::MaxStableSetNode, to::MaxStableSetNode, action::DPAction)
    return true
end
