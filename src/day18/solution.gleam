import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import internal/aoc_utils
import internal/dijkstra
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day18.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      aoc_utils.run_part_and_print("Part 1", fn() { solve_p1(lines, 70, 1024) })
      aoc_utils.run_part_and_print("Part 2", fn() { solve_p2(lines, 70, 1024) })
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(
  lines: List(String),
  size: Int,
  fallen: Int,
) -> Result(String, String) {
  let bytes =
    parse(lines)
    |> list.take(fallen)
    |> set.from_list
  let pqueue = dijkstra.push(dijkstra.new(), 0, #(0, 0), None)
  use length <- result.map({
    find_route_length(bytes, size, pqueue)
    |> result.replace_error("Error in search")
  })

  length
  |> int.to_string
}

// Part 2
pub fn solve_p2(
  lines: List(String),
  size: Int,
  min_start: Int,
) -> Result(String, String) {
  let bytes = parse(lines)

  let blocker = find_blocking_piece(bytes, min_start, list.length(bytes), size)

  Ok(int.to_string(blocker.0) <> "," <> int.to_string(blocker.1))
}

fn parse(lines: List(String)) -> List(Point) {
  lines
  |> list.map(fn(line) {
    let vals = string.split(line, ",") |> list.map(int.parse)
    case vals {
      [Ok(x), Ok(y)] -> Ok(#(x, y))
      _ -> Error(Nil)
    }
  })
  |> result.values
}

fn find_route_length(
  bytes: Set(Point),
  size: Int,
  pqueue: dijkstra.Queue(Point),
) -> Result(Int, Nil) {
  use #(newpqueue, score, pos) <- result.try(dijkstra.pop(pqueue))

  case pos == #(size, size) {
    True -> {
      // plot_route(newpqueue, bytes, size)
      Ok(score)
    }

    False -> {
      let next_points =
        list.map(point.directions, point.add(_, pos))
        |> list.filter(fn(p) {
          p.0 >= 0 && p.0 <= size && p.1 >= 0 && p.1 <= size
        })
        |> list.filter(fn(p) { !set.contains(bytes, p) })
        |> list.map(fn(p) { #(score + 1, p) })

      let newpqueue = dijkstra.push_list(newpqueue, next_points, Some(pos))
      find_route_length(bytes, size, newpqueue)
    }
  }
}

pub fn plot_route(
  queue: dijkstra.Queue(Point),
  bytes: Set(Point),
  size: Int,
) -> Nil {
  let path =
    dijkstra.get_path(queue, #(size, size))
    |> result.unwrap([])
    |> set.from_list

  list.each(list.range(0, size), fn(y) {
    list.each(list.range(0, size), fn(x) {
      case set.contains(bytes, #(x, y)), set.contains(path, #(x, y)) {
        True, False -> io.print("#")
        False, True -> io.print("O")
        False, False -> io.print(" ")
        True, True -> panic as "stepped in a byte"
      }
    })
    io.println("")
  })
}

fn find_blocking_piece(
  bytes: List(Point),
  min: Int,
  max: Int,
  size: Int,
) -> Point {
  let mid = { max - min } / 2 + min

  case max == min + 1 {
    True -> {
      list.drop(bytes, min)
      |> list.first
      |> result.unwrap(#(0, 0))
    }

    False -> {
      let byte_set = list.take(bytes, mid) |> set.from_list

      let pqueue = dijkstra.push(dijkstra.new(), 0, #(0, 0), None)
      case find_route_length(byte_set, size, pqueue) {
        Error(_) -> find_blocking_piece(bytes, min, mid, size)
        Ok(_) -> find_blocking_piece(bytes, mid, max, size)
      }
    }
  }
}
