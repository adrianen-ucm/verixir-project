locals_without_parens = [
  with_env: 1,
  havoc: 1,
  assume: 1,
  assume: 2,
  assert: 1,
  assert: 2,
  block: 1,
  unfold: 1,
  fail: 1,
  add: 1,
  local: 1,
  context: 2,
  declare_const: 1,
  when_unsat: 2
]

[
  inputs: ["{mix,.formatter}.exs", "{examples,lib,test}/**/*.{ex,exs}"],
  import_deps: [:smt_lib],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
