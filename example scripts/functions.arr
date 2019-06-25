include data-druid
include image
import valueskeleton as VS
import error-display as ED
import lists as L

opening-prompt = [list: "### Data Druid: Function Practice","The following prompts will ask you to explore and write some Pyret functions."]

candy = table: name, sugar-percent
  row: "100 Grand", 0.73199999
  row: "3 Musketeers", 0.60399997
end

race-speeds = table: race, speed
  row: "Boston", 13
  row: "New York", 15
  row: "Los Angeles", 14
end

task-list :: List<{Any; (Any -> Boolean)}> = [list:
  #| {[list:'First, try writing a simple function that takes in a number and returns the number plus 1.', "You may have to return the function by entering its name without brackets (e.g., `foo`) in order to submit it correctly."];
    {(f):
      is-function(f) and
      (f(1) == 2) and
      (f(10.5) == 11.5) and
      (f(-4) == -3)}}, |#
  {[list: "Given this table, `candy`:",
      ED.embed(candy),
      "Write a single line of code that retrieves the sugar-percent value of *100 Grand*. (Remember, tables are 0-indexed in Pyret)."];
    _ == candy.row-n(0)["sugar-percent"]},
  #|
  {[list: "We've defined a table `race-speeds` that contains data on the highest speed achieved in various races. Here are the columns contained in the table:", 
      ED.embed(table: race, speed end),
      "Using `sort-by` and `row-n`, write a single line of code that retrieves the name of the race in `race-speeds` that has the highest achieved speed. You may assume that the table has more than one entry."];
    _ == sort-by(race-speeds, "speed", false).row-n(0)["race"]},
  |#
  {"Is `link(3, 4)` a valid list? Enter yes or no.";
    is-no},
  {"Can you construct a valid list that only contains 3 and 4?";
    _ == [list: 3, 4]},
  {[list:"Alice wrote the following function to find the product of all numbers in a list:",
      "```\nfun list-product(lst :: List) -> Number:\n  cases (List) lst:\n    | empty => 0\n    | link(first, rest) => first * list-product(lst)\n  end\nend\n```",
      "Does Alice's function work? Either enter `yes`, or provide an example of a `List` that exposes a flaw in `list-product`. (You do not have to call the function.)"];
    is-link}
]

closing-prompt = "Nice job! You have successfully completed this assignment: Function Practice."
 
##################################################################
tasks =
  get-task-list(task-list, opening-prompt, closing-prompt, none)

session = state(neutral, tasks)
funs = make-funs(session)
get-current-attempt = funs.{0}
get-current-task = funs.{1}
repl-hook = funs.{2}