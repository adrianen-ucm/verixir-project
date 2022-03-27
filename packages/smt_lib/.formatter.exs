locals_without_parens = [
  assert: 1,
  push: 0,
  push: 1,
  pop: 0,
  pop: 1,
  declare_const: 1,
  declare_sort: 1,
  declare_fun: 1,
  define_fun: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{examples,lib,test}/**/*.{ex,exs}"],
  import_deps: [:nimble_parsec],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
