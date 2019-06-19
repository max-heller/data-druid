### Assignment URL: http://localhost:5000/editor#assignment=1whPt1n--1y_vuhvmhBec4g0TW7edd3_2
### Import Line: include shared-gdrive("table-demo2.arr", "1whPt1n--1y_vuhvmhBec4g0TW7edd3_2")
provide *
include shared-gdrive("playground.arr", "1sRD4hBi-TP9j_FBCg5ZZxo50rcUqFOR1")
include tables
import lists as L

# gradebook = 
#   table: name :: String, SNC :: Boolean, exam1 :: Number, exam2 :: Number end

fun type-checker(x :: Any) -> Boolean:
  type-checkers = [list: is-string, is-boolean, is-number, is-number]
  is-table(x) and 
  (x.column-names() == [list: "name", "SNC", "exam1", "exam2"]) and
  fold2(
    lam(acc, column, f):
      acc and L.all(f, column)
    end,
    true,
    x.all-columns(),
    type-checkers)
end

general-hint = 
  "Think about what kind of data can go in each column of the table and how each table can have multiple rows."


## PREDICATES

score-change-hint = "How can a student's performance change between the two exams?"

fun score-is-zero(r :: Row):
  (r.get-value("exam1") == 0) or (r.get-value("exam2") == 0)
end

fun score-is-same(r :: Row):
  r.get-value("exam1") == r.get-value("exam2")
end

fun score-gets-better(r :: Row):
  r.get-value("exam1") < r.get-value("exam2")
end

fun score-gets-worse(r :: Row):
  r.get-value("exam1") > r.get-value("exam2")
end

pred-has-zero-score = pred(
  {(t): L.any(score-is-zero, t.all-rows())},
  "What are the possible values for a student's score?")

pred-has-same-score = pred(
  {(t): L.any(score-is-same, t.all-rows())},
  score-change-hint)

pred-has-worsening-score = pred(
  {(t): L.any(score-gets-worse, t.all-rows())},
  score-change-hint)

pred-has-improving-score = pred(
  {(t): L.any(score-gets-better, t.all-rows())},
  score-change-hint)

pred-duplicate-name = pred(
  {(t): 
    names = t.get-column("name")
    L.distinct(names) <> names},
  "Do student names have to be unique?")

pred-has-snc-variation = pred(
  {(t):
    is-snc = t.get-column("SNC")
    is-snc.member(true) and is-snc.member(false)},
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