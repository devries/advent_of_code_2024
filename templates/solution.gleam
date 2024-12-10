import gleam/io
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/dayXX.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      aoc_utils.run_part_and_print("Part 1", fn() { solve_p1(lines) })
      aoc_utils.run_part_and_print("Part 2", fn() { solve_p2(lines) })
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  Error("Unimplemented")
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  Error("Unimplemented")
}
