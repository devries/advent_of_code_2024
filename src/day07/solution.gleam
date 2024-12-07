import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day07.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      io.println("Part 1: " <> aoc_utils.solution_or_error(solve_p1(lines)))
      io.println("Part 2: " <> aoc_utils.solution_or_error(solve_p2(lines)))
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  use parsed_lines <- result.map({
    lines
    |> list.map(parse)
    |> result.all
  })

  parsed_lines
  |> list.filter(fn(parsed_line) { is_possible(parsed_line.0, parsed_line.1) })
  |> list.map(pair.first)
  |> int.sum
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use parsed_lines <- result.map({
    lines
    |> list.map(parse)
    |> result.all
  })

  parsed_lines
  |> list.filter(fn(parsed_line) {
    is_possible_part2(parsed_line.0, parsed_line.1)
  })
  |> list.map(pair.first)
  |> int.sum
  |> int.to_string
}

fn parse(line: String) -> Result(#(Int, List(Int)), String) {
  let first_split = case string.split(line, ": ") {
    [pre, post] -> Ok(#(pre, post))
    _ -> Error("Unable to parse line: " <> line)
  }

  use #(pre, post) <- result.try(first_split)

  use target <- result.try({
    int.parse(pre)
    |> result.replace_error("Unable to convert " <> pre <> " to integer")
  })

  let parsed_list =
    post
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all
    |> result.replace_error("Unable to parse integers in list " <> post)

  use parsed_list <- result.try(parsed_list)
  Ok(#(target, parsed_list))
}

fn is_possible(target: Int, values: List(Int)) -> Bool {
  case values {
    [] -> False
    [first, ..rest] -> is_possible_acc(target, rest, first)
  }
}

fn is_possible_acc(target: Int, values: List(Int), current: Int) -> Bool {
  case values {
    [] -> current == target
    _ if current > target -> False
    [first, ..rest] -> {
      is_possible_acc(target, rest, current * first)
      || is_possible_acc(target, rest, current + first)
    }
  }
}

fn is_possible_part2(target: Int, values: List(Int)) -> Bool {
  case values {
    [] -> False
    [first, ..rest] -> is_possible_part2_acc(target, rest, first)
  }
}

fn is_possible_part2_acc(target: Int, values: List(Int), current: Int) -> Bool {
  case values {
    [] -> current == target
    _ if current > target -> False
    [first, ..rest] -> {
      is_possible_part2_acc(target, rest, concat(current, first))
      || is_possible_part2_acc(target, rest, current * first)
      || is_possible_part2_acc(target, rest, current + first)
    }
  }
}

fn concat(x: Int, y: Int) -> Int {
  let xs = int.to_string(x)
  let ys = int.to_string(y)

  let assert Ok(r) = int.parse(xs <> ys)
  r
}
