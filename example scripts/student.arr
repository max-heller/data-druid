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

data Date:
  | date(month :: Number, day :: Number, year :: Number)
end

data Student:
  | student(name :: String, birthday :: Date)
end

a = student("Alice", date(4, 1, 1999))
# Prompts can be strings, with lines separated by '\n', or lists of anything
task-list :: List<{String; (Any -> Boolean)}> = [list:
  {"First, represent a student named 'Alice' who was born in 1999 on April 1st."; _ == student("Alice", date(4, 1, 1999))},
  {"Next, represent a student named 'Bob' whose birthday is March 30.";
    _ == impossible},
  {"Next, represent a student who was born on June 3rd, 2001, named 'Caroline'.";
    _ == student("Caroline", date(6, 3, 2001))},
  {"We have defined a Student instance a. Using field accessors, can you find their birth month?"; _ == 4}
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
  first = task(
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
      link(task(prompt, item.{1}), acc-tasks)
    end,
    [list: task(ED.h-sequence(to-ED(closing-prompt), " "), {(_): false})])

  link(first, rest)
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
