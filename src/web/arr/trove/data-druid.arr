provide *
provide-types *

import global as _
import base as _

import error-display as ED
import srcloc as S
import valueskeleton as VS
include image
include lists


################## DEFINITIONS


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


## STATE

data State:
  | state(
      ref attempt :: Attempt,
      ref tasks :: List<Task>)
end


################## FUNCTIONS

fun make-instructor-defn(
    line-start :: Number,
    char-start :: Number,
    line-end :: Number,
    char-end :: Number)
  -> ED.ErrorDisplay:
  ED.cmcode(S.srcloc("definitions://",
      line-start, char-start, 0, line-end, char-end, 0))
end

fun feedback(attempt :: Attempt) -> ED.ErrorDisplay:
  cases(Attempt) attempt:
    | correct => [ED.para: ED.text("Good job!")]
    | neutral => [ED.para: ]
    | incorrect => [ED.para: ED.text("Incorrect, try again.")]
    | pyret-error => [ED.para: ED.text("Encountered Pyret error(s), try again.")]
  end
end

fun get-task-list(
    items :: List<{Any; (Any -> Boolean)}>,
    opening-prompt :: Any,
    closing-prompt :: Any,
    instructor-defn :: ED.ErrorDisplay)
  -> List<Task>:
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

fun make-funs(s :: State) -> {(-> Attempt); (-> Annotated); (Any -> Nothing)}:
  get-current-attempt = lam() -> Attempt:
    s!attempt
  end

  get-current-task = lam() -> Annotated block:
    current-attempt = s!attempt
    s!{attempt: pyret-error}
    annotated-task(feedback(current-attempt), s!tasks.first)
  end

  repl-hook = lam(value):
    cases(List) s!tasks:
      | link(t, rest) =>
        s!{attempt: ask block:
              | value == nothing then: neutral
              | t.predicate(value) then:
                s!{tasks: rest}
                correct
              | otherwise: incorrect
          end}
      | empty => raise("Found end of task list. Should not have occured.")
    end
  end

  {get-current-attempt; get-current-task; repl-hook}
end