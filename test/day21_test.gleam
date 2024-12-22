import day21/solution
import gleam/string
import gleeunit/should

const testinput = "029A
980A
179A
456A
379A"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("126384"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok(""))
}
