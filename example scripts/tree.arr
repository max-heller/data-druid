include data-druid
include image

# Instructor-Provided Definitions

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
task-list :: List<{Any; (Any -> Boolean)}> = [list:
  {"First, construct an empty tree."; _ == mt},
  {[list: "Next, construct the following tree:",
      image-url("https://i.imgur.com/jR9KOsz.png")];
    _ == node(5, mt, mt)},
  {"Next, construct a tree with root node 1, left child 2, and right child 3.";
    _ == node(1, node(2, mt, mt), node(3, mt, mt))},
  {"Next, construct a tree with at least three levels.";
    lam(tree):
        fun depth(t) -> Number:
          cases (Tree) t:
            | mt => 0
            | node(_, l, r) =>
               1 + num-max(depth(l), depth(r))
          end
        end
        depth(tree) >= 3
    end}
]

opening-prompt = "Welcome to the Data Druid demo! Here's a data definition for a binary tree:"
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
  get-task-list(task-list, opening-prompt, closing-prompt, instructor-defn)

session = state(neutral, tasks)
funs = make-funs(session)
get-current-attempt = funs.{0}
get-current-task = funs.{1}
repl-hook = funs.{2}
