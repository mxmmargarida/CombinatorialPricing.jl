# State
struct MinSetCoverState <: DPState{MinSetCoverPricing}
    not_covered::BitSet
    num_elements::Int
end

Base.show(io::IO, s::MinSetCoverState) = print(io, bitset_braille(s.not_covered, s.num_elements))
Base.hash(s::MinSetCoverState, h::UInt) = hash(s.not_covered, h)
Base.:(==)(s::MinSetCoverState, t::MinSetCoverState) = s.not_covered == t.not_covered

# Graph
state_type(::Type{MinSetCoverPricing}) = MinSetCoverState

const MinSetCoverGraph = graph_type(MinSetCoverPricing)
const MinSetCoverNode = node_type(MinSetCoverPricing)
const MinSetCoverArc = arc_type(MinSetCoverPricing)

source_state(g::MinSetCoverGraph) = MinSetCoverState(BitSet(1:num_elements(g.prob)), num_elements(g.prob))
sink_state(g::MinSetCoverGraph) = MinSetCoverState(BitSet(), num_elements(g.prob))

function transition(dpgraph::MinSetCoverGraph, node::MinSetCoverNode, action::DPAction)
    l, state = node
    ll = l + 1
    s = state.not_covered
    sets = dpgraph.prob.sets

    part = partition(dpgraph, ll)
    @assert(action ⊆ part, "Action is invalid for the layer ($action ⊊ $part)")

    # Cover all elements in the sets within action
    ss = copy(s)
    for i in action
        setdiff!(ss, sets[i])
    end

    return (ll, MinSetCoverState(ss, state.num_elements))
end

function is_valid_transition(dpgraph::MinSetCoverGraph, source::MinSetCoverNode, target::MinSetCoverNode, action::DPAction)
    s, t = source[2].not_covered, target[2].not_covered
    sets = dpgraph.prob.sets

    must_cover = setdiff(s, t)
    isempty(must_cover) && return true
    for i in action
        setdiff!(must_cover, sets[i])
        isempty(must_cover) && return true
    end
    return false
end
