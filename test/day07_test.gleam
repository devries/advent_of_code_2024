import day07/solution
import gleam/string
import gleeunit/should

const testinput = "190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("3749"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("11387"))
}
