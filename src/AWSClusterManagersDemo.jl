using AWSClusterManagers: AWSBatchManager
using Distributed

const NUM_WORKERS = 4

# Must start workers before any @everywhere for them to be available on the workers
addprocs(AWSBatchManager(NUM_WORKERS))

@everywhere function throw_darts()
    MAX_THROW = 250_000
    dart_count = Integer(floor(rand() * MAX_THROW))
    hits = 0

    for _ in 1:dart_count
        x = rand()
        y = rand()

        if ((x*x) + (y*y) < 1)
            hits += 1
        end
    end

    return hits, dart_count
end

calc_approx_pi(hits::Integer, thrown::Integer) = 4 * hits / thrown

function main()
    total_hits = 0
    total_throws = 0

    for worker in workers()
        hits, throws = remotecall_fetch(throw_darts, worker)
        percentile = (hits / throws)

        println("Worker $(worker) landed $(hits) of $(throws), ($(percentile)%)!")
        total_hits += hits
        total_throws += throws
    end

    approx_pi = calc_approx_pi(total_hits, total_throws)
    println("$(NUM_WORKERS) workers threw a total of $(total_throws) darts.")
    println("They calculated PI to be approximately,\n$(approx_pi)")
end
