struct Partition <: AbstractVector{BitSet}
    parts::Vector{BitSet}
end

Base.size(p::Partition) = size(p.parts)
Base.getindex(p::Partition, i::Int) = getindex(p.parts, i)
Base.IndexStyle(p::Partition) = IndexStyle(p.parts)

abstract type AbstractPartitioning end

struct DefaultPartitioning <: AbstractPartitioning
    group_size::Int
end

function Partition(prob::PricingProblem, partitioning::DefaultPartitioning)
    n = num_items(prob)
    return Partition(BitSet.(Iterators.partition(1:n, partitioning.group_size)))
end

struct RandomPartitioning <: AbstractPartitioning
    group_size::Int
end

function Partition(prob::PricingProblem, partitioning::RandomPartitioning)
    n = num_items(prob)
    return Partition(BitSet.(Iterators.partition(shuffle(1:n), partitioning.group_size)))
end

struct TolledFirstPartitioning <: AbstractPartitioning
    group_size::Int
end

function Partition(prob::PricingProblem, partitioning::TolledFirstPartitioning)
    i1, i2 = collect(tolled(prob)), collect(toll_free(prob))
    return Partition(BitSet.(Iterators.partition(vcat(i1, i2), partitioning.group_size)))
end
