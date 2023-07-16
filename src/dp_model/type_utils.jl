graph_type(::Type{P}) where P<:PricingProblem = DPGraph{P, state_type(P)}
node_type(::Type{P}) where P<:PricingProblem = DPNode{state_type(P)}
arc_type(::Type{P}) where P<:PricingProblem = DPArc{state_type(P)}

state_type(prob::PricingProblem) = state_type(typeof(prob))
graph_type(prob::PricingProblem) = graph_type(typeof(prob))
node_type(prob::PricingProblem) = node_type(typeof(prob))
arc_type(prob::PricingProblem) = arc_type(typeof(prob))

state_type(::Type{DPGraph{P,S}}) where {P,S} = S
node_type(::Type{DPGraph{P,S}}) where {P,S} = DPNode{S}
arc_type(::Type{DPGraph{P,S}}) where {P,S} = DPArc{S}

state_type(g::DPGraph) = state_type(typeof(g))
node_type(g::DPGraph) = node_type(typeof(g))
arc_type(g::DPGraph) = arc_type(typeof(g))
