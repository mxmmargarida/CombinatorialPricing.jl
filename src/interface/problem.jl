abstract type PricingProblem end

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
