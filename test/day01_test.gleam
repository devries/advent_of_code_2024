import day01/solution
import gleam/string
import gleeunit/should

const testinput = "3   4
4   3
2   5
1   3
3   9
3   3"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("11"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("31"))
}
