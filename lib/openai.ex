defmodule OpenAI do
  @moduledoc """
  A module to interact with the OpenAI API.
  """
  use Tesla

  require Logger

  plug Tesla.Middleware.BaseUrl, "https://api.openai.com/v1"

  plug Tesla.Middleware.Headers, [
    {"Authorization", "Bearer #{System.get_env("OPEN_AI_KEY")}"}
  ]

  plug Tesla.Middleware.JSON

  def complete(system_prompt, prompts) do
    request = %{
      model: "gpt-4o-mini",
      messages:
        Enum.concat(
          [
            %{role: "system", content: system_prompt}
          ],
          prompts
        ),
      temperature: 0.7
    }

    case post("/chat/completions", request) do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: %{
           "choices" => [
             %{
               "message" => %{
                 "content" => content
               }
             }
           ]
         }
       }} ->
        Jason.decode!(content)

      _ ->
        nil
    end
  end

  def translator_prompt do
    """
    You are a translator helping developers translate their internal identifiers to human readable English text.
    Translate each key to English using passive voice in past tense, like so:

    contact.create -> Contact created
    message.submit -> Message submitted
    sendout.start -> Sendout started

    Your response should be in format:
    {
      "contacts.create": "Contact created",
      "message.submit": "Message submitted",
      "sendout.start": "Sendout started"
    }
    """
  end
end
