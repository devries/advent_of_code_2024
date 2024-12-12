import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import gleam/string
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day12.txt"

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

  find_regions(dict.keys(grid), grid, set.new(), [])
  |> list.fold(0, fn(a, r) { a + { set.size(r.positions) * r.perimeter } })
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  Error("Unimplemented")
}

fn parse(lines: List(String)) -> Dict(Point, String) {
  use grid, line, y <- list.index_fold(lines, dict.new())
  let characters = string.to_graphemes(line)

  use grid, c, x <- list.index_fold(characters, grid)

  let p = #(x, y)
  dict.insert(grid, p, c)
}

type Region {
  Region(plants: String, positions: Set(Point), perimeter: Int)
}

fn find_regions(
  positions: List(Point),
  grid: Dict(Point, String),
  assigned: set.Set(Point),
  regions: List(Region),
) -> List(Region) {
  case positions {
    [] -> regions
    [first, ..rest] -> {
      case set.contains(assigned, first) {
        True -> find_regions(rest, grid, assigned, regions)
        False -> {
          let assert Ok(plants) = dict.get(grid, first)
          let new_region = explore(plants, [first], grid, set.new(), 0)
          find_regions(rest, grid, set.union(assigned, new_region.positions), [
            new_region,
            ..regions
          ])
        }
      }
    }
  }
}

fn explore(
  plants: String,
  positions: List(Point),
  grid: Dict(Point, String),
  seen: Set(Point),
  edges: Int,
) -> Region {
  case positions {
    [] -> Region(plants, seen, edges)
    [first, ..rest] -> {
      case set.contains(seen, first) {
        False -> {
          let adjacents =
            list.map(point.directions, point.add(_, first))
            |> list.filter(fn(p) { set.contains(seen, p) == False })

          let new_positions =
            adjacents
            |> list.filter(fn(position) {
              dict.get(grid, position) == Ok(plants)
            })

          let new_edges = list.length(adjacents) - list.length(new_positions)

          explore(
            plants,
            list.flatten([rest, new_positions]),
            grid,
            set.insert(seen, first),
            edges + new_edges,
          )
        }
        True -> explore(plants, rest, grid, seen, edges)
      }
    }
  }
}
