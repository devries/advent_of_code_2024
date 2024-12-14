import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/regexp
import gleam/result
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day14.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      aoc_utils.run_part_and_print("Part 1", fn() { solve_p1(lines, 101, 103) })
      aoc_utils.run_part_and_print("Part 2", fn() { solve_p2(lines, 101, 103) })
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(
  lines: List(String),
  x_size: Int,
  y_size: Int,
) -> Result(String, String) {
  use robots <- result.map({
    lines
    |> list.map(parse)
    |> result.all
  })
  list.range(1, 100)
  |> list.fold(robots, fn(rlist, _) { list.map(rlist, step(_, x_size, y_size)) })
  |> quadrant_split(x_size, y_size)
  |> dict.values
  |> list.map(list.length)
  |> list.fold(1, fn(m, n) { m * n })
  |> int.to_string
}

// Part 2
pub fn solve_p2(
  lines: List(String),
  x_size: Int,
  y_size: Int,
) -> Result(String, String) {
  use robots <- result.map({
    lines
    |> list.map(parse)
    |> result.all
  })
  step_and_check_overlap(robots, x_size, y_size, 0)
  |> int.to_string
}

type Robot {
  Robot(p: Point, v: Point)
}

fn parse(line: String) -> Result(Robot, String) {
  let assert Ok(re) =
    regexp.from_string("p=(\\d+),(\\d+)\\s+v=(-?\\d+),(-?\\d+)")

  case regexp.scan(re, line) {
    [regexp.Match(_, matches)] -> {
      case matches {
        [Some(p1s), Some(p2s), Some(v1s), Some(v2s)] -> {
          let assert Ok(p1) = int.parse(p1s)
          let assert Ok(p2) = int.parse(p2s)
          let assert Ok(v1) = int.parse(v1s)
          let assert Ok(v2) = int.parse(v2s)
          Ok(Robot(#(p1, p2), #(v1, v2)))
        }
        _ -> {
          Error("Rebot not parsable")
        }
      }
    }
    _ -> Error("Robot not found")
  }
}

fn step(r: Robot, x_size: Int, y_size: Int) -> Robot {
  let x = { r.p.0 + r.v.0 } % x_size
  let y = { r.p.1 + r.v.1 } % y_size

  case x < 0, y < 0 {
    True, True -> Robot(..r, p: #(x + x_size, y + y_size))
    True, _ -> Robot(..r, p: #(x + x_size, y))
    _, True -> Robot(..r, p: #(x, y + y_size))
    _, _ -> Robot(..r, p: #(x, y))
  }
}

fn quadrant_split(
  rlist: List(Robot),
  x_size: Int,
  y_size: Int,
) -> Dict(Int, List(Robot)) {
  list.group(rlist, fn(r) {
    case int.compare(r.p.0, x_size / 2), int.compare(r.p.1, y_size / 2) {
      order.Lt, order.Lt -> 0
      order.Lt, order.Gt -> 2
      order.Gt, order.Lt -> 1
      order.Gt, order.Gt -> 3
      _, _ -> 4
    }
  })
  |> dict.delete(4)
}

// fn print_robot_map(rlist: List(Robot), x_size: Int, y_size: Int) -> List(Robot) {
//   let rpos =
//     rlist
//     |> list.fold(dict.new(), fn(rpos, r) {
//       dict.upsert(rpos, r.p, fn(existing) {
//         case existing {
//           Some(v) -> v + 1
//           _ -> 1
//         }
//       })
//     })

//   list.each(list.range(0, y_size - 1), fn(y) {
//     list.each(list.range(0, x_size - 1), fn(x) {
//       case dict.get(rpos, #(x, y)) {
//         Ok(v) -> io.print(int.to_string(v))
//         _ -> io.print(" ")
//       }
//     })
//     io.println("")
//   })

//   rlist
// }

// At first I went thousands and thousands of iterations looking for symmetry
// thinking it would be centered, but it was not. Eventually I decided to check
// the reddit, so I did not come up with the no overlap idea.
fn step_and_check_overlap(
  rlist: List(Robot),
  x_size: Int,
  y_size: Int,
  v: Int,
  // ) -> List(Robot) {
) -> Int {
  let rnext = list.map(rlist, fn(r) { step(r, x_size, y_size) })

  // case left_right_symmetry(rnext, x_size, y_size) {
  case no_overlaps(rnext) {
    True -> {
      // print_robot_map(rnext, x_size, y_size)
      // io.println(int.to_string(v + 1))

      v + 1
    }
    _ -> step_and_check_overlap(rnext, x_size, y_size, v + 1)
  }
}

fn no_overlaps(rlist: List(Robot)) -> Bool {
  rlist
  |> list.fold(dict.new(), fn(rpos, r) {
    dict.upsert(rpos, r.p, fn(existing) {
      case existing {
        Some(v) -> v + 1
        _ -> 1
      }
    })
  })
  |> dict.values()
  |> list.all(fn(v) { v == 1 })
}
