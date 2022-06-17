locals_without_parens = [
  with_env: 1,
  with_env: 2,
  with_local_env: 1,
  with_local_env: 2,
  havoc: 1,
  havoc: 2,
  assume: 1,
  assume: 2,
  assume: 3,
  assert: 1,
  assert: 2,
  assert: 3,
  block: 1,
  block: 2,
  unfold: 1,
  unfold: 2,
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
