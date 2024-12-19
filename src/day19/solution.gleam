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
  |> list.map(find_sequence_count(trie, cache, _))
  |> list.filter(fn(s) { s != 0 })
  |> list.length
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let #(trie, patterns) = parse(lines)

  use cache <- memoize.with_cache()

  patterns
  |> list.map(find_sequence_count(trie, cache, _))
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

fn find_sequence_count(
  trie: Dict(String, Node),
  cache: memoize.Cache(List(String), Int),
  pattern: String,
) -> Int {
  let g = string.to_graphemes(pattern)
  recurse_counter(trie, cache, [g], 0)
}

fn find_possible_heads(
  trie: Dict(String, Node),
  remaining: List(String),
  stack: List(#(String, List(String))),
) -> List(#(String, List(String))) {
  case remaining {
    [first, ..rest] -> {
      case dict.get(trie, first) {
        Ok(Next(subtrie)) -> find_possible_heads(subtrie, rest, stack)
        Ok(End(subtrie, value)) ->
          find_possible_heads(subtrie, rest, [#(value, rest), ..stack])
        Error(Nil) -> stack
      }
    }
    [] -> stack
  }
}

fn recurse_counter(
  trie: Dict(String, Node),
  cache: memoize.Cache(List(String), Int),
  stack: List(List(String)),
  done: Int,
) -> Int {
  case stack {
    [first, ..rest] -> {
      case first {
        [] -> recurse_counter(trie, cache, rest, done + 1)
        _ -> {
          let desc = cached_count(trie, cache, first)
          recurse_counter(trie, cache, rest, done + desc)
        }
      }
    }
    [] -> done
  }
}

fn cached_count(
  trie: Dict(String, Node),
  cache: memoize.Cache(List(String), Int),
  sequence: List(String),
) -> Int {
  use <- memoize.cache_check(cache, sequence)

  let new_ones =
    find_possible_heads(trie, sequence, [])
    |> list.map(fn(mtup) { mtup.1 })
  recurse_counter(trie, cache, new_ones, 0)
}
