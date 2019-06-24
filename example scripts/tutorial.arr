include data-druid
include image
import valueskeleton as VS
import error-display as ED
import lists as L

opening-prompt = [list: "**Welcome to the Data Druid tutorial!**",
  "Data Druid will take you through a number of prompts and provide feedback to help you practice your coding skills! This tutorial will help you become acquainted with the features of this program.", "For each prompt, type your answer on the line and press enter to submit."]

task-list :: List<{Any; (Any -> Boolean)}> = [list:
  {'First, type in the string `"hello"` and press enter. \n\nNote that Strings in Pyret are case-sensitive.';
    _ == "hello"},
  {"Sometimes, you may encounter a prompt that describes an ill-defined task. For example, 'enter a number that is both greater than 0 and less than 0'.\n\n In this case, you should click on the `impossible` button instead of writing code.";
    _ == impossible},
  {[list: "You can use the **up arrow** on your keyboard to cycle through your previous entries, and the **down arrow** to go back. Using this, you can easily retrieve text you've previously typed, just like copying and pasting.", 'Try using the up arrow to submit `"hello"` again.'];
    _ == "hello"},
  {[list: "Occasionally, you may find that you need to write multiple lines in one entry, such as when writing a function. Use **shift + enter** to make a new line without submitting. Try typing this multi-line string:", "````\n```foo\nbar```\n````"];
    _ == "foo\nbar"}
]

closing-prompt = "Nice work! You have successfully completed the Data Druid tutorial."

##################################################################
tasks =
  get-task-list(task-list, opening-prompt, closing-prompt, none)

session = state(neutral, tasks)
funs = make-funs(session)
get-current-attempt = funs.{0}
get-current-task = funs.{1}
repl-hook = funs.{2}