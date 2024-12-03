import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import internal/aoc_utils
import simplifile

pub fn main() {
  let filename = "inputs/day03.txt"

  let full_text = simplifile.read(from: filename)
  case full_text {
    Ok(content) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      io.println("Part 1: " <> aoc_utils.solution_or_error(solve_p1(content)))
      io.println("Part 2: " <> aoc_utils.solution_or_error(solve_p2(content)))
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(content: String) -> Result(String, String) {
  let assert Ok(re) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")

  regexp.scan(with: re, content: content)
  |> list.map(calculate_match)
  |> int.sum
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(content: String) -> Result(String, String) {
  let assert Ok(re_mul) = regexp.from_string("mul\\((\\d+),(\\d+)\\)")
  let assert Ok(re_dont) = regexp.from_string("don't\\(\\)")

  regexp.split(with: re_dont, content: content)
  |> get_doable_regions
  |> list.map(regexp.scan(with: re_mul, content: _))
  |> list.flatten
  |> list.map(calculate_match)
  |> int.sum
  |> int.to_string
  |> Ok
}

fn calculate_match(match: regexp.Match) -> Int {
  list.fold(match.submatches, 1, fn(mul, submatch) {
    case submatch {
      Some(s) -> {
        let assert Ok(i) = int.parse(s)
        mul * i
      }
      None -> mul
    }
  })
}

fn get_doable_regions(regions: List(String)) -> List(String) {
  case regions {
    [f] -> [f]
    [f, ..rest] -> get_doable_regions_acc(rest, [f])
    [] -> []
  }
}

fn get_doable_regions_acc(
  dont_regions: List(String),
  do_regions: List(String),
) -> List(String) {
  let assert Ok(re_do) = regexp.from_string("do\\(\\)")

  case dont_regions {
    [f, ..rest] -> {
      let dos = regexp.split(with: re_do, content: f) |> list.drop(1)
      get_doable_regions_acc(rest, list.flatten([dos, do_regions]))
    }
    [] -> do_regions
  }
}
