import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day05.txt"

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
  use #(ruleset, pagesets) <- result.try(parse(lines))

  use middle_element_strings <- result.try({
    pagesets
    |> list.filter(fn(pageset) {
      pageset
      |> list.combination_pairs
      |> list.map(make_opposing_rule)
      |> set.from_list
      |> set.is_disjoint(ruleset)
    })
    |> list.map(get_middle)
    |> result.all
  })

  use middle_elements <- result.map({
    middle_element_strings
    |> list.map(int.parse)
    |> result.all
    |> result.replace_error("Unable to parse middle elements")
  })

  int.sum(middle_elements)
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use #(ruleset, pagesets) <- result.try(parse(lines))

  let reordered_pagesets =
    pagesets
    |> list.filter(fn(pageset) {
      pageset
      |> list.combination_pairs
      |> list.map(make_opposing_rule)
      |> set.from_list
      |> set.is_disjoint(ruleset)
      |> bool.negate
    })
    |> list.map(reorder_list(_, ruleset))

  use middle_element_strings <- result.try({
    reordered_pagesets
    |> list.map(get_middle)
    |> result.all
  })

  use middle_elements <- result.map({
    middle_element_strings
    |> list.map(int.parse)
    |> result.all
    |> result.replace_error("Unable to parse middle integers")
  })

  int.sum(middle_elements)
  |> int.to_string
}

fn parse(
  lines: List(String),
) -> Result(#(Set(String), List(List(String))), String) {
  case aoc_utils.chunk_around_empty_strings(lines) {
    [rules, pagesets] -> {
      Ok(#(set.from_list(rules), list.map(pagesets, string.split(_, ","))))
    }
    _ -> Error("unable to parse input")
  }
}

// This creates a rule which would conflict with the pages in the order given
fn make_opposing_rule(p: #(String, String)) -> String {
  p.1 <> "|" <> p.0
}

fn get_middle(items: List(a)) -> Result(a, String) {
  let length = list.length(items)

  items
  |> list.drop(length / 2)
  |> list.first
  |> result.replace_error("Unable to find middle of " <> string.inspect(items))
}

fn reorder_list(pages: List(String), ruleset: Set(String)) -> List(String) {
  let bad_pair =
    pages
    |> list.combination_pairs
    |> list.fold_until(Error(Nil), fn(_, pair) {
      // On first instance of a pair that is in the wrong order return it
      let found =
        make_opposing_rule(pair)
        |> set.contains(ruleset, _)
      case found {
        True -> list.Stop(Ok(pair))
        False -> list.Continue(Error(Nil))
      }
    })

  case bad_pair {
    Error(Nil) -> pages
    Ok(vals) -> {
      // This swaps the two elements that are out of order
      list.map(pages, fn(page) {
        case page {
          p if p == vals.0 -> vals.1
          p if p == vals.1 -> vals.0
          _ -> page
        }
      })
      |> reorder_list(ruleset)
    }
  }
}
