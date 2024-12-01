import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day01.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      io.println("Part 1: " <> aoc_utils.solution_or_error(solve_p1(lines)))
      io.println("Part 2: " <> aoc_utils.solution_or_error(solve_p2b(lines)))
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  use #(l1, l2) <- result.map(parse_lines(lines))

  // Sort lists
  let sl1 = list.sort(l1, int.compare)
  let sl2 = list.sort(l2, int.compare)

  // zip sorted lists and take the absolute value of the differency of each tuple
  list.zip(sl1, sl2)
  |> list.map(fn(tpl) { int.absolute_value(tpl.0 - tpl.1) })
  |> int.sum
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use #(l1, l2) <- result.map(parse_lines(lines))

  // Map the first list to a function which counts occurrences in the second list
  // and then multiplies them by the value
  l1
  |> list.map(fn(x) {
    let c = list.count(l2, fn(o) { o == x })
    c * x
  })
  |> int.sum
  |> int.to_string
}

// After seeing Jonathan Paulson's video of his solution, I realize it is likely
// much more efficient to create a dictionary of the counts for each element in
// list 2, then run through list one looking up the counts.
pub fn solve_p2b(lines: List(String)) -> Result(String, String) {
  use #(l1, l2) <- result.map(parse_lines(lines))

  let counts = count_values(l2)

  l1
  |> list.map(fn(x) {
    dict.get(counts, x)
    |> result.unwrap(0)
    |> int.multiply(x)
  })
  |> int.sum
  |> int.to_string
}

// Parse all lines
fn parse_lines(lines: List(String)) -> Result(#(List(Int), List(Int)), String) {
  use combined <- result.try(list.try_map(lines, parse_line))

  combined
  |> list.try_fold(from: #([], []), with: fn(lists, couple) {
    case couple {
      [x, y] -> Ok(#([x, ..pair.first(lists)], [y, ..pair.second(lists)]))
      _ ->
        Error(
          "Unexpected number of integers in line: " <> string.inspect(couple),
        )
    }
  })
}

// Parse a line as space separated integers
fn parse_line(line: String) -> Result(List(Int), String) {
  line
  |> string.split(" ")
  |> list.filter(fn(v) { v != "" })
  |> list.try_map(int.parse)
  |> result.replace_error("Unable to parse line: " <> line)
}

fn count_values(l: List(a)) -> dict.Dict(a, Int) {
  list.fold(l, from: dict.new(), with: fn(d, x) {
    let current_count = dict.get(d, x) |> result.unwrap(0)
    dict.insert(d, for: x, insert: current_count + 1)
  })
}
