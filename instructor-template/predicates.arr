provide *
include shared-gdrive("playground.arr", "1sRD4hBi-TP9j_FBCg5ZZxo50rcUqFOR1")

# INSTRUCTOR PROVIDED DATA DEFINITION

data Person:
  | person(name :: String, age :: Number)
end

# TYPE CHECKER AND GENERAL HINT

fun type-checker(x :: Any) -> Boolean:
  is-person(x)
end

general-hint = 
  "Here is a hint!"

#  PREDICATES 

pred-is-infant = pred(
  {(t): t.age == 0},
  "Is there a minimum age for a person?")

pred-has-fullname = pred(
  {(t): t.name.string-split-all(" ").length > 1},
  "What kinds of names can people have?"
)

## HINT CRITERIA FUNCTIONS

fun is-general-hint-eligible(
    stagnated-attempts :: Number,
    num-predicates :: Number,
    num-satisfied-predicates :: Number)
  -> Boolean:
  stagnated-attempts > 2
end

fun is-specific-hint-eligible(
    stagnated-attempts :: Number,
    num-predicates :: Number,
    num-satisfied-predicates :: Number)
  -> Boolean:
  (stagnated-attempts >= 4) and (num-predicates >= 2)
end  