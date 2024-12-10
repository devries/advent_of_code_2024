import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day04.txt"

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
  let map = parse(lines)
  let word = "XMAS"
  let word_forward = string.to_graphemes(word) |> list.map(Ok)
  let word_reverse = list.reverse(word_forward)
  let assert Ok(first_letter) = string.first(word)
  let assert Ok(last_letter) = string.last(word)
  let directions = [#(1, 0), #(0, 1), #(1, 1), #(1, -1)]

  map
  |> dict.to_list
  // Find X or S points
  |> list.filter(fn(pl) { pl.1 == first_letter || pl.1 == last_letter })
  |> list.map(pair.first)
  |> list.map(fn(p) {
    // create spans of point horizontally, vertically, and in both diagonals
    directions
    |> list.map(fn(d) {
      span_points(p, d, list.length(word_forward))
      // Get the letters for those spans
      |> list.map(dict.get(map, _))
    })
  })
  |> list.flatten
  |> list.map(fn(span) {
    // Check if they match the word forward or reversed
    case span {
      l if l == word_forward -> 1
      l if l == word_reverse -> 1
      _ -> 0
    }
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let map = parse(lines)

  map
  |> dict.to_list
  // Find where "A"s are located
  |> list.filter(fn(pl) { pl.1 == "A" })
  |> list.map(pair.first)
  |> list.map(fn(p) {
    // Get the four coordinates around each A
    [#(-1, -1), #(1, 1), #(-1, 1), #(1, -1)]
    |> list.map(point.add(p, _))
    |> list.map(dict.get(map, _))
  })
  |> list.map(fn(corners) {
    // Check if they are arranged appropriately
    case corners {
      [Ok("M"), Ok("S"), Ok("M"), Ok("S")] -> 1
      [Ok("M"), Ok("S"), Ok("S"), Ok("M")] -> 1
      [Ok("S"), Ok("M"), Ok("M"), Ok("S")] -> 1
      [Ok("S"), Ok("M"), Ok("S"), Ok("M")] -> 1
      _ -> 0
    }
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

fn parse(lines: List(String)) -> Dict(Point, String) {
  use map, line, y <- list.index_fold(lines, dict.new())
  let characters = string.to_graphemes(line)

  use map, c, x <- list.index_fold(characters, map)
  let p = #(x, y)
  dict.insert(map, p, c)
}

fn span_points(start: Point, direction: Point, length: Int) -> List(Point) {
  list.range(0, length - 1)
  |> list.map(point.mul(direction, _))
  |> list.map(point.add(start, _))
}
