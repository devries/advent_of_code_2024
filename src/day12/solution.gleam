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
  let grid = parse(lines)

  find_regions(dict.keys(grid), grid, set.new(), [])
  |> list.fold(0, fn(a, r) {
    a + { get_combined_edge_count(r) * set.size(r.positions) }
  })
  |> int.to_string
  |> Ok
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

// Return a list of regions from the input grid.
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

          let starting_list = [first]
          let new_region =
            explore(
              plants,
              starting_list,
              grid,
              set.from_list(starting_list),
              0,
            )
          find_regions(rest, grid, set.union(assigned, new_region.positions), [
            new_region,
            ..regions
          ])
        }
      }
    }
  }
}

// Explore a region looking for all connected positions with plant type of
// plants from a list of positions to explore from. Also count edges while
// doing this.
fn explore(
  plants: String,
  positions: List(Point),
  grid: Dict(Point, String),
  found: Set(Point),
  edges: Int,
) -> Region {
  case positions {
    [] -> Region(plants, found, edges)
    [first, ..rest] -> {
      let adjacents =
        list.map(point.directions, point.add(_, first))
        |> list.filter(fn(p) { set.contains(found, p) == False })

      let new_positions =
        adjacents
        |> list.filter(fn(position) { dict.get(grid, position) == Ok(plants) })

      let new_edges = list.length(adjacents) - list.length(new_positions)

      explore(
        plants,
        list.flatten([rest, new_positions]),
        grid,
        set.union(found, set.from_list(new_positions)),
        edges + new_edges,
      )
    }
  }
}

// Get the set of edges in a region with a side in a particular direction.
fn get_edge_pieces_for_direction(r: Region, d: Point) -> Set(Point) {
  r.positions
  |> set.filter(fn(pt) {
    let checkpoint = point.add(pt, d)
    set.contains(r.positions, checkpoint) == False
  })
}

// Get the number of straight edges in one direction.
fn get_combined_edge_count_for_direction(r: Region, d: Point) -> Int {
  let edges = get_edge_pieces_for_direction(r, d)

  let check_direction = point.rotate_right(d)

  // Check if an edge piece is right next to existing piece
  // with an edge in the same direction. If so, just ignore that
  // piece. This will leave one piece from each connected
  // edge.
  set.to_list(edges)
  |> list.filter(fn(pt) {
    set.contains(edges, point.add(pt, check_direction)) == False
  })
  |> list.length
}

// Get the total number of straight edges
fn get_combined_edge_count(r: Region) -> Int {
  point.directions
  |> list.fold(0, fn(sides, d) {
    sides + get_combined_edge_count_for_direction(r, d)
  })
}
