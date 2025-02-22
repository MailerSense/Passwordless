defmodule PasswordlessWeb.PetalFrameworkTranslations do
  @moduledoc """
  Petal Framework components like data_table sometimes have text in them that need translations.
  You can edit the translations for these here.
  """
  use Gettext, backend: PasswordlessWeb.Gettext

  def translate("Showing"), do: gettext("Showing")
  def translate("to"), do: gettext("to")
  def translate("of"), do: gettext("of")
  def translate("rows"), do: gettext("rows")
  def translate("Equals"), do: gettext("Equals")
  def translate("Not equal"), do: gettext("Not equal")
  def translate("Search (case insensitive)"), do: gettext("Search (case insensitive)")
  def translate("Is empty"), do: gettext("Is empty")
  def translate("Not empty"), do: gettext("Not empty")
  def translate("Less than or equals"), do: gettext("Less than or equals")
  def translate("Less than"), do: gettext("Less than")
  def translate("Greater than or equals"), do: gettext("Greater than or equals")
  def translate("Greater than"), do: gettext("Greater than")
  def translate("Search in"), do: gettext("Search in")
  def translate("Contains"), do: gettext("Contains")
  def translate("Search (case sensitive)"), do: gettext("Search (case sensitive)")
  def translate("Search (case sensitive) (and)"), do: gettext("Search (case sensitive) (and)")
  def translate("Search (case sensitive) (or)"), do: gettext("Search (case sensitive) (or)")
  def translate("Search (case insensitive) (and)"), do: gettext("Search (case insensitive) (and)")
  def translate("Search (case insensitive) (or)"), do: gettext("Search (case insensitive) (or)")
end
