include data-druid
include image
import valueskeleton as VS
# Instructor-Provided Definitions

data Tree:
  | mt
  | node(
      value :: Number,
      left :: Tree,
      right :: Tree)
end

data Tree2:
  | mt2
  | node2(
      value :: Number,
      left :: Tree2,
      right :: Tree2)
sharing:
  method _output(self):
    VS.vs-str("Output intentionally hidden.")
  end
end

fun leaf(val):
  node(val, mt, mt)
end

foo = node2(2.72, node2(3.14, mt2, node2(6.02, mt2, mt2)), node2(6.28, mt2, mt2))

# Prompts can be strings, with lines separated by '\n', or lists of anything
task-list :: List<{Any; (Any -> Boolean)}> = [list:
  {"First, construct an empty tree."; _ == mt},
  {[list: "Next, construct the following tree:",
      image-url("https://i.imgur.com/s4ZA6C9.png")];
    _ == node(5, mt, mt)},
  {"Next, construct a tree with root node 1, left child with value 2, and right child with value 3.";
    _ == node(1, node(2, mt, mt), node(3, mt, mt))},
  {[list: "Next, construct the following tree:",
      image-url("https://i.imgur.com/TEasw4l.png")];
    is-no},
  {"Next, construct a tree with a depth of at least three.";
    lam(input):
        fun depth(t) -> Number:
          cases (Tree) t:
            | mt => 0
            | node(_, l, r) =>
               1 + num-max(depth(l), depth(r))
          end
        end
      is-Tree(input) and (depth(input) >= 3)
    end},
  {"We have defined a Tree instance named 'foo'. Using dot accessors, retrieve the value of the root's left child.";
    _ == foo.left.value}
]

opening-prompt = [list: "Welcome to the Data Druid demo!",
    "The following prompts will ask you to build some data instances. If the proposed scenario is impossible to represent with the given data definitions, enter 'impossible'.",
  "Here's the data definitions for a binary tree:"]
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