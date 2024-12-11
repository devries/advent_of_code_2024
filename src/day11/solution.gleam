import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/result
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day11.txt"

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
  use values <- result.map(parse(lines))
  values
  |> stone_count(25)
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use values <- result.map(parse(lines))

  let assert Ok(cache) = actor.start(dict.new(), handle_message)

  let result =
    list.fold(over: values, from: 0, with: fn(total, child_stone) {
      total + stone_count_memoized(child_stone, 75, cache)
    })

  process.send(cache, Shutdown)
  int.to_string(result)
}

fn parse(lines: List(String)) -> Result(List(Int), String) {
  use input <- result.try({
    list.first(lines)
    |> result.replace_error("No lines found in input")
  })

  input
  |> string.split(" ")
  |> list.map(int.parse)
  |> result.all
  |> result.replace_error("Unable to parse input")
}

fn step(x: Int) -> List(Int) {
  let assert Ok(ds) = int.digits(x, 10)
  let n = list.length(ds)

  case x, n % 2 {
    0, _ -> [1]
    _, 1 -> [x * 2024]
    _, _ -> {
      let parts = list.split(ds, n / 2)
      let assert Ok(f) = int.undigits(parts.0, 10)
      let assert Ok(s) = int.undigits(parts.1, 10)
      [f, s]
    }
  }
}

fn step_generations(stones: List(Int), generations: Int) -> List(Int) {
  case generations {
    0 -> stones
    _ -> {
      stones
      |> list.map(step)
      |> list.flatten
      |> step_generations(generations - 1)
    }
  }
}

fn stone_count(stones: List(Int), generations: Int) -> Int {
  step_generations(stones, generations)
  |> list.length
}

// I figured the same numbers would come up over and over again, especially
// for big numbers (which would be multiples of 2024 and a smaller number)
// so I decided to memoize the stone count. I had to refactor a little and
// struggled over how to save mutable state, but then I remembered that
// actors save state.

fn stone_count_memoized(
  stone: Int,
  generations: Int,
  cache: process.Subject(Message),
) -> Int {
  case generations, process.call(cache, Get(_, stone, generations), 100) {
    0, _ -> 1
    _, Ok(n) -> n
    _, _ -> {
      let result =
        list.fold(over: step(stone), from: 0, with: fn(total, child_stone) {
          total + stone_count_memoized(child_stone, generations - 1, cache)
        })

      process.send(cache, Put(stone, generations, result))
      result
    }
  }
}

// Memoization in Gleam threw me for a loop, but an actor can hold
// the information I need. Below are the building blocks of an
// actor that holds a dict with a stone number and generations as
// a key, and the total count of stones will be descended from it
// after than many generations.

pub type Message {
  Put(value: Int, generations: Int, count: Int)
  Get(reply_with: Subject(Result(Int, Nil)), value: Int, generations: Int)
  Shutdown
}

pub fn handle_message(message: Message, current: Dict(#(Int, Int), Int)) {
  case message {
    Put(v, g, c) -> actor.continue(dict.insert(current, #(v, g), c))
    Get(client, v, g) -> {
      process.send(client, dict.get(current, #(v, g)))
      actor.continue(current)
    }
    Shutdown -> actor.Stop(process.Normal)
  }
}
