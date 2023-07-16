"""
The state type of the dynamic programming model corresponding to the pricing problem `P`.
"""
abstract type DPState{P<:PricingProblem} end

"""
    state_type(::Type{<:PricingProblem})

Return the state type corresponding to the given pricing problem.
"""
function state_type end

"""
    source_state(g::DPGraph) -> DPState

Get the source state of the `DPGraph`.
"""
function source_state end

"""
    sink_state(g::DPGraph) -> DPState

Get the sink state of the `DPGraph`.
"""
function sink_state end

"""
    transition(graph::DPGraph, node::DPNode, action::DPAction) -> DPNode

Transition from `node` to the next layer given `action`.
"""
function transition end

"""
    is_valid_transition(graph::DPGraph, source::DPNode, target::DPNode, action::DPAction) -> Bool

Check if `action` is a valid transition between `source` and `target` nodes.
"""
function is_valid_transition end
