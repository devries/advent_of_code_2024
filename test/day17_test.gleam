import day17/solution
import gleam/string
import gleeunit/should

const testinput = "Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0"

const testinput_part2 = "Register A: 2024
Register B: 0
Register C: 0

Program: 0,3,5,4,3,0"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("4,6,3,5,6,3,5,2,1,0"))
}

pub fn part2_test() {
  let lines = string.split(testinput_part2, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("117440"))
}
