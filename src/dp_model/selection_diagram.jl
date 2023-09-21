# State
struct SDState <: DPState{PricingProblem}
    selected::BitSet
end

Base.show(io::IO, s::SDState) = print(io, Tuple(s.selected))
Base.hash(s::SDState, h::UInt) = hash(s.selected, h)
Base.:(==)(s::SDState, t::SDState) = s.selected == t.selected

const SDArc = DPArc{DPState}

# Graph
struct SDGraph{P<:PricingProblem}
    prob::P
    layers::Vector{Vector{SDState}}  # Not include the source layer (layer 0)
    arcs::Vector{SDArc}
end

source_state(::SDGraph) = SDState(BitSet())
sink_state(::SDGraph) = SDState(BitSet())

source_node(g::SDGraph) = (0, source_state(g))
sink_node(g::SDGraph) = (nl(g), sink_state(g))

Graphs.nv(g::SDGraph) = 1 + sum(length.(g.layers))      # 1 extra node for the source
Graphs.vertices(g::SDGraph) = Iterators.flatten(vcat((source_node(g),), [((l, st) for st in layer) for (l, layer) in enumerate(g.layers)]))

Graphs.ne(g::SDGraph) = length(g.arcs)
Graphs.edges(g::SDGraph) = g.arcs

nl(g::SDGraph) = length(g.layers)                    # Not include the source layer (layer 0)
layer(g::SDGraph, l) = l == 0 ? [source_state(g)] : g.layers[l]
Base.getindex(g::SDGraph, l) = layer(g, l)

num_items(g::SDGraph) = num_items(g.prob)

Base.show(io::IO, g::SDGraph{P}) where {P} = print(io, "SDGraph{$P} with $(nl(g)) layers, $(nv(g)) nodes, and $(ne(g)) arcs")

# Construction
function sdgraph_from_pairs(prob::PricingProblem, pairs)
    layer1 = SDState.(BitSet.(unique!(collect(Iterators.flatten(pairs)))))
    layer2 = SDState.(BitSet.(unique!(pairs)))
    layer3 = [SDState(BitSet())]
    layers = [layer1, layer2, layer3]

    arcs = SDArc[]
    g = SDGraph(prob, layers, arcs)
    source = source_node(g)
    for s in layer1
        push!(arcs, SDArc(source, (1, s), s.selected))
    end
    for s in layer1, t in layer2
        issubset(s.selected, t.selected) || continue
        push!(arcs, SDArc((1, s), (2, t), setdiff(t.selected, s.selected)))
    end

    return g
end

