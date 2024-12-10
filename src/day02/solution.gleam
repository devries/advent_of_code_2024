import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day02.txt"

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
  use parsed_data <- result.map({
    lines
    |> list.try_map(parse_line)
  })

  parsed_data
  |> list.count(is_safe)
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use parsed_data <- result.map({
    lines
    |> list.try_map(parse_line)
  })

  parsed_data
  |> list.count(is_really_safe)
  |> int.to_string
}

// Parse a line as space separated integers
fn parse_line(line: String) -> Result(List(Int), String) {
  line
  |> string.split(" ")
  |> list.filter(fn(v) { v != "" })
  |> list.try_map(int.parse)
  |> result.replace_error("Unable to parse line: " <> line)
}

pub type Change {
  Increase(Int)
  Decrease(Int)
  Flat
}

pub fn to_changes(values: List(Int)) -> List(Change) {
  to_changes_acc(values, [])
}

fn to_changes_acc(values: List(Int), acc: List(Change)) -> List(Change) {
  case values {
    [f, s, ..rest] if f < s ->
      to_changes_acc([s, ..rest], [Increase(s - f), ..acc])
    [f, s, ..rest] if f > s ->
      to_changes_acc([s, ..rest], [Decrease(f - s), ..acc])
    [_, s, ..rest] -> to_changes_acc([s, ..rest], [Flat, ..acc])
    [_, ..rest] -> to_changes_acc(rest, acc)
    [] -> list.reverse(acc)
  }
}

pub fn is_safe(record: List(Int)) -> Bool {
  record
  |> to_changes
  |> tolerable_changes
}

fn tolerable_changes(changes: List(Change)) -> Bool {
  case changes {
    [Increase(_), Decrease(_), ..] -> False
    [Decrease(_), Increase(_), ..] -> False
    [Flat, ..] -> False
    [Increase(x), ..] if x > 3 -> False
    [Decrease(x), ..] if x > 3 -> False
    [_, ..rest] -> tolerable_changes(rest)
    [] -> True
  }
}

pub fn is_really_safe(record: List(Int)) -> Bool {
  // If it satisfies the regular safety check, we are fine.
  use <- bool.guard(is_safe(record), True)

  // If the regular check does not pass, we try removing each level
  // to see if removing one will cause it to pass.
  record
  |> list.combinations(list.length(record) - 1)
  |> list.any(fn(subrecord) {
    subrecord
    |> to_changes
    |> tolerable_changes
  })
}
