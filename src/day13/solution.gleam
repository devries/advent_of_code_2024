import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day13.txt"

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
  use inputs <- result.map({
    lines
    |> aoc_utils.chunk_around_empty_strings()
    |> list.map(parse)
    |> result.all
  })

  inputs
  |> list.map(solve)
  |> result.values
  |> list.map(fn(v) { 3 * v.0 + v.1 })
  |> int.sum
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use inputs <- result.map({
    lines
    |> aoc_utils.chunk_around_empty_strings()
    |> list.map(parse)
    |> result.all
  })

  inputs
  |> list.map(fn(i) {
    Input(..i, px: 10_000_000_000_000 + i.px, py: 10_000_000_000_000 + i.py)
  })
  |> list.map(solve)
  |> result.values
  |> list.map(fn(v) { 3 * v.0 + v.1 })
  |> int.sum
  |> int.to_string
}

type Input {
  Input(ax: Int, ay: Int, bx: Int, by: Int, px: Int, py: Int)
}

fn parse(lines: List(String)) -> Result(Input, String) {
  let assert Ok(plus_re) = regexp.from_string("\\+(\\d+)")
  let assert Ok(eq_re) = regexp.from_string("=(\\d+)")

  lines
  |> list.index_fold(Ok(Input(0, 0, 0, 0, 0, 0)), fn(input_result, line, idx) {
    case input_result, idx {
      Ok(input), 0 -> {
        let scanresult =
          regexp.scan(plus_re, line)
          |> scanline()

        case scanresult {
          Ok([x, y]) -> Ok(Input(..input, ax: x, ay: y))
          Error(s) -> Error(s)
          _ -> Error("Unexpected number of matches")
        }
      }
      Ok(input), 1 -> {
        let scanresult =
          regexp.scan(plus_re, line)
          |> scanline()

        case scanresult {
          Ok([x, y]) -> Ok(Input(..input, bx: x, by: y))
          Error(s) -> Error(s)
          _ -> Error("Unexpected number of matches")
        }
      }
      Ok(input), 2 -> {
        let scanresult =
          regexp.scan(eq_re, line)
          |> scanline()

        case scanresult {
          Ok([x, y]) -> Ok(Input(..input, px: x, py: y))
          Error(s) -> Error(s)
          _ -> Error("Unexpected number of matches")
        }
      }
      Ok(_), _ -> {
        Error("Found too many lines")
      }
      _, _ -> input_result
    }
  })
}

fn scanline(matches: List(regexp.Match)) -> Result(List(Int), String) {
  matches
  |> list.map(fn(match) {
    case list.first(match.submatches) {
      Ok(option.Some(x)) -> {
        int.parse(x)
        |> result.replace_error("Unable to parse " <> x)
      }
      _ -> Error("Bad match")
    }
  })
  |> result.all
}

//      ax * A +      bx * B =      px
//      ay * A +      by * B =      py
//
// by * ax * A + by * bx * B = by * px
// bx * ay * A + bx * by * B = bx * py
//
// ( ax * by - ay * bx ) * A = by * px - bx * py
//
// A = ( px * by - py * bx ) / ( ax * by - ay * bx )
//
// B = ( px - ax * A ) / bx
//

fn solve(i: Input) -> Result(#(Int, Int), Nil) {
  let denominator = i.ax * i.by - i.ay * i.bx
  let numerator = i.px * i.by - i.py * i.bx

  use a <- result.try(int.divide(numerator, denominator))
  let b = { i.px - i.ax * a } / i.bx
  case numerator % denominator {
    0 -> Ok(#(a, b))
    _ -> Error(Nil)
  }
}
