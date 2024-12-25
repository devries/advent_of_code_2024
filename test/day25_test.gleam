import day25/solution
import gleam/string
import gleeunit/should

const testinput = "#####
.####
.####
.####
.#.#.
.#...
.....

#####
##.##
.#.##
...##
...#.
...#.
.....

.....
#....
#....
#...#
#.#.#
#.###
#####

.....
.....
#.#..
###..
###.#
###.#
#####

.....
.....
.....
#....
#.#..
#.#.#
#####"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("3"))
}
