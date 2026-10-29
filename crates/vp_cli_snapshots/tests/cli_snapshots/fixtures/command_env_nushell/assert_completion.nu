# Nushell 0.116 deprecates a positional completer input such as `context` (#3127).
# Nushell writes the warning to stderr, so complete in a child process.
let lines = [
  "vp en",
  "ls | vp en",
  "echo \"it's okay\" | vp en",
  "vpr ",
  "ls | vpr ",
  "do {\n  let x = 1\n  vpr ",
]
let script = $"source env.nu
($lines | to nuon) | each {|line| $line | commandline complete } | to json --raw"
let result = ^$nu.current-exe -n -c $script | complete
if $result.exit_code != 0 {
  error make { msg: $"completion failed: ($result.stderr)" }
}
if ($result.stderr | str contains "deprecated") {
  error make { msg: $"completion printed a deprecation warning: ($result.stderr)" }
}

let completions = $result.stdout | from json
for index in [0 1 2] {
  let values = $completions | get $index | each {|value| $value | str trim }
  if "env" not-in $values {
    error make { msg: $"`($lines | get $index)` did not complete `env`, got: ($values)" }
  }
}

# `buffer` includes the earlier commands. Without the `vpr` translation, fish completes file names.
for index in [4 5] {
  if ($completions | get $index) != ($completions | get 3) {
    error make { msg: $"`($lines | get $index)` completed differently from `vpr `, got: ($completions | get $index)" }
  }
}

print "Nushell completer checks passed"
