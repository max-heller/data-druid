include data-druid
include image
import valueskeleton as VS
import error-display as ED
import lists as L

a = 3.141592

fun foo(x):
  if (x == a):
    "Correct"
  else:
    "Expected the variable a, got something else."
  end
end

opening-prompt = [list: "**Welcome to the Data Druid tutorial!**",
  "Data Druid will take you through a number of prompts and provide feedback to help you practice your coding skills! This tutorial will help you become acquainted with the features of this program.", "For each prompt, type your answer on the line and press enter to submit."]

task-list :: List<{Any; (Any -> Boolean)}> = [list:
  {'First, type in the string `"hello"` and press enter. \n\n(Note that Strings in Pyret are case-sensitive.)';
    _ == "hello"},
  {'Sometimes, you may encounter a prompt that describes an ill-defined task, for example: "Enter a number that is both greater than 0 and less than 0."\n\n In this case, you should click on the `impossible` button instead of writing code.';
    _ == impossible},
  {[list: "You can use the **up arrow** on your keyboard to cycle through your previous entries, and the **down arrow** to go back. Using this, you can easily retrieve text you've previously typed, just like copying and pasting.", 'Try using the up arrow to submit `"hello"` again.'];
    _ == "hello"},
  {[list: "You can also define variables in the entry area. Anything you define and bind to a variable can be accessed in later submissions.", "(Note that when you submit an entry that contains only a variable binding, the prompt will be reprinted.)", "We've defined a variable `a`, which points to some value, and a function `foo`. Try calling `foo` on `a`."];
      _ == "Correct"},
  {[list: "Occasionally, you may find that you need to write multiple lines in one entry, such as when writing a function. Use **shift + enter** to make a new line without submitting. Try typing this multi-line string:", "````\n```foo\nbar```\n````"];
    _ == "foo\nbar"},
]

closing-prompt = [list:"Nice work! You have successfully completed the Data Druid tutorial.", "If you ever find that your code is taking a long time to execute, or you've accidentally written an infinite loop, you can use the **Stop** button to terminate currently running code. This button will not affect your current progress in the assignment.","At any point, you can use the **Restart** button to reload the program and start from the beginning. Note that this action will reset any progress you have made up to that point."]
 
##################################################################
tasks =
  get-task-list(task-list, opening-prompt, closing-prompt, none)

session = state(neutral, tasks)
funs = make-funs(session)
get-current-attempt = funs.{0}
get-current-task = funs.{1}
repl-hook = funs.{2}