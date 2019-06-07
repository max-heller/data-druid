import error-display as ED
import srcloc as S
import valueskeleton as VS

## MOVE?

## CHOICE (FOR STUDENT RESPONSES)

data Choice:
  | yes
  | no
sharing:
  method _output(self):
    VS.vs-seq(empty)
  end
end

impossible = no


# Instructor-Provided Definitions
# (This will be moved to a new file)

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

# separate lines using '\n'
task-list :: List<{String; (Any -> Boolean)}> = [list:
  {"First, construct an empty tree."; _ == mt},
  {"Next, construct a tree made of a single node with value 5.";
    _ == node(5, mt, mt)},
  {"Next, construct a tree with root node 1, left child 2, and right child 3.";
    _ == node(1, node(2, mt, mt), node(3, mt, mt))},
  {"Is it possible to construct a tree with this definition with 5 as its root and 1, 2, and 3 as its direct children? Enter yes or no.";
    is-no},
]

opening-prompt = "Welcome to the Data Druid demo! Here's a data definition for a binary tree:"
closing-prompt = "Congrats!"

# for definition window
defn-start = 24
defn-char-start = 0
defn-end = 30
defn-char-end = 3

#################################


################## DEFINITIONS

## TASK

newtype Task as TaskT
is-Task = TaskT.test

task :: (ED.ErrorDisplay, (Any -> Boolean) -> Task) = block:
  var next-task-id = 1
  lam(prompt, predicate) block:
    task-id = next-task-id
    next-task-id := next-task-id + 1
    TaskT.brand({
        id: task-id,
        prompt: prompt,
        predicate: predicate
      })
  end
end


## ANNOTATED TASK (TASK W/ FEEBACK)

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

## ATTEMPT RESULT

data Attempt:
  | correct
  | neutral
  | incorrect
  | pyret-error
end

################## FUNCTIONS

fun feedback(attempt :: Attempt) -> ED.ErrorDisplay:
  cases(Attempt) attempt:
    | correct => [ED.para: ED.text("Good job!")]
    | neutral => [ED.para: ]
    | incorrect => [ED.para: ED.text("Incorrect, try again:")]
    | pyret-error => [ED.para: ED.text("Encountered Pyret error(s), try again:")]
  end
end

instructor-defn = 
  ED.cmcode(S.srcloc("definitions://", defn-start, defn-char-start, 0, defn-end, defn-char-end, 0))

fun get-task-list(items :: List<{String; (Any -> Boolean)}>) -> List<Task>:
  doc: "Takes instructor list and converts to a list of Task objects"
  body-tail = items.foldr(
    lam(item, acc-tasks): 
      link(
        task(
          ED.h-sequence(
            string-split-all(item.{0}, "\n").foldr(
              lam(elt, acc): link([ED.para: ED.text(elt)], acc) end, 
              [list: [ED.para: ED.optional(instructor-defn)]]),
            " "),
          item.{1}),
        acc-tasks)
    end, 
    [list: task([ED.error: [ED.para: ED.text(closing-prompt)]], {(_): false})])
  head = task(
    ED.h-sequence(
      string-split-all(opening-prompt, "\n").foldr(
        lam(elt, acc): link([ED.para: ED.text(elt)], acc) end, 
        [list: 
          [ED.para: instructor-defn], 
          [ED.para: ED.text("Ready to begin? Enter yes or no.")]]),
      " "),
    is-yes)
  link(head, body-tail)
end

var tasks = get-task-list(task-list)
  


var attempt :: Attempt = neutral

fun get-current-task() -> Annotated block:
  current-attempt = attempt
  attempt := pyret-error
  annotated-task(feedback(current-attempt),
    task(tasks.first.prompt, tasks.first.predicate))
end

fun repl-hook(value):
  cases(List) tasks:
    | link(t, rest) =>
      attempt := ask block:
        | value == nothing then: neutral
        | t.predicate(value) then:
          tasks := rest
          correct
        | otherwise: incorrect
      end
    | empty => raise("Found end of task list. Should not have occured.")
  end
end