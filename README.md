# Elixir Distributed Test

This test uses `Erlang PG` to act as a "registry" for GenServer and communicate between nodes.

More info about `PG` can be found at: https://erlang.org/doc/man/pg.html

## Install dependencies

```sh
$> mix deps.get
```

## Run two or more terminals using

```sh
$> iex --name n1@127.0.0.1 -S mix

$> iex --name n2@127.0.0.1 -S mix
```

`libcluster` will connect those nodes automatically

## OR Dinamically create a slave node through:

```elixir
Dist.SlaveNode.spawn()
```

Start creating Items with `Dist.ItemsManager.new`

You can then kill an open `iex` and Add a new item to the other node to see every other persisted in the other node's `ItemsManager` state

This will distribute the current state evenly across all other nodes and recreate its children for every node that received the new items

You can generate childs using `Dist.ItemsManager.new 10`, this will generate 10 processes using syn, pg and horde as distributed registry  

You can then call the processes calling a generated id and the module corresponding what you want, example: `Dist.ItemPg.hello 512951` Assuming it was previously created a process with id `512951`

----

### You can run Dynamic Node processing with

```elixir
{:ok, node} = Dist.SlaveNode.spawn 4
Dist.SlaveNode.observe node
Dist.SlaveNode.heavy node, 100_000_000
```

This will:
- spawn a slave node with 4 cpus available.
- start observer, then in "Load charts tab" you can see the CPU usage with active schedulers
- And then it will use Flow to compute an Enum using the available schedulers


## Benchmark results (Using benchee)

### DYNAMIC ITEM 10000 calls each (horde 0.7) - Calling from the same node

```
Name                ips        average  deviation         median         99th %
new_horde         25.07       39.89 ms    ±11.24%       38.75 ms       58.90 ms
new_pg            24.63       40.61 ms    ±25.42%       37.66 ms       85.42 ms
new_syn           15.60       64.11 ms    ±10.42%       63.01 ms      105.05 ms

Comparison: 
new_horde         25.07
new_pg            24.63 - 1.02x slower +0.72 ms
new_syn           15.60 - 1.61x slower +24.22 ms
```

### DYNAMIC ITEM 50000 calls each (horde 0.7) - Calling from another node

```
Name                ips        average  deviation         median         99th %
new_pg             6.11      163.74 ms    ±19.03%      158.02 ms      306.64 ms
new_horde          4.04      247.66 ms    ±21.48%      218.72 ms      376.29 ms
new_syn            2.78      360.36 ms     ±9.78%      354.04 ms      465.05 ms

Comparison: 
new_pg             6.11
new_horde          4.04 - 1.51x slower +83.92 ms
new_syn            2.78 - 2.20x slower +196.62 ms
```

### DYNAMIC ITEM 100000 calls each (horde 0.8x) - Calling from another node

```
Benchmarking horde...
Benchmarking pg...
Benchmarking syn...

Name            ips        average  deviation         median         99th %
pg            0.192         5.20 s     ±8.09%         5.20 s         5.50 s
horde         0.172         5.83 s     ±0.00%         5.83 s         5.83 s
syn           0.172         5.83 s     ±0.00%         5.83 s         5.83 s

Comparison: 
pg            0.192
horde         0.172 - 1.12x slower +0.63 s
syn           0.172 - 1.12x slower +0.63 s
```

using only `:pg` is slightly faster than `Horde` and `Syn` Dynamic Registries
