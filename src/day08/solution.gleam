import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day08.txt"

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
  parse(lines)
  |> find_all_nodes_in_city
  |> set.size
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  parse(lines)
  |> find_all_harmonic_nodes_in_city
  |> set.size
  |> int.to_string
  |> Ok
}

type City {
  City(antennas: Dict(String, List(Point)), max: Point)
}

fn parse(lines: List(String)) -> City {
  let init = City(dict.new(), #(0, 0))

  use city, line, y <- list.index_fold(lines, init)
  let characters = string.to_graphemes(line)

  use city, c, x <- list.index_fold(characters, city)

  let p = #(x, y)
  let max = #(int.max(city.max.0, x), int.max(city.max.1, y))

  case c {
    "." -> City(city.antennas, max)
    _ -> {
      let l = dict.get(city.antennas, c) |> result.unwrap([])
      let added_antennas = dict.insert(city.antennas, c, [p, ..l])
      City(added_antennas, max)
    }
  }
}

fn find_nodes(combo: #(Point, Point)) -> #(Point, Point) {
  let forward = point.add(combo.1, point.sub(combo.1, combo.0))
  let back = point.add(combo.0, point.sub(combo.0, combo.1))

  #(forward, back)
}

fn find_all_nodes(points: List(Point)) -> set.Set(Point) {
  points
  |> list.combination_pairs
  |> list.map(find_nodes)
  |> list.fold(set.new(), fn(acc, node_pair) {
    set.insert(acc, node_pair.0)
    |> set.insert(node_pair.1)
  })
}

fn find_all_nodes_in_city(city: City) -> set.Set(Point) {
  city.antennas
  |> dict.to_list
  |> list.map(pair.second)
  |> list.fold(set.new(), fn(acc, antenna_list) {
    set.union(acc, find_all_nodes(antenna_list))
  })
  // Make sure node is in city
  |> set.filter(fn(node) {
    node.0 >= 0 && node.0 <= city.max.0 && node.1 >= 0 && node.1 <= city.max.1
  })
}

fn find_harmonic_nodes(combo: #(Point, Point), max: Point) -> set.Set(Point) {
  let diffa = point.sub(combo.1, combo.0)
  let diffb = point.mul(diffa, -1)

  let initial_list = [combo.0]

  find_bounded_points(combo.0, diffa, max, initial_list)
  |> find_bounded_points(combo.0, diffb, max, _)
  |> set.from_list
}

fn find_bounded_points(
  origin: Point,
  delta: Point,
  max: Point,
  current: List(Point),
) {
  let candidate = point.add(origin, delta)

  let xvalid = candidate.0 >= 0 && candidate.0 <= max.0
  let yvalid = candidate.1 >= 0 && candidate.1 <= max.1

  case xvalid, yvalid {
    True, True ->
      find_bounded_points(candidate, delta, max, [candidate, ..current])
    _, _ -> current
  }
}

fn find_all_harmonic_nodes_in_city(city: City) -> set.Set(Point) {
  city.antennas
  |> dict.to_list
  |> list.map(pair.second)
  |> list.fold(set.new(), fn(acc, antenna_list) {
    list.combination_pairs(antenna_list)
    |> list.map(find_harmonic_nodes(_, city.max))
    |> list.fold(set.new(), fn(node_group, node_set) {
      set.union(node_group, node_set)
    })
    |> set.union(acc)
  })
}
