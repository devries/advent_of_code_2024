import day19/solution
import gleam/string
import gleeunit/should

const testinput = "r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("6"))
}

pub fn part2_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("16"))
}
