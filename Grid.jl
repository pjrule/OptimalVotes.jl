module Grid
using DataStructures

struct GridEnsemble
    width::Int
    height::Int
    size::Int
    n_districts::Int
    district_pop::Int
    weights::AbstractArray{Int}
    plans::AbstractArray{Int, 2}
    n_plans::Int
end

"""Load enumerated plans from a @zschutzman-style CSV."""
function GridEnsemble(plans_file::AbstractString, width::Int, height::Int, n_districts::Int)
    n_plans = countlines(plans_file)
    plans = zeros(Int, n_plans, width * height)
    weights = ones(Int, n_plans)
    
    open(plans_file) do file
        for (plan_idx, plan) in enumerate(eachline(file))
            assignments = [parse(Int, a) for a in split(plan, ",")]
            @assert length(assignments) == width * height
            @simd for i in 1:length(assignments)
                plans[plan_idx, i] = assignments[i]
            end
        end
    end
    
    district_pop = Int((width * height) / n_districts)
    plan_size = width * height
    return GridEnsemble(width, height, plan_size, n_districts, district_pop,
                        weights, plans, size(plans, 1))
end

function unique_districts(ensemble::GridEnsemble)
    district_counts = DefaultDict{Tuple, Int}(0)
    for plan_idx in 1:ensemble.n_plans
        plan = ensemble.plans[plan_idx, :]
        districts = [[] for _ in 1:ensemble.n_districts]
        for (idx, node) in enumerate(plan)
            push!(districts[node], idx)
        end
        for dist in districts
            district_counts[tuple(sort(dist))] += 1
        end
    end
    return district_counts
end

const ensemble = GridEnsemble("enum.csv", 6, 6, 6)
const districts = unique_districts(ensemble)
const tie = Int(ensemble.district_pop / 2)
const win = tie + 1

function expected_seat_share(voters::Array{Int})
    binary_voters = zeros(Int, ensemble.size)
    for v in voters
        binary_voters[v] = 1
    end

    total_wins = 0
    for (dist, freq) in districts
        voters_in_dist = sum(binary_voters[dist[1]])
        if voters_in_dist == tie
            total_wins += 0.5 * freq
        elseif voters_in_dist >= win
            total_wins += freq
        end
    end
    total_wins / sum(values(districts))
end

function seat_hist(ensemble::GridEnsemble, voters::Array{Int})::AbstractDict
    binary_voters = zeros(Int, ensemble.size)
    for v in voters
        binary_voters[v] = 1
    end
    for r in eachrow(reshape(binary_voters, ensemble.width, ensemble.height)')
        println(r)
    end
    hist = DefaultDict{Float64, Int}(0)
    for i in 1:ensemble.n_plans
        binary_plan = zeros(Int, ensemble.n_districts, ensemble.size)
        for (j, assignment) in enumerate(ensemble.plans[i, :])
            binary_plan[assignment, j] = 1
        end
        counts = binary_plan * binary_voters
        wins = 0
        split = (ensemble.width * ensemble.height) / (ensemble.n_districts * 2)
        for c in counts
            if c == split
                wins += 0.5
            elseif c > split
                wins += 1
            end
        end
        if wins == 2
            println(ensemble.plans[i, :])
        end
        hist[wins] += 1
    end
    hist
end

export expected_seat_share, ensemble, districts, seat_hist

end
