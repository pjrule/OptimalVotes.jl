using Distributed
@everywhere using Combinatorics
@everywhere using Random
@everywhere include("./Grid.jl")
@everywhere using .Grid
@everywhere struct Extremes
    min_share::Float64
    max_share::Float64
    min_voters::Set{Array{Int}}
    max_voters::Set{Array{Int}}
    voters_hash::UInt64
end
include("./dedupe.jl")

const batch_size = 250000
const channel_size = 1
const n_voters = 12

@everywhere function eval_voter_dists(jobs, results)
    while true
        voter_dists = take!(jobs)
        max_share = 0
        min_share = 1
        max_voters = Set([])
        min_voters = Set([])
        v_hash = hash(Set(v for v in eachcol(voter_dists)))
        for i in 1:size(voter_dists, 2)
            voters = voter_dists[:, i]
            share = expected_seat_share(voters)
            if share > max_share
                max_share = share
                max_voters = Set([voters])
            elseif share == max_share
                push!(max_voters, voters)
            end
            if share < min_share
                min_share = share
                min_voters = Set([voters])
            elseif share == min_share
                push!(min_voters, voters)
            end
        end
        extremes = Extremes(min_share, max_share, min_voters, max_voters)#, v_hash)
        put!(results, extremes)
    end
end

function add_combos(jobs::RemoteChannel, meta::RemoteChannel, batch_size::Int, n_voters::Int)
    batch_count = 0
    batch_idx = 1
    batch = zeros(Int, n_voters, batch_size)
    for c in combinations(1:ensemble.size, n_voters)
        if !combo_duplicated(c, ensemble.width)
            batch[:, batch_idx] = c
            batch_idx += 1
            if batch_idx > batch_size
                put!(jobs, copy(batch))
                batch_idx = 1
                batch_count += 1 
            end
        end
    end
    # Handle remaining partial batch
    put!(jobs, copy(batch[:, 1:batch_idx - 1]))
    batch_count += 1
    put!(meta, batch_count)
end

function main()
    jobs = RemoteChannel(()->Channel{Array{Int, 2}}(channel_size))
    meta = RemoteChannel(()->Channel{Int}(1))
    results = RemoteChannel(()->Channel{Extremes}(channel_size))
    # Start workers.
    for p in workers()
        remote_do(eval_voter_dists, p, jobs, results)
    end

    max_share = 0
    min_share = 1
    max_voters = Set([])
    min_voters = Set([])
    @async add_combos(jobs, meta, batch_size, n_voters)
    i = 0
    n_batches = missing
    while true
        batch_extremes = take!(results)
        println("[batch ", i, "]")
        println("\tmin share: ", batch_extremes.min_share)
        println("\tmax share: ", batch_extremes.max_share)
        println("\tvoters hash: ", batch_extremes.voters_hash)
        println("\tmin voter dists:")
        for v in batch_extremes.min_voters
            println("\t\t", v)
        end
        println("\tmax voter dists:")
        for v in batch_extremes.max_voters
            println("\t\t", v)
        end

        if batch_extremes.min_share < min_share
            min_share = batch_extremes.min_share
            min_voters = batch_extremes.min_voters
        elseif batch_extremes.min_share == min_share
            min_voters = union(min_voters, batch_extremes.min_voters)
        end
        if batch_extremes.max_share > max_share
            max_share = batch_extremes.max_share
            max_voters = batch_extremes.max_voters
        elseif batch_extremes.max_share == max_share
            max_voters = union(max_voters, batch_extremes.max_voters)
        end
        i += 1
       if isready(meta)
            n_batches = take!(meta)
            println("got number of batches: ", n_batches)
        end
        if !ismissing(n_batches) && n_batches == i
            break  # done!
        end
    end
    println("min share: ", min_share)
    println("max share: ", max_share)
    println("min voter dists:")
    for v in min_voters
        println(v)
    end
    println("max voter dists:")
    for v in max_voters
        println(v)
    end

    # Kill workers.
    for wid in workers()
        if wid != 1
            rmprocs(wid)
        end
    end
end

main()
