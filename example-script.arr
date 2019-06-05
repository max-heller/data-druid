import error-display as ED
import srcloc as S
import valueskeleton as VS

# Assignment-specific definitions

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

#################################

data Task:
  | task(
      prompt :: ED.ErrorDisplay,
      predicate :: (Any -> Boolean))
end

data Annotated:
  | annotated-task(
      feedback :: ED.ErrorDisplay,
      t :: Task)
sharing:
  method render-fancy-reason(self):
    ED.h-sequence(link(
        self.feedback,
        self.t.prompt.contents), " ")
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

var tasks =
  [list:
    task([ED.error:
        [ED.para:
          ED.text("Welcome to the Data Druid demo! Here's a data definition for a binary tree:")],
        [ED.para: ED.optional(ED.cmcode(S.srcloc("definitions://", 7, 0, 0, 13, 3, 0)))],
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

var feedback = ""

fun get-current-task() -> Annotated block:
  current-feedback = feedback
  feedback := "Incorrect, try again:"
  annotated-task([ED.para: ED.text(current-feedback)],
    task(tasks.first.prompt, tasks.first.predicate))
end

fun repl-hook(value):
  cases(List) tasks:
    | link(t, rest) =>
      feedback := ask block:
        | value == nothing then: ""
        | t.predicate(value) then:
          tasks := rest
          "Good job!"
        | otherwise: "Incorrect, try again:"
      end
    | empty => raise("Found end of task list. Should not have occured.")
  end
end
