defmodule APISex.Utils do

  # see https://tools.ietf.org/html/rfc7230#section-3.2.6
  def rfc7230_quotedstring_regex do
    ~r{^([\v\s\x21\x23-\x5B\x5D-\x7E\x80-\xFF]|\\\v|\\\s|\\[\x21-\x7E]|\\[\x80-\xFF])*$}
  end

  def rfc7230_token_regex do
    ~r{^[!#$%&'*+\-.\^_`|~0-9A-Za-z]*$}
  end
end
