include data-druid
import valueskeleton as VS

# Instructor-Provided Definitions

data Date:
  | date(month :: Number, day :: Number, year :: Number)
end

data Student:
  | student(name :: String, birthday :: Date)
end

data Student2:
  | student2(name :: String, birthday :: Date2)
sharing:
  method _output(self):
    VS.vs-str("Output intentionally hidden.")
  end
end

data Date2:
  | date2(month :: Number, day :: Number, year :: Number)
sharing:
  method _output(self):
    VS.vs-str("Output intentionally hidden.")
  end
end

a = student2("Alice", date2(7, 1, 2003))
b = student2("Benjamin", date2(1, 1, 1))

# Prompts can be strings, with lines separated by '\n', or lists of anything
task-list :: List<{String; (Any -> Boolean)}> = [list:
  {"First, use the Date definition to represent the date July 1st, 2019.";
    _ == date(7, 1, 2019)},
  {"Represent a student named 'Alice' who was born in 1999 on April 1st."; _ == student("Alice", date(4, 1, 1999))},
  {"Next, represent a student named 'Bob' whose birthday is March 30.";
    _ == impossible},
  {"Next, represent a student who was born on June 3rd, 2001, named 'Caroline'.";
    _ == student("Caroline", date(6, 3, 2001))},
  {"We have defined a Student instance called 'b'. Using field accessors (i.e., '.first'), can you find their name?"; _ == b.name},
  {"We have defined a Student instance called 'a'. Using field accessors, can you find their birth month?"; _ == a.birthday.month}
]

opening-prompt =
  [list: "Welcome to the Data Druid demo!",
    "The following prompts will ask you to build some data instances. If the proposed scenario is impossible to represent with the given data definitions, enter 'impossible'.",
    "Here's the data definitions for a date and a student:"]

closing-prompt = "Congrats!"

# for definition window
defn-start = 6
defn-char-start = 0
defn-end = 12
defn-char-end = 3

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