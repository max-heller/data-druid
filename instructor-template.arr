include data-druid
include image
import valueskeleton as VS
include shared-gdrive("cs111-2018.arr", "1XxbD-eg5BAYuufv6mLmEllyg28IR7HeX")

### INSTRUCTOR DATA DEFINITIONS GO HERE 

data Person:
  | person(name :: String, age :: Number)
end

# For making hidden instances
data Person2:
  | person2(name :: String, age :: Number)
sharing:
  method _output(self):
    VS.vs-str("Output intentionally hidden.")
  end
end

# Hidden instances
x = person2("Bob", 17)

### LOCATION of INSTRUCTOR-PROVIDED DATA DEFINITION
# (TO BE SHOWN WITH EVERY PROMPT)

# starting line of definition
defn-start = 8
defn-char-start = 0

# ending line of definition
defn-end = 10
defn-char-end = 50

### OPENING PROMPT (supports markdown)

opening-prompt = [list: "## Data Druid: Weather Tables",
  "The following prompts will ask you to build a few examples of a data structure. If the proposed scenario is impossible to represent with the given data definitions, click the `impossible` button.",
  "Here's the definition of a `Person` object used to store information about an individual:"]

### TASK PROMPTS
#
# every task is represented as a tuple {A;B}, where A is either a single string or a list of 
# renderable objects, and B is a satisfiable predicate that takes in a student-entered value 
# and returns true when the predicate is satisfied. 
#
# for the text of each prompt, if a single string is entered, it will be rendered with markdown.
# if a list of strings and objects is entered, strings will be rendered as discrete mardown
# paragraphs and Pyret objects will be embedded using Pyret's native object rendering.
#

task-list :: List<{Any; (Any -> Boolean)}> = [list:
  {"Create a `Person` instance for `Alice`, who is `25` years old.";
    _ == person("Alice", 25)},
  {"Given a `Person` stored as `x`, retrieve their age.";
    _ == x.age}
]

### CLOSING PROMPT

closing-prompt = "Nice job! You have successfully completed this assignment."

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
