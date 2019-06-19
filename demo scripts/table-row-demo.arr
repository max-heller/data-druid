### Assignment URL: http://localhost:5000/editor#assignment=1Sy-A-Pc6qJG62J8BS3qW6P8IooDUMpAe
### Import Line: include shared-gdrive("table-demo.arr", "1Sy-A-Pc6qJG62J8BS3qW6P8IooDUMpAe")
provide *
include shared-gdrive("playground.arr", "1sRD4hBi-TP9j_FBCg5ZZxo50rcUqFOR1")
include tables

# gradebook = 
#   table: name :: String, SNC :: Boolean, exam1 :: Number, exam2 :: Number end

fun type-checker(x :: Any) -> Boolean:
  is-row(x) and 
  (x.get-column-names() == [list: "name", "SNC", "exam1", "exam2"]) and
  is-string(x.get-value("name")) and
  is-boolean(x.get-value("SNC")) and
  is-number(x.get-value("exam1")) and
  is-number(x.get-value("exam2"))
end

general-hint = 
  "Think about what kind of data can go in each column of the table and how each table can have multiple rows."


## PREDICATES

score-change-hint = "How can a student's performance change between the two exams?"

pred-is-zero-score = pred(
  {(r): (r.get-value("exam1") == 0) or (r.get-value("exam2") == 0)},
  "What are the possible values for a student's score?")

pred-is-improving-score = pred(
  {(r): r.get-value("exam1") < r.get-value("exam2")},
  score-change-hint)

pred-is-same-score = pred(
  {(r): r.get-value("exam1") == r.get-value("exam2")},
  score-change-hint)

pred-is-worsening-score = pred(
  {(r): r.get-value("exam1") > r.get-value("exam2")},
  score-change-hint)

pred-is-snc = pred(
  {(r): r.get-value("SNC") == true},
  "What are the possible answers to 'Is this student taking the course S/NC'?")

## HINT CRITERIA FUNCTIONS

fun is-general-hint-eligible(
   stagnated-attempts :: Number,
   num-predicates :: Number,
   num-satisfied-predicates :: Number)
 -> Boolean:
  stagnated-attempts >= 5
end

fun is-specific-hint-eligible(
   stagnated-attempts :: Number,
   num-predicates :: Number,
   num-satisfied-predicates :: Number)
 -> Boolean:
  (stagnated-attempts >= 3) and
  (num-satisfied-predicates >= (num-predicates - 1))
end  