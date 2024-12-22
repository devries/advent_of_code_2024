import day22/solution
import gleam/list
import gleam/string
import gleam/yielder
import gleeunit/should

const testinput = "1
10
100
2024"

pub fn part1_test() {
  let lines = string.split(testinput, "\n")
  solution.solve_p1(lines)
  |> should.equal(Ok("37327623"))
}

const testinput_p2 = "1
2
3
2024"

pub fn part2_test() {
  let lines = string.split(testinput_p2, "\n")
  solution.solve_p2(lines)
  |> should.equal(Ok("23"))
}

const testsequence = [
  15_887_950, 16_495_136, 527_345, 704_524, 1_553_684, 12_683_156, 11_100_544,
  12_249_484, 7_753_432, 5_908_254,
]

pub fn step_test() {
  yielder.unfold(123, fn(v) {
    let r = solution.step(v)
    yielder.Next(r, r)
  })
  |> yielder.take(list.length(testsequence))
  |> yielder.to_list
  |> should.equal(testsequence)
}
