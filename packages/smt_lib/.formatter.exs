locals_without_parens = [
  assert: 1,
  assert: 2,
  push: 0,
  push: 1,
  push: 2,
  pop: 0,
  pop: 1,
  pop: 2,
  declare_const: 1,
  declare_const: 2,
  declare_sort: 1,
  declare_sort: 2,
  declare_fun: 1,
  declare_fun: 2,
  define_fun: 1,
  define_fun: 2
]

locals_without_parens_example_3 = [
  eval: 2,
  declare_const: 1,
  when_unsat: 3,
  local: 1,
  add: 1,
  skip: 1,
  fail: 0
]

[
  inputs: ["{mix,.formatter}.exs", "{examples,lib,test}/**/*.{ex,exs}"],
  import_deps: [:nimble_parsec],
  locals_without_parens: locals_without_parens ++ locals_without_parens_example_3,
  export: [locals_without_parens: locals_without_parens]
]
