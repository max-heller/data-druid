provide {repl-hook} end
import error-display as ED


data Task:
  | task(prompt, predicate)
sharing:
  method render-fancy-reason(self):
    self.prompt
  end
end

var tasks =
  [list:
    task([ED.error: ED.text("Please enter 1")], _ == 1),
    task([ED.error: ED.text("You're finished!")], lam(_): true end)
  ]

fun repl-hook(value) -> Task:
  cases(List) tasks:
    | link(t, rest) =>
      if (value <> nothing) and t.predicate(value) block:
        tasks := rest
        repl-hook(nothing)
      else:
        t
      end
    | empty =>
      task([ED.error: ED.text("Seriously, you're done.")], lam(_): false end)
  end
end
