locals_without_parens = [
  with_env: 1,
  havoc: 1,
  assume: 1,
  assert: 1,
  assert: 2,
  block: 1,
  same: 2,
  unfold: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{examples,lib,test}/**/*.{ex,exs}"],
  import_deps: [:smt_lib],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
