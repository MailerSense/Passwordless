defmodule PasswordlessWeb.EmailTestingHTML do
  use PasswordlessWeb, :html

  embed_templates "email_testing_html/*"

  def menu_item_classes(is_active) do
    active_classes =
      if is_active do
        "bg-slate-200 text-slate-900 dark:bg-slate-800 dark:text-slate-100"
      else
        "text-slate-600 hover:bg-slate-200 hover:text-slate-900 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-200"
      end

    active_classes <>
      " " <> "flex items-center px-2 py-2 text-sm font-medium rounded-lg group"
  end
end
