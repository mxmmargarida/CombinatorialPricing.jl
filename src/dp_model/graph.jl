struct DPGraph{P<:PricingProblem, S<:DPState}
    prob::P
    partition::Partition
    layers::Vector{Vector{S}}  # Not include the source layer (layer 0)
    arcs::Vector{DPArc{S}}
end

DPGraph(prob::P, partition, layers) where P<:PricingProblem = graph_type(P)(prob, partition, layers, [])
DPGraph(prob::P, partition) where P<:PricingProblem = DPGraph(prob, partition, [state_type(P)[] for _ in 1:length(partition)])

source_node(g::DPGraph) = (0, source_state(g))
sink_node(g::DPGraph) = (nl(g), sink_state(g))

Graphs.nv(g::DPGraph) = 1 + sum(length.(g.layers))      # 1 extra node for the source
Graphs.vertices(g::DPGraph) = Iterators.flatten(vcat((source_node(g),), [((l, st) for st in layer) for (l, layer) in enumerate(g.layers)]))

Graphs.ne(g::DPGraph) = length(g.arcs)
Graphs.edges(g::DPGraph) = g.arcs

nl(g::DPGraph) = length(g.partition)                    # Not include the source layer (layer 0)
partition(g::DPGraph, l) = g.partition[l]
layer(g::DPGraph, l) = l == 0 ? [source_state(g)] : g.layers[l]
Base.getindex(g::DPGraph, l) = layer(g, l)

num_items(g::DPGraph) = num_items(g.prob)

Base.show(io::IO, g::DPGraph{P,S}) where {P,S} = print(io, "DPGraph{$P} with $(nl(g)) layers, $(nv(g)) nodes, and $(ne(g)) arcs")
