@with_kw struct MaxStableSetPricingGenArgs
    values_dist = DiscreteUniform(50, 150)
    graph_density::Float64 = 0.16
    tolled_proportion::Float64 = 0.4
    tolled_values_multiplier::Float64 = 1.3
    random_tolled_proportion::Float64 = 0.07
end

# Interface
generate(::Type{MaxStableSetPricing}, num_vertices::Int; kwargs...) =
    generate_hard_maxstab_pricing_random(num_vertices, MaxStableSetPricingGenArgs(; kwargs...))

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

# Harder instance generation
function generate_hard_maxstab_pricing_random(num_vertices::Int, args::MaxStableSetPricingGenArgs)
    graph = erdos_renyi(num_vertices, args.graph_density)
    return generate_hard_maxstab_pricing_from_graph(graph, args)
end

generate_hard_maxstab_pricing_random(num_vertices::Int; kwargs...) =
    generate_hard_maxstab_pricing_random(num_vertices, MaxStableSetPricingGenArgs(; kwargs...))

function generate_hard_maxstab_pricing_from_graph(graph::SimpleGraph, args::MaxStableSetPricingGenArgs)
    num_vertices = nv(graph)
    edges = [(src(e), dst(e)) for e in Graphs.edges(graph)]
    base_values = Float64.(rand(args.values_dist, num_vertices))
    num_tolled = Int(ceil(num_vertices * args.tolled_proportion))
    num_tolled_random = round(Int, num_tolled * args.random_tolled_proportion)
    num_tolled_optimize = num_tolled - num_tolled_random

    # Create a temporary problem
    temp_prob = MaxStableSetPricing(num_vertices, edges, base_values, BitSet())
    temp_stab_model = follower_model(temp_prob, silent=true)
    optimize!(temp_stab_model)
    x = value.(temp_stab_model[:x])     # This is treated as the weights to sample the tolled items

    # Sample the tolled items
    tolled_optimize = sample(1:num_vertices, Weights(x .+ 1e-2), num_tolled_optimize, replace=false)
    tolled_random = shuffle(setdiff(1:num_vertices, tolled_optimize))[1:num_tolled_random]
    tolled = sort!(vcat(tolled_optimize, tolled_random))

    # Make the tolled items more attractable
    base_values[tolled] = base_values[tolled] * args.tolled_values_multiplier
    return MaxStableSetPricing(num_vertices, edges, base_values, BitSet(tolled))
end