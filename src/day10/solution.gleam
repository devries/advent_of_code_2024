import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day10.txt"

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
  let grid = parse(lines)

  let trailheads = find_trailheads(grid)

  list.map(trailheads, find_path_ends(grid, _))
  |> list.map(list.length)
  |> int.sum
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let grid = parse(lines)

  let trailheads = find_trailheads(grid)

  list.map(trailheads, find_path_rating(grid, _))
  |> int.sum
  |> int.to_string
  |> Ok
}

fn parse(lines: List(String)) -> Dict(Point, Int) {
  use grid, line, y <- list.index_fold(lines, dict.new())
  let characters = string.to_graphemes(line)

  use grid, c, x <- list.index_fold(characters, grid)

  let p = #(x, y)
  let assert Ok(v) = int.parse(c)
  dict.insert(grid, p, v)
}

fn find_trailheads(grid: Dict(Point, Int)) -> List(Point) {
  grid
  |> dict.fold([], fn(found, p, v) {
    case v {
      0 -> [p, ..found]
      _ -> found
    }
  })
}

fn find_path_ends(grid: Dict(Point, Int), start: Point) -> List(Point) {
  find_path_ends_iterator(grid, [start], set.new(), set.new())
  |> set.to_list
}

fn find_path_ends_iterator(
  grid: Dict(Point, Int),
  search: List(Point),
  seen: set.Set(Point),
  found: set.Set(Point),
) -> set.Set(Point) {
  case search {
    [] -> found
    [first, ..rest] -> {
      // Have we seen this point, if so continue on
      case set.contains(seen, first) {
        True -> find_path_ends_iterator(grid, rest, seen, found)
        False -> {
          // Is this a trail end, or off map?
          case dict.get(grid, first) {
            Ok(9) ->
              // End point, record it as seen and as found
              find_path_ends_iterator(
                grid,
                rest,
                set.insert(seen, first),
                set.insert(found, first),
              )
            // This condition should never happen as we are selecting only grid points for search
            Error(_) -> find_path_ends_iterator(grid, rest, seen, found)
            Ok(v) -> {
              // New point, find neighbors that are one higher and add to search
              let candidates =
                list.map(point.directions, point.add(_, first))
                |> list.filter(fn(point) {
                  let filter_val = v + 1
                  case dict.get(grid, point) {
                    Ok(new_val) if new_val == filter_val -> True
                    _ -> False
                  }
                })
              find_path_ends_iterator(
                grid,
                list.append(candidates, rest),
                set.insert(seen, first),
                found,
              )
            }
          }
        }
      }
    }
  }
}

fn find_path_rating(grid: Dict(Point, Int), start: Point) -> Int {
  find_path_rating_iterator(grid, [start], 0)
}

fn find_path_rating_iterator(
  grid: Dict(Point, Int),
  search: List(Point),
  found: Int,
) -> Int {
  case search {
    [] -> found
    [first, ..rest] -> {
      // Is this a trail end, or off map?
      case dict.get(grid, first) {
        Ok(9) -> find_path_rating_iterator(grid, rest, found + 1)
        // This should never happen because we only add grid points to search stack
        Error(_) -> find_path_rating_iterator(grid, rest, found)
        Ok(v) -> {
          // New point, find neighbors that are one higher and add to search
          let candidates =
            list.map(point.directions, point.add(_, first))
            |> list.filter(fn(point) {
              let filter_val = v + 1
              case dict.get(grid, point) {
                Ok(new_val) if new_val == filter_val -> True
                _ -> False
              }
            })
          find_path_rating_iterator(grid, list.append(candidates, rest), found)
        }
      }
    }
  }
}
