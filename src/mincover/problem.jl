struct MinSetCoverPricing <: PricingProblem
    num_elements::Int
    sets::Vector{BitSet}
    base_costs::Vector{Float64}
    tolled::BitSet
end

# Interface
num_items(prob::MinSetCoverPricing) = length(prob.sets)
tolled(prob::MinSetCoverPricing) = prob.tolled
toll_free(prob::MinSetCoverPricing) = setdiff(BitSet(1:num_items(prob)), tolled(prob))
base_costs(prob::MinSetCoverPricing) = prob.base_costs

num_elements(prob::MinSetCoverPricing) = prob.num_elements

# Pretty print
function Base.show(io::IO, prob::MinSetCoverPricing)
    i1 = length(prob.tolled)
    nf = length(prob.sets)
    ne = prob.num_elements
    print(io, "$(typeof(prob)) with $ne elements, $nf sets ($i1 tolled)")
end

# Subproblem
function restrict(prob::MinSetCoverPricing, elements::Vector{Int})
    # `elements` defines the mapping of elements between the original and the subproblem
    subsets = [BitSet(findall(∈(s), elements)) for s in prob.sets]
    return MinSetCoverPricing(length(elements), subsets, prob.base_costs, prob.tolled)
end
