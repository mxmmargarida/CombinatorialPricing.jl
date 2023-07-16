abstract type AbstractSampler end

function Base.rand(sampler::AbstractSampler, count::Int)
    return [rand(sampler) for _ in 1:count]
end
