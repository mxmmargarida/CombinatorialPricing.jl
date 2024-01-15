graph_type(::Type{P}) where P<:AbstractProblem = DPGraph{P, state_type(P)}
node_type(::Type{P}) where P<:AbstractProblem = DPNode{state_type(P)}
arc_type(::Type{P}) where P<:AbstractProblem = DPArc{state_type(P)}

state_type(prob::AbstractProblem) = state_type(typeof(prob))
graph_type(prob::AbstractProblem) = graph_type(typeof(prob))
node_type(prob::AbstractProblem) = node_type(typeof(prob))
arc_type(prob::AbstractProblem) = arc_type(typeof(prob))

state_type(::Type{DPGraph{P,S}}) where {P,S} = S
node_type(::Type{DPGraph{P,S}}) where {P,S} = DPNode{S}
arc_type(::Type{DPGraph{P,S}}) where {P,S} = DPArc{S}

state_type(g::DPGraph) = state_type(typeof(g))
node_type(g::DPGraph) = node_type(typeof(g))
arc_type(g::DPGraph) = arc_type(typeof(g))
