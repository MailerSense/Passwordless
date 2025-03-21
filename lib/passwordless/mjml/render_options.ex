defmodule Passwordless.MJML.RenderOptions do
  @moduledoc """
  Render options for MJML.
  """
  use TypedStruct

  typedstruct do
    field :keep_comments, boolean(), default: false
    field :social_icon_path, String.t(), default: nil
    field :fonts, map(), default: nil
  end
end
