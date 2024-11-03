import gleeunit
import gleeunit/should
import internal/aoc_utils

pub fn main() {
  gleeunit.main()
}

pub fn solution_or_error_test() {
  aoc_utils.solution_or_error(Ok("This is good"))
  |> should.equal("This is good")

  aoc_utils.solution_or_error(Error("This is bad"))
  |> should.equal("ERROR: This is bad")
}
