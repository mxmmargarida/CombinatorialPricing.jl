struct Partition <: AbstractVector{BitSet}
    parts::Vector{BitSet}
end

Base.size(p::Partition) = size(p.parts)
Base.getindex(p::Partition, i::Int) = getindex(p.parts, i)
Base.IndexStyle(p::Partition) = IndexStyle(p.parts)

abstract type AbstractPartitioning end

# Group items based on the default order (1:n)
struct DefaultPartitioning <: AbstractPartitioning
    group_size::Int
end

function Partition(prob::AbstractProblem, partitioning::DefaultPartitioning)
    n = num_items(prob)
    return Partition(BitSet.(Iterators.partition(1:n, partitioning.group_size)))
end

# Group items based on a random order (shuffle(1:n))
struct RandomPartitioning <: AbstractPartitioning
    group_size::Int
    rng::AbstractRNG
end

RandomPartitioning(group_size::Int) = RandomPartitioning(group_size, Random.default_rng())

function Partition(prob::AbstractProblem, partitioning::RandomPartitioning)
    n = num_items(prob)
    return Partition(BitSet.(Iterators.partition(shuffle(partitioning.rng, 1:n), partitioning.group_size)))
end

# Group items based on the default order, but with all the tolled items at the start and toll-free at the end
struct TolledFirstPartitioning <: AbstractPartitioning
    group_size::Int
end

function Partition(prob::PricingProblem, partitioning::TolledFirstPartitioning)
    i1, i2 = collect(tolled(prob)), collect(toll_free(prob))
    return Partition(BitSet.(Iterators.partition(vcat(i1, i2), partitioning.group_size)))
end
