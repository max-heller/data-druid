include data-druid
include image
import valueskeleton as VS
import error-display as ED
import lists as L
# Instructor-Provided Definitions
_ = 
table: name, SNC, exam1, exam2 end

# Prompts can be strings, with lines separated by '\n', or lists of anything
task-list :: List<{Any; (Any -> Boolean)}> = [list:
  {"First, make a table containing information on a student named Alice who is taking the course SNC, scored an 87 on the first exam, and a 91 on the second.";
  _ == table: name, SNC, exam1, exam2 row: "Alice", true, 87, 91 end},
  {"Next, make a table containing information on a student named Bob who is taking the course for a grade, scored a 95 on the first exam, and has not yet taken the second";
    _ == no},
  {"Now, make a table containing information on a student named Carol, who got a better score on the first exam than on the second.";
    lam(t):
      is-table(t) and
      (t.column-names() == [list: "name", "SNC", "exam1", "exam2"]) and
      L.any({(r): (r["name"] == "Carol") and (r["exam1"] > r["exam2"])}, t.all-rows())
    end}
]

opening-prompt = [list: "Welcome to the Data Druid demo!",
    "The following prompts will ask you to build some data instances. If the proposed scenario is impossible to represent with the given data definitions, enter 'impossible'.",
  "Here's the definition of a table from class:"]
closing-prompt = "Congrats!"

# for definition window
defn-start = 8
defn-char-start = 0
defn-end = 8
defn-char-end = 50

##################################################################

instructor-defn =
  make-instructor-defn(defn-start, defn-char-start, defn-end, defn-char-end)

tasks =
  get-task-list(task-list, opening-prompt, closing-prompt, some(instructor-defn))

session = state(neutral, tasks)
funs = make-funs(session)
get-current-attempt = funs.{0}
get-current-task = funs.{1}
repl-hook = funs.{2}
