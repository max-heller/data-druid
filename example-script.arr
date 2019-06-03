provide {repl-hook} end

data Task:
  | task(prompt, predicate)
end

var tasks =
  [list:
    task("Enter 1", _ == 1)
  ]

fun repl-hook(value) -> Nothing:
  _ = cases(List) tasks:
    | link(t, rest) =>
      if t.predicate(value) block:
        print("Nice job!")
        tasks := rest
      else:
        print(t.prompt)
      end
    | empty =>
      print("You're done!")
  end
  nothing
end

