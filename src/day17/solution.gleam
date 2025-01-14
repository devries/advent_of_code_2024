import envoy
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day17.txt"

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
  use #(c, prog) <- result.map(parse(lines))
  run_until_done(c, prog)
  |> list.map(int.to_string)
  |> string.join(",")
}

// Part 2

// My program dissassembled
// bst A  -> Write A -> B                                  B is lowest 3 bits of A
// bxl 1  -> Flip lowest bit of  B.                        B is A with lowest bit flip
// cdv B  -> A/2^B -> C (Shift A right B and store to C)   
// adv 3  -> A/2^3 -> A (Shift A right 3)                  A shifts by one 3 bit byte
// bxl 4  -> Flip third bit of B                           
// bxc 0  -> XOR B and C and store to B                    
// out B  -> Output B % 8                                  Last 3 bits of B
// jnz 0  -> Jump to 0 if A != 0                           A must be 0 at end

pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use #(_, prog) <- result.map(parse(lines))

  case envoy.get("AOC_DEBUG") {
    Ok(_) -> dissassemble(prog, 0)
    _ -> Nil
  }

  let matches =
    prog
    |> dict.to_list
    |> list.sort(fn(ta, tb) { int.compare(tb.0, ta.0) })
    |> list.map(pair.second)

  find_a(prog, 0, matches)
  |> int.to_string
}

type Computer {
  Computer(
    register_a: Int,
    register_b: Int,
    register_c: Int,
    ip: Int,
    output_buffer: List(Int),
  )
}

fn new_computer(a: Int, b: Int, c: Int) -> Computer {
  Computer(a, b, c, 0, [])
}

// Parse input returning computer with initial state and instructions.
fn parse(lines: List(String)) -> Result(#(Computer, Dict(Int, Int)), String) {
  use #(rline, pline) <- result.try({
    case aoc_utils.chunk_around_empty_strings(lines) {
      [register_line, program_line] ->
        Ok(#(register_line, string.concat(program_line)))
      _ -> Error("Unable to parse input")
    }
  })

  use rlist <- result.try({
    list.map(rline, get_register_value)
    |> result.all
    |> result.replace_error("Unable to parse registers")
  })

  use program <- result.try(parse_program(pline))

  case rlist {
    [a, b, c] -> Ok(#(new_computer(a, b, c), program))
    _ -> Error("Wrong register number")
  }
}

fn get_register_value(line: String) -> Result(Int, Nil) {
  case string.split(line, ": ") {
    [_, val] -> int.parse(val)
    _ -> Error(Nil)
  }
}

fn parse_program(line: String) -> Result(Dict(Int, Int), String) {
  use values <- result.map({
    line
    |> string.replace("Program: ", "")
    |> string.split(",")
    |> list.map(int.parse)
    |> result.all
    |> result.replace_error("Unable to parse instructions")
  })

  list.index_map(values, fn(v, idx) { #(idx, v) })
  |> dict.from_list
}

type Running {
  Run(Computer)
  Halt(Computer)
}

fn step(c: Computer, prog: Dict(Int, Int)) -> Running {
  case dict.get(prog, c.ip), dict.get(prog, c.ip + 1) {
    // adv instruction
    Ok(0), Ok(v) -> {
      let r = c.register_a / int.product(list.repeat(2, combo(c, v)))
      Run(Computer(..c, register_a: r, ip: c.ip + 2))
    }

    // bxl instruction
    Ok(1), Ok(v) -> {
      let r = int.bitwise_exclusive_or(c.register_b, v)
      Run(Computer(..c, register_b: r, ip: c.ip + 2))
    }

    // bst instruction
    Ok(2), Ok(v) -> {
      let r = combo(c, v) % 8
      Run(Computer(..c, register_b: r, ip: c.ip + 2))
    }

    // jnz instruction
    Ok(3), Ok(v) -> {
      let ip = case c.register_a {
        0 -> c.ip + 2
        _ -> v
      }
      Run(Computer(..c, ip: ip))
    }

    // bxc instruction
    Ok(4), _ -> {
      let r = int.bitwise_exclusive_or(c.register_b, c.register_c)
      Run(Computer(..c, register_b: r, ip: c.ip + 2))
    }

    // out instruction
    Ok(5), Ok(v) -> {
      Run(
        Computer(..c, ip: c.ip + 2, output_buffer: [
          combo(c, v) % 8,
          ..c.output_buffer
        ]),
      )
    }

    // bdv instruction
    Ok(6), Ok(v) -> {
      let r = c.register_a / int.product(list.repeat(2, combo(c, v)))
      Run(Computer(..c, register_b: r, ip: c.ip + 2))
    }

    // cdv instruction
    Ok(7), Ok(v) -> {
      let r = c.register_a / int.product(list.repeat(2, combo(c, v)))
      Run(Computer(..c, register_c: r, ip: c.ip + 2))
    }

    // No instruction or invalid instruction
    _, _ -> Halt(c)
  }
}

fn combo(c: Computer, v: Int) -> Int {
  case v {
    l if l <= 3 -> l
    4 -> c.register_a
    5 -> c.register_b
    6 -> c.register_c
    _ -> panic as "bad combo operand"
  }
}

fn run_until_done(c: Computer, prog: Dict(Int, Int)) -> List(Int) {
  case step(c, prog) {
    Run(nc) -> run_until_done(nc, prog)
    Halt(nc) -> list.reverse(nc.output_buffer)
  }
}

fn dissassemble(prog: Dict(Int, Int), inst: Int) -> Nil {
  case dict.get(prog, inst), dict.get(prog, inst + 1) {
    Ok(i), Ok(v) -> {
      let opcode = case i {
        0 | 2 | 5 | 6 | 7 -> combo_opcode(v)
        _ -> int.to_string(v)
      }

      let itxt = case i {
        0 -> "adv"
        1 -> "bxl"
        2 -> "bst"
        3 -> "jnz"
        4 -> "bxc"
        5 -> "out"
        6 -> "bdv"
        7 -> "cdv"
        _ -> panic as "unknown instruction"
      }

      io.println(itxt <> " " <> opcode)
      dissassemble(prog, inst + 2)
    }
    _, _ -> Nil
  }
}

fn combo_opcode(i: Int) -> String {
  case i {
    l if l <= 3 -> int.to_string(l)
    4 -> "A"
    5 -> "B"
    6 -> "C"
    _ -> panic as "bad combo operand"
  }
}

// After disassembly and analysis, I realized that for each output depended only on
// the last 3 bits of A and larger parts of A from previous outputs, so I could proceed
// from the last output to the first and build A up by trying 8 three bit combinations
// for each output to match the appropriate program instruction.

// Run until list starts with match, starting with 0
fn next_digit(current_a: Int, prog: Dict(Int, Int), match: Int, try: Int) -> Int {
  let trial_a =
    int.bitwise_shift_left(current_a, 3)
    |> int.bitwise_or(try)

  let c = new_computer(trial_a, 0, 0)

  case run_until_done(c, prog) {
    [first, ..] if first == match -> trial_a
    _ -> next_digit(current_a, prog, match, try + 1)
  }
}

fn find_a(prog: Dict(Int, Int), prev_a: Int, matches: List(Int)) -> Int {
  case matches {
    [first, ..rest] -> {
      let a = next_digit(prev_a, prog, first, 0)
      find_a(prog, a, rest)
    }
    [] -> prev_a
  }
}
