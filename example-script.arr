import error-display as ED
import srcloc as S
import valueskeleton as VS

data Task:
  | task(prompt, predicate)
sharing:
  method render-fancy-reason(self):
    self.prompt
  end
end

data Choice:
  | yes
  | no
sharing:
  method _output(self):
    VS.vs-seq(empty)
  end
end

data Tree:
  | mt
  | node(
      value :: Number,
      left :: Tree,
      right :: Tree)
end


fun leaf(val):
  node(val, mt, mt)
end

var tasks =
  [list:
    task([ED.error:
        [ED.para:
          ED.text("Here's the data definition:")],
        ED.cmcode(S.srcloc("definitions://", 22, 0, 0, 28, 3, 0)),
        [ED.para:
          ED.text("Ready to begin? Enter yes or no.")]], is-yes),
    task([ED.error: [ED.para: ED.text("First, construct an empty tree.")]],
      _ == mt),
    task([ED.error: [ED.para: ED.text("Next, construct a tree made of a single node with value 5.")]],
      _ == node(5, mt, mt)),
    task([ED.error: [ED.para: ED.text("Next, construct a tree with root node 1, left child 2, and right child 3.")]],
      _ == node(1, node(2, mt, mt), node(3, mt, mt))),
    task([ED.error: [ED.para: ED.text("Is it possible to construct a tree with this definition with 5 as its root and 1, 2, and 3 as its direct children? Enter yes or no.")]],
      is-no),
    task([ED.error: ED.text("Congrats, you're done!")],
      lam(_): false end)
  ]

fun repl-hook(value) -> Task:
  cases(List) tasks:
    | link(t, rest) =>
      if (value <> nothing) and t.predicate(value) block:
        tasks := rest
        repl-hook(nothing)
      else:
        if (value <> nothing):
          task(ED.h-sequence(
              link(
                [ED.para: ED.text("Incorrect, try again:")],
                t.prompt.contents), " "), t.predicate)
        else:
          t
        end
      end
    | empty =>
      task([ED.error: ED.text("Seriously, you're done.")], lam(_): false end)
  end
end
