defmodule SmtLib.String.To.Helpers do
  alias SmtLib.Syntax, as: S
  import NimbleParsec

  @spec blank_char() :: NimbleParsec.t()
  def blank_char do
    ascii_char([?\s, ?\t, ?\r, ?\n])
  end

  @spec comment() :: NimbleParsec.t()
  def comment do
    ignore(ascii_char([?;]))
    |> utf8_string(
      [{:not, ?\r}, {:not, ?\n}],
      min: 0
    )
  end

  @spec skip_blanks_and_comments() :: NimbleParsec.t()
  def skip_blanks_and_comments do
    choice([
      blank_char(),
      comment()
    ])
    |> times(min: 0)
    |> ignore()
  end

  @spec token(NimbleParsec.t()) :: NimbleParsec.t()
  def token(parser) do
    concat(parser, skip_blanks_and_comments())
  end

  @spec string_literal() :: NimbleParsec.t()
  def string_literal do
    ignore(ascii_char([?"]))
    |> utf8_string(
      [{:not, ?"}],
      min: 0
    )
    |> ignore(ascii_char([?"]))
  end

  @spec success() :: NimbleParsec.t()
  def success do
    choice([
      string("success"),
      string("")
    ])
    |> map({__MODULE__, :to_success, []})
  end

  @spec unsupported() :: NimbleParsec.t()
  def unsupported do
    string("unsupported")
    |> map({__MODULE__, :to_unsupported, []})
  end

  @spec error :: NimbleParsec.t()
  def error do
    ignore(ascii_char([?(]))
    |> ignore(token(string("error")))
    |> concat(token(string_literal()))
    |> ignore(ascii_char([?)]))
    |> map({__MODULE__, :to_error, []})
  end

  @spec check_sat_response() :: NimbleParsec.t()
  def check_sat_response do
    choice([
      string("sat"),
      string("unsat"),
      string("unknown")
    ])
    |> map({__MODULE__, :to_check_sat_response, []})
  end

  @spec specific_success_response() :: NimbleParsec.t()
  def specific_success_response do
    check_sat_response()
    |> map({__MODULE__, :to_specific_success_response, []})
  end

  @spec to_success(String.t()) :: :success
  def to_success("success") do
    :success
  end

  def to_success("") do
    :success
  end

  @spec to_unsupported(String.t()) :: :unsupported
  def to_unsupported("unsupported") do
    :unsupported
  end

  @spec to_error(String.t()) :: {:error, String.t()}
  def to_error(msg) do
    {:error, msg}
  end

  @spec to_check_sat_response(String.t()) :: S.specific_success_response_t()
  def to_check_sat_response("sat") do
    {:check_sat_response, :sat}
  end

  def to_check_sat_response("unsat") do
    {:check_sat_response, :unsat}
  end

  def to_check_sat_response("unknown") do
    {:check_sat_response, :unknown}
  end

  @spec to_specific_success_response(S.specific_success_response_t()) ::
          S.general_response_t()
  def to_specific_success_response(response) do
    {:specific_success_response, response}
  end
end
