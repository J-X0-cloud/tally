defmodule TallyWeb.ErrorJSON do
  @moduledoc """
  Renders errors raised while handling a request (unmatched routes, crashes) as JSON in the same
  shape the controllers use: `{"error": code, "message": text}`.
  """

  def render(template, _assigns) do
    status = template |> String.split(".") |> hd()

    %{
      error: status |> Phoenix.Controller.status_message_from_template() |> code(),
      message: Phoenix.Controller.status_message_from_template(template)
    }
  end

  defp code(message), do: message |> String.downcase() |> String.replace(~r/[^a-z]+/, "_")
end
