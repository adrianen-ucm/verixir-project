locals_without_parens = [
  requires: 1,
  ensures: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{examples,lib,test}/**/*.{ex,exs}"],
  import_deps: [:boogiex],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
