defmodule Bench do
  def run() do
    horde_ids = Dist.ItemsManager.get_ids(:horde)
    syn_ids = Dist.ItemsManager.get_ids(:syn)
    pg_ids = Dist.ItemsManager.get_ids(:pg)

    Benchee.run(%{
      "syn" => fn -> Enum.each(syn_ids, fn id -> Dist.ItemSyn.hello(id) end) end,
      "horde" => fn -> Enum.each(horde_ids, fn id -> Dist.ItemHorde.hello(id) end) end,
      "pg" => fn -> Enum.each(pg_ids, fn id -> Dist.ItemPg.hello(id) end) end
    })
  end
end
