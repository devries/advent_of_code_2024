import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import internal/aoc_utils
import internal/memoize

pub fn main() {
  let filename = "inputs/day19.txt"

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
  let #(trie, patterns) = parse(lines)

  use cache <- memoize.with_cache()

  patterns
  |> list.map(find_sequence(trie, cache, _))
  |> list.filter(fn(s) { s != [] })
  |> list.length
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let #(trie, patterns) = parse(lines)

  use cache <- memoize.with_cache()

  patterns
  |> list.map(find_sequence(trie, cache, _))
  |> list.filter(fn(s) { s != [] })
  |> list.map(list.length)
  |> int.sum
  |> int.to_string
  |> Ok
}

type Node {
  End(subvalues: Dict(String, Node), value: String)
  Next(subvalues: Dict(String, Node))
}

fn add_towel(root: Dict(String, Node), towel: String) -> Dict(String, Node) {
  let g = string.to_graphemes(towel)
  add_towel_acc(root, towel, g)
}

fn add_towel_acc(
  root: Dict(String, Node),
  towel: String,
  remaining: List(String),
) -> Dict(String, Node) {
  case remaining {
    [only] -> {
      case dict.get(root, only) {
        Ok(node) -> dict.insert(root, only, End(node.subvalues, towel))
        Error(_) -> dict.insert(root, only, End(dict.new(), towel))
      }
    }
    [first, ..rest] -> {
      let existing = dict.get(root, first) |> result.unwrap(Next(dict.new()))

      case existing {
        Next(subvalues) -> {
          dict.insert(root, first, Next(add_towel_acc(subvalues, towel, rest)))
        }
        End(subvalues, value) -> {
          dict.insert(
            root,
            first,
            End(add_towel_acc(subvalues, towel, rest), value),
          )
        }
      }
    }
    [] -> panic as "I shouldn't even be here"
  }
}

fn parse(lines: List(String)) -> #(Dict(String, Node), List(String)) {
  let assert [towels, patterns] = aoc_utils.chunk_around_empty_strings(lines)

  #(parse_towels(towels), patterns)
}

fn parse_towels(lines: List(String)) -> Dict(String, Node) {
  string.concat(lines)
  |> string.split(", ")
  |> list.fold(dict.new(), add_towel)
}

fn find_sequence(
  trie: Dict(String, Node),
  cache: memoize.Cache(List(String), List(List(String))),
  pattern: String,
) -> List(List(String)) {
  let g = string.to_graphemes(pattern)
  recurse_trie(trie, cache, [#([], g)], [])
  |> io.debug
}

fn find_sequence_acc(
  trie: Dict(String, Node),
  remaining: List(String),
  stack: List(#(String, List(String))),
) -> List(#(String, List(String))) {
  case remaining {
    [first, ..rest] -> {
      case dict.get(trie, first) {
        Ok(Next(subtrie)) -> find_sequence_acc(subtrie, rest, stack)
        Ok(End(subtrie, value)) ->
          find_sequence_acc(subtrie, rest, [#(value, rest), ..stack])
        Error(Nil) -> stack
      }
    }
    [] -> stack
  }
}

fn recurse_trie(
  trie: Dict(String, Node),
  cache: memoize.Cache(List(String), List(List(String))),
  stack: List(#(List(String), List(String))),
  done: List(List(String)),
) -> List(List(String)) {
  case stack {
    [first, ..rest] -> {
      case first.1 {
        [] -> {
          recurse_trie(trie, cache, rest, [first.0, ..done])
          // [first.0, ..done]
        }
        _ -> {
          let desc =
            cached_list(trie, cache, first.1)
            |> list.map(fn(d) { list.flatten([first.0, d]) })
          recurse_trie(trie, cache, rest, list.flatten([desc, done]))
        }
      }
    }
    [] -> done
  }
}

fn cached_list(
  trie: Dict(String, Node),
  cache: memoize.Cache(List(String), List(List(String))),
  sequence: List(String),
) -> List(List(String)) {
  use <- memoize.cache_check(cache, sequence)

  let new_ones =
    find_sequence_acc(trie, sequence, [])
    |> list.map(fn(mtup) { #([mtup.0], mtup.1) })
  recurse_trie(trie, cache, new_ones, [])
}
