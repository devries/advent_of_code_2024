import day11/solution
import gleam/string
import gleeunit/should

const testinput = "125 17"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("55312"))
}
