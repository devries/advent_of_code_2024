import day20/solution
import gleam/string
import gleeunit/should

const testinput = "###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines, 20)
  |> should.equal(Ok("5"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines, 70)
  |> should.equal(Ok("41"))
}
