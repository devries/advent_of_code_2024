import gleam/int
import gleam/io
import gleam/list
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day25.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      aoc_utils.run_part_and_print("Part 1", fn() { solve_p1(lines) })
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  let #(locks, keys) =
    aoc_utils.chunk_around_empty_strings(lines)
    |> list.map(parse_schematic)
    |> list.partition(fn(s) {
      case s {
        Lock(_) -> True
        Key(_) -> False
      }
    })

  locks
  |> list.fold(0, fn(sum, lock) {
    keys
    |> list.fold(sum, fn(sum, key) {
      case combo_test(lock, key) {
        True -> sum + 1
        False -> sum
      }
    })
  })
  |> int.to_string
  |> Ok
}

type Schematic {
  Lock(values: List(Int))
  Key(values: List(Int))
}

fn parse_schematic(lines: List(String)) -> Schematic {
  let values =
    lines
    |> list.map(fn(l) { string.to_graphemes(l) })
    |> list.transpose
    |> list.map(fn(l) {
      list.fold(l, -1, fn(sum, g) {
        case g {
          "#" -> sum + 1
          _ -> sum
        }
      })
    })

  case list.first(lines) {
    Ok(".....") -> Key(values)
    Ok("#####") -> Lock(values)
    _ -> panic as "this should not happen"
  }
}

fn combo_test(a: Schematic, b: Schematic) -> Bool {
  case a, b {
    Lock(va), Key(vb) | Key(vb), Lock(va) -> {
      list.zip(va, vb)
      |> list.fold(True, fn(success, tup) { success && tup.0 + tup.1 < 6 })
    }
    _, _ -> False
  }
}
