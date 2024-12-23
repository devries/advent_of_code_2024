import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day23.txt"

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
  let conn = parse(lines)

  dict.keys(conn)
  |> list.filter(fn(item) { string.starts_with(item, "t") })
  |> list.map(find_cycles(_, 3, conn))
  |> list.fold(set.new(), fn(combined, single) { set.union(combined, single) })
  |> set.size
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let conn = parse(lines)

  let cycles =
    dict.keys(conn)
    |> list.map(find_cycles(_, 3, conn))
    |> list.fold(set.new(), fn(combined, single) { set.union(combined, single) })
    |> set.to_list

  let connset =
    dict.to_list(conn)
    |> list.map(fn(tup) { #(tup.0, set.from_list(tup.1)) })
    |> dict.from_list

  largest_group(cycles, connset, set.new())
  |> set.to_list
  |> list.sort(string.compare)
  |> string.join(",")
  |> Ok
}

fn parse(lines: List(String)) -> Dict(String, List(String)) {
  lines
  |> list.map(string.split(_, "-"))
  |> list.fold(dict.new(), fn(connections, values) {
    case values {
      [a, b] -> {
        let alist = dict.get(connections, a) |> result.unwrap([])
        let blist = dict.get(connections, b) |> result.unwrap([])

        let connections = dict.insert(connections, a, [b, ..alist])
        dict.insert(connections, b, [a, ..blist])
      }
      _ -> connections
    }
  })
}

fn find_cycles(
  start: String,
  length: Int,
  conn: Dict(String, List(String)),
) -> Set(Set(String)) {
  find_cycles_acc([start], length, conn, start, set.new(), set.new())
}

fn find_cycles_acc(
  search: List(String),
  length: Int,
  conn: Dict(String, List(String)),
  end: String,
  prev: Set(String),
  found: Set(Set(String)),
) -> Set(Set(String)) {
  case search {
    [first, ..rest] -> {
      let next =
        dict.get(conn, first)
        |> result.unwrap([])

      case length == 1 {
        True -> {
          // Add found set where next element is the end element
          case list.contains(next, end) {
            True ->
              find_cycles_acc(
                rest,
                length,
                conn,
                end,
                prev,
                set.insert(found, set.insert(prev, first)),
              )
            False -> find_cycles_acc(rest, length, conn, end, prev, found)
          }
        }
        False -> {
          // continue traversing the cycle, ignoring where we've already been
          let found =
            find_cycles_acc(
              list.filter(next, fn(item) { !set.contains(prev, item) }),
              length - 1,
              conn,
              end,
              set.insert(prev, first),
              found,
            )
          find_cycles_acc(rest, length, conn, end, prev, found)
        }
      }
    }
    [] -> found
  }
}

// Starting from a group, find another computer which is connected to every
// computer in the group, then continue to grow from that larger group until
// no further systems can be added.
fn grow(group: Set(String), connset: Dict(String, Set(String))) -> Set(String) {
  // find largest set containing group
  let candidates =
    group
    |> set.fold(None, fn(u, vertex) {
      case u {
        None -> {
          dict.get(connset, vertex)
          |> result.lazy_unwrap(set.new)
          |> Some
        }
        Some(u) ->
          set.intersection(
            u,
            dict.get(connset, vertex) |> result.lazy_unwrap(set.new),
          )
          |> Some
      }
    })
    |> option.lazy_unwrap(set.new)
    |> set.difference(group)
    |> set.to_list
    |> list.first

  case candidates {
    Ok(c) -> grow(set.insert(group, c), connset)
    Error(Nil) -> group
  }
}

// If a cycle is contained entirely within the group we found, it will only
// grow to be that same group, so we can ignore it and test other cycles.
fn prune(group: Set(String), cycles: List(Set(String))) -> List(Set(String)) {
  // remove cycles within group
  list.filter(cycles, fn(c) { !set.is_subset(c, group) })
}

// Start growing from each cycle to find the largest group
// pruning searched cycles at each step.
fn largest_group(
  cycles: List(Set(String)),
  connset: Dict(String, Set(String)),
  largest: Set(String),
) -> Set(String) {
  // Search all cycles for largest group
  case cycles {
    [first, ..rest] -> {
      let candidate = grow(first, connset)
      let remaining = prune(candidate, rest)
      case set.size(candidate) > set.size(largest) {
        True -> largest_group(remaining, connset, candidate)
        False -> largest_group(remaining, connset, largest)
      }
    }
    [] -> largest
  }
}
