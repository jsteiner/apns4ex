defmodule APNS.Callback do
  require Logger
  def error(%APNS.Error{error: error, message_id: message_id}) do
    Logger.error "[APNS] Error \"#{error}\" for message #{inspect message_id}"
  end
  def feedback(%APNS.Feedback{token: token}) do
    Logger.info "[APNS] Feedback received for token #{token}"
  end
end