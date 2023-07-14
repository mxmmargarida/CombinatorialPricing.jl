@with_kw struct MaxStableSetPricingGenArgs
    values_dist = DiscreteUniform(50, 150)
    graph_density::Float64 = 0.2
    tolled_proportion::Float64 = 0.5
    tolled_values_multiplier::Float64 = 1.5
end

# Interface
generate(::Type{MaxStableSetPricing}, num_vertices::Int; kwargs...) =
    generate_maxstab_pricing_random(num_vertices, MaxStableSetPricingGenArgs(; kwargs...))

# Implementations
function generate_maxstab_pricing_random(num_vertices::Int, args::MaxStableSetPricingGenArgs)
    graph = erdos_renyi(num_vertices, args.graph_density)
    return generate_maxstab_pricing_from_graph(graph, args)
end

function generate_maxstab_pricing_from_graph(graph::SimpleGraph, args::MaxStableSetPricingGenArgs)
    num_vertices = nv(graph)
    edges = [(src(e), dst(e)) for e in Graphs.edges(graph)]
    base_values = Float64.(rand(args.values_dist, num_vertices))
    num_tolled = Int(ceil(num_vertices * args.tolled_proportion))
    tolled = sort!(shuffle(1:num_vertices)[1:num_tolled])
    # Make the tolled items more attractable
    base_values[tolled] = base_values[tolled] * args.tolled_values_multiplier
    return MaxStableSetPricing(num_vertices, edges, base_values, BitSet(tolled))
end

generate_maxstab_pricing_from_graph(graph::AbstractGraph, args::MaxStableSetPricingGenArgs) =
    generate_maxstab_pricing_from_graph(SimpleGraph(graph), args)

generate_maxstab_pricing_from_graph(graph; kwargs...) =
    generate_maxstab_pricing_from_graph(graph, MaxStableSetPricingGenArgs(; kwargs...))
