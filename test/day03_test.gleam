import day03/solution
import gleeunit/should

const testinput = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"

const testinput2 = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

pub fn part1_test() {
  solution.solve_p1(testinput)
  |> should.equal(Ok("161"))
}

pub fn part2_test() {
  solution.solve_p2(testinput2)
  |> should.equal(Ok("48"))
}
