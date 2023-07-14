"""
The supertype of all pricing problems.
"""
abstract type PricingProblem end

## Interface
"""
    num_items(prob::PricingProblem) -> Int

Get the total number of items selectable by the followers (including tolled and toll-free items).

All items are indexed by the range `1:num_items(prob)`.
"""
function num_items end

"""
    tolled(prob::PricingProblem) -> BitSet

Get the set of tolled items.
"""
function tolled end

"""
    toll_free(prob::PricingProblem) -> BitSet

Get the set of toll-free items.
"""
function toll_free end

"""
    base_values(prob::PricingProblem)::Vector{Int}

Get the base values of all selectable items.
These are the actual values of the toll-free items.
The actual value of a tolled item is the sum of its base value and its toll price.
"""
function base_values end

"""
    generate(type::Type{<:PricingProblem}, num_items::Int; kwargs...)

Generate a random pricing problem of the given `type` with `num_items` selectable items.
"""
function generate end

## Write to file
function Base.write(filename::AbstractString, prob::PricingProblem)
    open(filename, "w") do f
        JSON.print(f, Dict(:problem => prob))
    end
end

## Read from file
function Base.read(filename::AbstractString, P::Type{<:PricingProblem})
    str = read(filename, String)
    return unmarshal(P, JSON.parse(str)["problem"])
end
