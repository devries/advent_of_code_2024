import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/string
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day21.txt"

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

// +---+---+---+
// | 7 | 8 | 9 |
// +---+---+---+
// | 4 | 5 | 6 |
// +---+---+---+
// | 1 | 2 | 3 |
// +---+---+---+
//     | 0 | A |
//     +---+---+
//
// ^, >, <, v <- order for keypad
//
//     +---+---+
//     | ^ | A |
// +---+---+---+
// | < | v | > |
// +---+---+---+
//
// v, >, <, ^ <- order for directional keypad
//
// ^ -> <A>A   
// < -> v<<A>>^A
// v -> v<A>^A
// > -> vA^A

// 379A
// ^A^^<<A>>AvvvA
//               12345678 1 123456789 1 12345678
// ^       A     ^        ^ <         < A         >     >A   v        vvA 
// <   A   > A   <   A    A v  < A    A > >^  A   v  A  A^ A v  < A   AA> ^  A
// v<<A>>^AvA^A  v<<A>>^A A v<A<A>>^A A vAA<^A>A  v<A>^AA<A>Av<A<A>>^AAAvA<^A>A
// <v<A>>^AvA^A  <vA<AA>>^A A vA<^A>A A vA^A       <vA>^AA<A>A<v<A>A>^AAAvA<^A>A
// <   A   > A   v  < <A    A > ^  A  A >  A       v  A  A^ A <   v A  AA> ^  A
// ^       A     <          < ^       ^ A          >     >A   v        vvA 
//               1234567890 1 1234567 1 1234
// ^A<<^^A>>AvvvA

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  list.map(lines, fn(line) {
    decode_numeric_sequence(line)
    |> io.debug
    |> decode_directional_sequence
    |> io.debug
    |> decode_directional_sequence
    |> io.debug
    |> string.length
    |> io.debug
  })

  todo
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  Error("Unimplemented")
}

fn decode_numeric_sequence(sequence: String) -> String {
  string.to_graphemes("A" <> sequence)
  |> list.window_by_2
  |> list.map(fn(pair) { find_motion_numeric(pair.0, pair.1) })
  |> string.join("")
}

fn decode_directional_sequence(sequence: String) -> String {
  string.to_graphemes("A" <> sequence)
  |> list.window_by_2
  |> list.map(fn(pair) { find_motion_directional(pair.0, pair.1) })
  |> string.join("")
}

fn find_motion_directional(start: String, push: String) -> String {
  let assert Ok(start_pos) = get_directional_position(start)
  let assert Ok(push_pos) = get_directional_position(push)

  let right_count = push_pos.0 - start_pos.0
  let up_count = push_pos.1 - start_pos.1

  let horizontal = case int.compare(start_pos.0, push_pos.0) {
    order.Lt -> string.join(list.repeat(">", right_count), "")
    order.Eq -> ""
    order.Gt -> string.join(list.repeat("<", -right_count), "")
  }

  case int.compare(start_pos.1, push_pos.1) {
    order.Lt -> {
      // Go up first then left or right
      horizontal <> string.join(list.repeat("^", up_count), "") <> "A"
    }
    order.Eq -> {
      // Go left or right
      horizontal <> "A"
    }
    order.Gt -> {
      // Go left or right first, then down
      string.join(list.repeat("v", -up_count), "") <> horizontal <> "A"
    }
  }
}

fn find_motion_numeric(start: String, push: String) -> String {
  let assert Ok(start_pos) = get_numeric_position(start)
  let assert Ok(push_pos) = get_numeric_position(push)

  let right_count = push_pos.0 - start_pos.0
  let up_count = push_pos.1 - start_pos.1

  let horizontal = case int.compare(start_pos.0, push_pos.0) {
    order.Lt -> string.join(list.repeat(">", right_count), "")
    order.Eq -> ""
    order.Gt -> string.join(list.repeat("<", -right_count), "")
  }

  case int.compare(start_pos.1, push_pos.1) {
    order.Lt -> {
      // Go up first then left or right
      string.join(list.repeat("^", up_count), "") <> horizontal <> "A"
    }
    order.Eq -> {
      // Go left or right
      horizontal <> "A"
    }
    order.Gt -> {
      // Go left or right first, then down
      horizontal <> string.join(list.repeat("v", -up_count), "") <> "A"
    }
  }
}

fn get_directional_position(key: String) -> Result(Point, Nil) {
  case key {
    "^" -> Ok(#(1, 1))
    "A" -> Ok(#(2, 1))
    "<" -> Ok(#(0, 0))
    "v" -> Ok(#(1, 0))
    ">" -> Ok(#(2, 0))
    _ -> Error(Nil)
  }
}

fn get_numeric_position(key: String) -> Result(Point, Nil) {
  case key {
    "7" -> Ok(#(0, 3))
    "8" -> Ok(#(1, 3))
    "9" -> Ok(#(2, 3))
    "4" -> Ok(#(0, 2))
    "5" -> Ok(#(1, 2))
    "6" -> Ok(#(2, 2))
    "1" -> Ok(#(0, 1))
    "2" -> Ok(#(1, 1))
    "3" -> Ok(#(2, 1))
    "0" -> Ok(#(1, 0))
    "A" -> Ok(#(2, 0))
    _ -> Error(Nil)
  }
}
