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

Start creating Items with `Dist.ItemsManager.new`

You can then kill an open `iex` and Add a new item to the other node to see every other persisted in the other node's `ItemsManager` state

This will distribute the current state evenly across all other nodes and recreate its children for every node that received the new items

You can call `Dist.ItemsManager.hello(item_id)` passing a generated id from new to see a message from Item GenServer process telling which node is currently responding
