import day10/solution
import gleam/string
import gleeunit/should

const testinput = "89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("36"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("81"))
}
