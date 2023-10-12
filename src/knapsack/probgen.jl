@with_kw struct KnapsackPricingGenArgs
    values_dist = DiscreteUniform(1, 100)
    weights_dist = DiscreteUniform(1, 100)
    density_dist = Uniform(0.75, 1.25)
    capacity_ratio::Float64 = 0.6
    tolled_proportion::Float64 = 0.6
    tolled_values_multiplier::Float64 = 2.0
end

# Interface
generate(::Type{KnapsackPricing}, num_items::Int; kwargs...) =
    generate_knapsack_pricing_uniform(num_items, KnapsackPricingGenArgs(; kwargs...))

# Implementations
function generate_knapsack_pricing_uniform(num_items::Int, args::KnapsackPricingGenArgs)
    weights = rand(args.weights_dist, num_items)
    density = rand(args.density_dist, num_items)
    base_values = round.(density .* weights)
    capacity = ceil(sum(weights) * args.capacity_ratio)
    num_tolled = Int(ceil(num_items * args.tolled_proportion))
    tolled = sort!(shuffle(1:num_items)[1:num_tolled])
    # Make the tolled items more attractable
    base_values[tolled] = base_values[tolled] * args.tolled_values_multiplier
    return KnapsackPricing(weights, capacity, base_values, BitSet(tolled))
end

generate_knapsack_pricing_uniform(num_items; kwargs...) =
    generate_knapsack_pricing_uniform(num_items, KnapsackPricingGenArgs(; kwargs...))
