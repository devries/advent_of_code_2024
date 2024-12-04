import gleeunit
import gleeunit/should
import internal/aoc_utils
import internal/point

pub fn main() {
  gleeunit.main()
}

pub fn solution_or_error_test() {
  aoc_utils.solution_or_error(Ok("This is good"))
  |> should.equal("This is good")

  aoc_utils.solution_or_error(Error("This is bad"))
  |> should.equal("ERROR: This is bad")
}

pub fn chunk_up_test() {
  ["aaa", "bbb", "ccc", "", "ddd", "eee", "", "", "fff"]
  |> aoc_utils.chunk_around_empty_strings()
  |> should.equal([["aaa", "bbb", "ccc"], ["ddd", "eee"], ["fff"]])
}

pub fn point_addition_test() {
  point.add(#(2, 1), #(-1, 1))
  |> should.equal(#(1, 2))
}

pub fn point_multiplication_test() {
  point.mul(#(2, 5), 5)
  |> should.equal(#(10, 25))

  point.mul(#(2, 5), 0)
  |> should.equal(#(0, 0))
}
