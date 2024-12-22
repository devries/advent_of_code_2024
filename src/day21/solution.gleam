import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import internal/aoc_utils
import internal/memoize
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
    let length =
      decode_numeric_sequence(line)
      |> decode_directional_sequence
      |> decode_directional_sequence
      |> string.length

    get_numeric_portions(line) * length
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  // I think I will need to memoize, but I need to figure out what.
  use cache <- memoize.with_cache()

  list.map(lines, fn(line) {
    let length =
      decode_numeric_sequence(line)
      |> count_directional_sequence(25, cache)

    get_numeric_portions(line) * length
  })
  |> int.sum
  |> int.to_string
  |> Ok
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

fn count_directional_sequence(
  starting: String,
  depth: Int,
  cache: memoize.Cache(#(String, String, Int), Int),
) -> Int {
  case depth {
    0 -> string.length(starting)
    _ -> {
      string.to_graphemes("A" <> starting)
      |> list.window_by_2
      |> list.map(fn(pair) {
        count_motion_directional(pair.0, pair.1, depth, cache)
      })
      |> int.sum
    }
  }
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

  let vertical = case int.compare(start_pos.1, push_pos.1) {
    order.Lt -> string.join(list.repeat("^", up_count), "")
    order.Eq -> ""
    order.Gt -> string.join(list.repeat("v", -up_count), "")
  }

  case start_pos, push_pos, optimal_first_motion(start_pos, push_pos) {
    #(_, 1), #(0, _), _ -> vertical <> horizontal <> "A"
    #(0, _), #(_, 1), _ -> horizontal <> vertical <> "A"
    _, _, Horizontal -> horizontal <> vertical <> "A"
    _, _, Vertical -> vertical <> horizontal <> "A"
  }
}

fn count_motion_directional(
  start: String,
  push: String,
  depth: Int,
  cache: memoize.Cache(#(String, String, Int), Int),
) -> Int {
  use <- memoize.cache_check(cache, #(start, push, depth))

  let assert Ok(start_pos) = get_directional_position(start)
  let assert Ok(push_pos) = get_directional_position(push)

  let right_count = push_pos.0 - start_pos.0
  let up_count = push_pos.1 - start_pos.1

  let horizontal = case int.compare(start_pos.0, push_pos.0) {
    order.Lt -> string.join(list.repeat(">", right_count), "")
    order.Eq -> ""
    order.Gt -> string.join(list.repeat("<", -right_count), "")
  }

  let vertical = case int.compare(start_pos.1, push_pos.1) {
    order.Lt -> string.join(list.repeat("^", up_count), "")
    order.Eq -> ""
    order.Gt -> string.join(list.repeat("v", -up_count), "")
  }

  let next = case
    start_pos,
    push_pos,
    optimal_first_motion(start_pos, push_pos)
  {
    #(_, 1), #(0, _), _ -> vertical <> horizontal <> "A"
    #(0, _), #(_, 1), _ -> horizontal <> vertical <> "A"
    _, _, Horizontal -> horizontal <> vertical <> "A"
    _, _, Vertical -> vertical <> horizontal <> "A"
  }

  count_directional_sequence(next, depth - 1, cache)
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

  let vertical = case int.compare(start_pos.1, push_pos.1) {
    order.Lt -> string.join(list.repeat("^", up_count), "")
    order.Eq -> ""
    order.Gt -> string.join(list.repeat("v", -up_count), "")
  }

  case start_pos, push_pos, optimal_first_motion(start_pos, push_pos) {
    #(_, 0), #(0, _), _ -> vertical <> horizontal <> "A"
    #(0, _), #(_, 0), _ -> horizontal <> vertical <> "A"
    _, _, Horizontal -> horizontal <> vertical <> "A"
    _, _, Vertical -> vertical <> horizontal <> "A"
  }
}

type Motion {
  Horizontal
  Vertical
}

// It looked like the best case solution, based on part 1 was to
// do motion of the directional farthest from the "A" key first, then
// the nearer one second. But it also seems like if you are going
// right and up you need to start with vertical motion.
// I have no idea why.
fn optimal_first_motion(start: Point, end: Point) -> Motion {
  case int.compare(start.0, end.0), int.compare(start.1, end.1) {
    order.Lt, order.Lt -> {
      // Right and up
      Vertical
    }
    order.Gt, order.Lt -> {
      // Left and up
      Horizontal
    }
    order.Lt, order.Gt -> {
      // Right and down
      Vertical
    }
    order.Gt, order.Gt -> {
      // Left and down
      Horizontal
    }
    _, _ -> Horizontal
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

fn get_numeric_portions(s: String) -> Int {
  string.drop_end(s, 1)
  |> int.parse
  |> result.unwrap(0)
}
