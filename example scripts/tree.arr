import error-display as ED
import srcloc as S
import valueskeleton as VS
include image


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

# Prompts can be strings, with lines separated by '\n', or lists of anything
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

data Task:
  | base-task(
      prompt :: ED.ErrorDisplay,
      predicate :: (Any -> Boolean))
  | task(
      id :: Number,
      prompt :: ED.ErrorDisplay,
      predicate :: (Any -> Boolean))
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
    | incorrect => [ED.para: ED.text("Incorrect, try again.")]
    | pyret-error => [ED.para: ED.text("Encountered Pyret error(s), try again.")]
  end
end

instructor-defn =
  ED.cmcode(S.srcloc("definitions://", defn-start, defn-char-start, 0, defn-end, defn-char-end, 0))

fun get-task-list(items :: List<{Any; (Any -> Boolean)}>) -> List<Task>:
  doc: "Takes instructor list and converts to a list of Task objects"

  fun to-ED(contents :: Any) -> List<ED.ErrorDisplay>:
    doc: "Converts anything into a list of renderable ErrorDisplays"

    fun to-ED-unwrapped(elt :: Any) -> List<ED.ErrorDisplay>:
      doc: "Converts anything into a list of ErrorDisplays"
      ask:
        | is-List(elt) then:
          elt.foldr({(content, acc): to-ED-unwrapped(content) + acc}, empty)
        | is-string(elt) then:
          lines = string-split-all(elt, "\n")
          lines.map(ED.text)
        | otherwise: [list: ED.embed(elt)]
      end
    end

    to-ED-unwrapped(contents).map({(x): [ED.para: x]})
  where:
    to-ED("test") is [list: [ED.para: ED.text("test")]]
    to-ED([list: "a", circle(10, "solid", "green"), "b"]) is [list:
      [ED.para: ED.text("a")],
      [ED.para: ED.embed(circle(10, "solid", "green"))],
      [ED.para: ED.text("b")]]
    to-ED([list: [list: "a", "b"]]) is [list:
      [ED.para: ED.text("a")],
      [ED.para: ED.text("b")]]
  end

  # First prompt includes non-optional data definition
  first = base-task(
    ED.h-sequence(
      to-ED(opening-prompt) + [list:
        [ED.para: instructor-defn],
        [ED.para: ED.text("Ready to begin? Enter yes or no.")]],
      " "),
    is-yes)

  # All prompts after the first
  rest = items.foldr(
    lam(item, acc-tasks):
      prompt = ED.h-sequence(
        to-ED(item.{0}) + [list: [ED.para: ED.optional(instructor-defn)]],
        " ")
      link(base-task(prompt, item.{1}), acc-tasks)
    end,
    [list: base-task(ED.h-sequence(to-ED(closing-prompt), " "), {(_): false})])

  tasks = link(first, rest)
  var id = -1
  tasks.map(
    lam(t) block:
      id := id + 1
      task(id, t.prompt, t.predicate)
    end)
end

var tasks = get-task-list(task-list)

var attempt :: Attempt = neutral

fun get-current-task() -> Annotated block:
  current-attempt = attempt
  attempt := pyret-error
  annotated-task(feedback(current-attempt), tasks.first)
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