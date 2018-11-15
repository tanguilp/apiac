defmodule APIsexTest do
  use ExUnit.Case
  use Plug.Test

  test "Connection is authenticated" do
    conn =
      conn(:get, "/")
      |> put_private(:apisex_authenticator, APISexAuthBasic)

    assert APISex.authenticated?(conn) == true
  end

  test "Connection is not authenticated" do
    conn =
      conn(:get, "/")
      |> put_private(:apisex_client, "client_id")

    assert APISex.authenticated?(conn) == false
  end

  test "Connection is machine to machine" do
    conn =
      conn(:get, "/")
      |> put_private(:apisex_client, "client_id")

    assert APISex.machine_to_machine?(conn) == true
  end

  test "Connection is not machine to machine" do
    conn =
      conn(:get, "/")
      |> put_private(:apisex_client, "client_id")
      |> put_private(:apisex_subject, "user@example.com")

    assert APISex.machine_to_machine?(conn) == false
  end

  test "WWW-Authenticate header set - one scheme" do
    conn =
      conn(:get, "/")
      |> APISex.set_WWWauthenticate_challenge(
        "Bearer",
        %{
          "realm" => "My realm",
          "additionalparam" => "additional value"
        }
      )

    assert Plug.Conn.get_resp_header(conn, "www-authenticate") in [
             ["Bearer realm=\"My realm\", additionalparam=\"additional value\""],
             ["Bearer additionalparam=\"additional value\", realm=\"My realm\""]
           ]
  end

  test "WWW-Authenticate header set - two scheme" do
    conn =
      conn(:get, "/")
      |> APISex.set_WWWauthenticate_challenge("Basic", %{"realm" => "basic realm"})
      |> APISex.set_WWWauthenticate_challenge(
        "Bearer",
        %{
          "realm" => "My realm",
          "error" => "insufficient_scope",
          "scope" => "group:read group:write"
        }
      )

    assert Plug.Conn.get_resp_header(conn, "www-authenticate") in [
             [
               "Basic realm=\"basic realm\", Bearer realm=\"My realm\", error=\"insufficient_scope\", scope=\"group:read group:write\""
             ],
             [
               "Basic realm=\"basic realm\", Bearer realm=\"My realm\", scope=\"group:read group:write\", error=\"insufficient_scope\""
             ],
             [
               "Basic realm=\"basic realm\", Bearer scope=\"group:read group:write\", realm=\"My realm\", error=\"insufficient_scope\""
             ],
             [
               "Basic realm=\"basic realm\", Bearer scope=\"group:read group:write\", error=\"insufficient_scope\", realm=\"My realm\""
             ],
             [
               "Basic realm=\"basic realm\", Bearer error=\"insufficient_scope\", scope=\"group:read group:write\", realm=\"My realm\""
             ],
             [
               "Basic realm=\"basic realm\", Bearer error=\"insufficient_scope\", realm=\"My realm\", scope=\"group:read group:write\""
             ]
           ]
  end

  test "WWW-Authenticate wrong param encoding raises exception" do
    conn = conn(:get, "/")

    assert_raise RuntimeError, fn ->
      APISex.set_WWWauthenticate_challenge(conn, "Basic", %{"realm" => "basic\"realm"})
    end
  end

  test "RFC 7230 quoted string" do
    assert APISex.rfc7230_quotedstring?("\"Realm 1\"")
    assert APISex.rfc7230_quotedstring?("\"Realm\\ 1\"")
    assert APISex.rfc7230_quotedstring?("\"Re\\alm 1\"")
    assert APISex.rfc7230_quotedstring?("\"Re\\\valm 1\"")

    refute APISex.rfc7230_quotedstring?("Realm 1")
    refute APISex.rfc7230_quotedstring?("\"Rea\x11lm 1\"")
    refute APISex.rfc7230_quotedstring?("\"Rea\"lm 1\"")
    refute APISex.rfc7230_quotedstring?("\"Rea\x7Flm 1\"")
  end

  test "RFC 7230 token" do
    assert APISex.rfc7230_token?("!#$%&'*+-.^_`|~")
    assert APISex.rfc7230_token?("abcABCmno0123457689MNOxyzXYZ")
    assert APISex.rfc7230_token?("abcABCmn%&'*+-.^_o0123457689MNOxyzXYZ")

    refute APISex.rfc7230_token?("abcABCmno 0123457689MNOxyzXYZ")
    refute APISex.rfc7230_token?("abcABCmno\\0123457689MNOxyzXYZ")
    refute APISex.rfc7230_token?("abcABCmno\"0123457689MNOxyzXYZ")
  end

  test "RFC 7235 token68" do
    assert APISex.rfc7235_token68?("dscwdx==")
    assert APISex.rfc7235_token68?("-._~+/")

    refute APISex.rfc7235_token68?("a<zfeaw")
    refute APISex.rfc7235_token68?("azf eaw")
    refute APISex.rfc7235_token68?("azf#eaw")
    refute APISex.rfc7235_token68?("Noël")
  end
end
