defmodule TallyWeb.Presence do
  @moduledoc """
  Tracks who is watching a site's live view, so the dashboard can show "3 teammates watching".
  Viewers are tracked by their socket id on the site's live topic; nothing about visitors goes here.
  """
  use Phoenix.Presence,
    otp_app: :tally,
    pubsub_server: Tally.PubSub
end
