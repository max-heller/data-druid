import error-display as ED
import srcloc as S
import valueskeleton as VS

data Task:
  | task(prompt :: ED.ErrorDisplay, predicate :: (Any -> Boolean))
  | annotated(feedback :: ED.ErrorDisplay, task :: Task%(is-task))
sharing:
  method render-fancy-reason(self):
    cases(Task) self:
      | task(prompt, _) => prompt
      | annotated(feedback, t) =>
        ED.h-sequence(link(
            feedback,
            t.prompt.contents), " ")
    end
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
          ED.text("Welcome to the Data Druid demo! Here's a data definition for a binary tree:")],
        ED.cmcode(S.srcloc("definitions://", 29, 0, 0, 35, 3, 0)),
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
    task([ED.error: [ED.para: ED.text("Congrats, you're done!")]],
      lam(_): false end)
  ]

fun repl-hook(value) -> Task:
  cases(List) tasks:
    | link(t, rest) =>
      base = cases(Task) t:
        | task(_, _) => t
        | annotated(_, base) => base
      end
      if (value <> nothing) and base.predicate(value) block:
        tasks := rest
        tasks := cases(List) tasks:
          | link(next, rr) =>
            link(annotated([ED.para: ED.text("Good job!")], next), rr)
          | empty => tasks
        end
        tasks.first
      else if (value <> nothing):
        annotated([ED.para: ED.text("Incorrect, try again:")], base)
      else:
        base
      end
    | empty =>
      task([ED.error: ED.text("Seriously, you're done.")], lam(_): false end)
  end
end
