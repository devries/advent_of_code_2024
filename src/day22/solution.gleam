import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/yielder
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day22.txt"

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
  use numberlist <- result.map({
    lines
    |> list.try_map(int.parse)
    |> result.replace_error("Unable to parse input")
  })

  numberlist
  |> list.map(step_times(_, 2000))
  |> int.sum
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use numberlist <- result.try({
    lines
    |> list.try_map(int.parse)
    |> result.replace_error("Unable to parse input")
  })

  use best_pair <- result.map({
    numberlist
    |> list.map(find_sequence_sets(_, 2000))
    |> list.map(build_values)
    |> list.fold(dict.new(), fn(da, d) {
      dict.to_list(d)
      |> list.fold(da, fn(da, tup) {
        let #(seq, price) = tup
        let value = dict.get(da, seq) |> result.unwrap(0)
        dict.insert(da, seq, value + price)
      })
    })
    |> dict.to_list
    |> list.reduce(fn(max, o) {
      case int.compare(o.1, max.1) {
        order.Gt -> o
        _ -> max
      }
    })
    |> result.replace_error("Something went wront")
  })

  pair.second(best_pair)
  |> int.to_string
}

pub fn step(start: Int) -> Int {
  let first = int.bitwise_exclusive_or({ start * 64 }, start) % 16_777_216
  let second = int.bitwise_exclusive_or({ first / 32 }, first) % 16_777_216
  int.bitwise_exclusive_or({ second * 2048 }, second) % 16_777_216
}

fn step_times(start: Int, times: Int) -> Int {
  case times {
    0 -> start
    n -> step_times(step(start), n - 1)
  }
}

fn price_sequence(start: Int, length: Int) -> List(Int) {
  yielder.unfold(start, fn(v) {
    let r = step(v)
    yielder.Next(v, r)
  })
  |> yielder.take(length + 1)
  |> yielder.to_list
  |> list.map(fn(v) { v % 10 })
}

fn differences(numbers: List(Int)) -> List(Int) {
  list.window_by_2(numbers)
  |> list.map(fn(tup) { tup.1 - tup.0 })
}

fn find_sequence_sets(start: Int, length: Int) -> List(#(Int, List(Int))) {
  let prices = price_sequence(start, length)

  let sequences = differences(prices) |> list.window(4)

  // Zip into tuples the price, and the sequence to get to that price.
  list.zip(list.drop(prices, 4), sequences)
}

fn build_values(sequences: List(#(Int, List(Int)))) -> Dict(List(Int), Int) {
  list.fold(sequences, dict.new(), fn(d, tup) {
    let #(price, sequence) = tup

    // In this case I am only interested in the first sequence that
    // results in the given price. If I encounter the sequence again
    // in the list I skip it and do not add it to the dictionary.

    case dict.get(d, sequence) {
      Ok(_) -> d
      Error(Nil) -> {
        dict.insert(d, sequence, price)
      }
    }
  })
}
