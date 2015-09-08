defmodule APNSTest do
  use ExUnit.Case
  require Logger
  doctest APNS

  @payload_min_size 38

  test "APNS start/stop for :dev and :prod env works correctly"do
    for env <- [:dev, :prod] do
      {:ok, pid} = APNS.start(env)
      assert Process.alive? pid
      :ok = APNS.stop(pid)
      refute Process.alive? pid
    end
  end

  test "If PN exceeds length of 256 bytes, it still builds proper payload by truncating alert message" do
    msg = %APNS.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:alert, String.duplicate("lorem ipsum", 100))
    payload = APNS.Connection.Worker.build_payload(msg)
    assert byte_size(payload) == 256
    assert payload =~ "…"
  end

  test "PN with UTF8-characters is properly truncated" do
    msg = %APNS.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:alert, String.duplicate("ありがとう", 30))
    payload = APNS.Connection.Worker.build_payload(msg)
    # When truncating UTF8 chars, payload size may be less than 256
    assert byte_size(payload) <= 256
    assert payload =~ "…"
  end

  test "If PN length is less than 256, it is not truncated" do
    string = "lorem ipsum"
    msg = %APNS.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:alert, string)
    payload = APNS.Connection.Worker.build_payload(msg)
    assert byte_size(payload) == @payload_min_size + byte_size(string)
    refute payload =~ "…"
  end

  test "Ellipsis absent when message size is exactly 256 bytes" do
    string = String.duplicate("a", 256 - @payload_min_size)
    msg = %APNS.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:alert, string)
    payload = APNS.Connection.Worker.build_payload(msg)
    assert byte_size(payload) == @payload_min_size + byte_size(string)
    refute payload =~ "…"
  end

  test "Payload can be built for any characters" do
    string = "test123 тест テスト !@#$%"
    msg = %APNS.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:alert, string)
    payload = APNS.Connection.Worker.build_payload(msg)
    assert byte_size(payload) == @payload_min_size + byte_size(string)
    refute payload =~ "…"
  end
end
