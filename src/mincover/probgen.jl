@with_kw struct MinSetCoverPricingGenArgs
    element_costs_dist = DiscreteUniform(50, 100)
    set_cost_multiplier_dist = Uniform(0.8, 1.2)
    sets_elements_ratio::Float64 = 2.0
    include_probability::Float64 = 0.1
    tolled_proportion::Float64 = 0.5
    tolled_costs_multiplier::Float64 = 1.5
end

# Interface
generate(::Type{MinSetCoverPricing}, num_sets::Int; kwargs...) =
    generate_mincover_pricing_random(num_sets, MinSetCoverPricingGenArgs(; kwargs...))

# Implementations
function generate_mincover_pricing_random(num_sets::Int, args::MinSetCoverPricingGenArgs)
    num_elements = ceil(Int, num_sets / args.sets_elements_ratio)
    elements_costs = rand(args.element_costs_dist, num_elements)

    num_tolled = Int(ceil(num_sets * args.tolled_proportion))
    num_toll_free = num_sets - num_tolled

    # There must be a cover of num_toll_free sets, so we seed some sets deterministically
    seeds = collect(Iterators.partition(shuffle(1:num_elements), ceil(Int, num_elements/num_toll_free)))

    # Synthesize the sets
    sets = BitSet[]
    base_costs = Float64[]
    while length(sets) < num_sets
        set = BitSet(findall(<(args.include_probability), rand(num_elements)))
        isempty(seeds) || push!(set, pop!(seeds)...)
        isempty(set) && continue
        (set in sets) && continue
        cost = sum(elements_costs[i] for i in set)
        push!(sets, set)
        push!(base_costs, cost)
    end
    base_costs = round.(base_costs .* rand(args.set_cost_multiplier_dist, num_sets))

    # Extract some cover and make its content toll-free
    toll_free_cover = BitSet(1:num_toll_free)
    for i in shuffle(1:num_toll_free)
        new_cover = collect(setdiff(toll_free_cover, i))
        if union_sets(@view sets[new_cover]) == BitSet(1:num_elements)
            pop!(toll_free_cover, i)
        end
    end

    # Make some sets tolled sets, excluding the sets that are already marked toll-free
    tolled = sort!(shuffle(setdiff(1:num_sets, toll_free_cover))[1:num_tolled])
    # Make the tolled items more attractable
    base_costs[tolled] = round.(base_costs[tolled] / args.tolled_costs_multiplier) 
    base_costs = max.(base_costs, 1.)
    
    # Final shuffle
    inds = shuffle(1:num_sets)
    sets = sets[inds]
    base_costs = base_costs[inds]
    tolled = findall(∈(tolled), inds)

    return MinSetCoverPricing(num_elements, sets, base_costs, BitSet(tolled))
end

generate_mincover_pricing_random(num_sets::Int; kwargs...) =
    generate_mincover_pricing_random(num_sets::Int, MinSetCoverPricingGenArgs(; kwargs...))
