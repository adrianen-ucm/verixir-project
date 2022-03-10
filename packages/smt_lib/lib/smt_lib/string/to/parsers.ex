defmodule SmtLib.String.To.Parsers do
  import SmtLib.String.To.Helpers
  import NimbleParsec

  defparsec :general_response,
            skip_blanks_and_comments()
            |> choice([
              token(success()) |> eos(),
              token(unsupported()) |> eos(),
              token(error()) |> eos(),
              token(specific_success_response()) |> eos()
            ])
end
