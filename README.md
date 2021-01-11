# OptimalVotes.jl

This is a tool for computing statistics (min, max, mean) over all possible 6x6 → 6 districting plans and all possible 1/3-2/3 voting patterns on the 6x6 grid.

## Usage
The districting plane enumeration file `enum.csv` is used by default. To run, invoke `julia enumerate.jl`

## Cluster usage
This tool is meant to be used on a compute cluster with a large number of cores. For instance, to run on a Slurm cluster with 380 cores, add
```
using Distributed, ClusterManagers
addprocs(SlurmManager(256), partition="batch", t="12:00:00", mem_per_cpu="1G")
```
to the header of `enumerate.jl`.
