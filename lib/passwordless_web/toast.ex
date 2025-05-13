defmodule PasswordlessWeb.Toast do
  @moduledoc false
  def toast_class_fn(assigns) do
    [
      # base classes
      "group/toast z-100 pointer-events-auto relative w-full items-center justify-between origin-center overflow-hidden rounded-lg p-6 shadow-3 border border-gray-200 dark:border-gray-700 col-start-1 col-end-1 row-start-1 row-end-2",
      # start hidden if javascript is enabled
      "[@media(scripting:enabled)]:opacity-0 [@media(scripting:enabled){[data-phx-main]_&}]:opacity-100",
      # used to hide the disconnected flashes
      if(assigns[:rest][:hidden], do: "hidden", else: "flex"),
      # override styles per severity
      assigns[:kind] == :info && "bg-white text-black dark:bg-gray-600 dark:text-white",
      assigns[:kind] == :error &&
        "text-red-700! bg-red-100! dark:bg-red-700! dark:text-white!"
    ]
  end
end
