# Elixir Distributed Test

This test uses `Erlang PG` to act as a "registry" for GenServer and communicate between nodes.

More info about `PG` can be found at: https://erlang.org/doc/man/pg.html

## Run two or more terminals using

> iex --sname n1 -S mix

> iex --sname n2 -S mix

Inside iex, connect nodes using `Node.connect(:"n1@whatever_generated_name")`

Start creating Items with `Dist.ItemsManager.new`

You can then kill an open `iex` and Add a new item to the other node to see every other persisted in the other node's `ItemsManager` state

This will distribute the current state evenly across all other nodes and recreate its children for every node that received the new items

You can call `Dist.ItemsManager.hello(item_id)` passing a generated id from new to see a message from Item GenServer process telling which node is currently responding
