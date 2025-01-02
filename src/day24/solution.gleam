import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day24.txt"

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
  use #(wires, gates) <- result.map(parse(lines))

  find_wire_values(wires, gates)
  |> get_number("z")
  |> int.to_string
}

//
// Half adder
// x0 XOR y0 -> z0
// x0 AND y0 -> c0
//
// Full adder
// xn XOR yn -> an
// xn AND yn -> bn
// an XOR cn-1 -> zn
// an AND cn-1 -> dn
// bn OR dn -> cn
//

// Part 2
// Easiest way to do this was to do some sorting and use editor macros to pull
// together the relevant half adder and full adders into groups.
// I then went looking at results and tried to implement a solution based on
// this explanation: https://old.reddit.com/r/adventofcode/comments/1hla5ql/2024_day_24_part_2_a_guide_on_the_idea_behind_the/
// and from a really great pattern matching example in the Gleam discord by
// super makioka sisters. This is essentially a copy of their example which
// I implemented in order to better understand it.
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use #(_, gates) <- result.map(parse(lines))

  gates
  |> list.filter(fn(g) {
    // filter the gates for gates that do not match a half adder followed by
    // a bunch of full adders.
    case g {
      // Outputs should be from Xor gates, except the last one
      Or(_, _, "z45") -> False
      Xor(_, _, "z" <> _) -> False
      Or(_, _, "z" <> _) | And(_, _, "z" <> _) -> True

      // Xor gates for inputs should connect to AND and XOR gates, but not OR gates
      Xor("x" <> _, "y" <> _, output) | Xor("y" <> _, "x" <> _, output) -> {
        find_gates_with_input(gates, output)
        |> has_or_gates
      }

      // Any other Xor gate is not valid
      Xor(_, _, _) -> True

      // And gates should have Or gates after them, except for the
      // output of the half-adder.
      // This assumes the output of the And from the first half adder
      // is not swapped.
      And("x00", _, _) | And(_, "x00", _) -> False
      And(_, _, output) -> {
        find_gates_with_input(gates, output)
        |> has_or_gates
        |> bool.negate
      }
      _ -> False
    }
  })
  |> list.map(fn(g) { g.output })
  |> list.sort(string.compare)
  |> string.join(",")
}

type Gate {
  And(input1: String, input2: String, output: String)
  Or(input1: String, input2: String, output: String)
  Xor(input1: String, input2: String, output: String)
}

fn parse(
  lines: List(String),
) -> Result(#(Dict(String, Int), List(Gate)), String) {
  let assert [values, gates] = aoc_utils.chunk_around_empty_strings(lines)

  use wire_dict <- result.try(parse_values(values))

  use gate_list <- result.map(parse_gates(gates))

  #(wire_dict, gate_list)
}

fn parse_values(values: List(String)) -> Result(Dict(String, Int), String) {
  use value_list <- result.map({
    values
    |> list.map(fn(line) {
      case string.split(line, ": ") {
        [wire, boolstring] ->
          case int.parse(boolstring) {
            Ok(n) -> Ok(#(wire, n))
            Error(Nil) -> Error("Unable to parse wire value")
          }
        _ -> Error("Unexpected wire value line")
      }
    })
    |> result.all
  })

  dict.from_list(value_list)
}

fn parse_gates(gates: List(String)) -> Result(List(Gate), String) {
  gates
  |> list.map(fn(line) {
    case string.split(line, " ") {
      [i1, name, i2, _, o] -> {
        case name {
          "AND" -> Ok(And(i1, i2, o))
          "OR" -> Ok(Or(i1, i2, o))
          "XOR" -> Ok(Xor(i1, i2, o))
          _ -> Error("Gate type not recognized")
        }
      }
      _ -> Error("Unexpected gate format")
    }
  })
  |> result.all
}

fn find_wire_values(
  wires: Dict(String, Int),
  gates: List(Gate),
) -> Dict(String, Int) {
  case gates {
    [] -> wires
    _ -> {
      let newdict =
        gates
        |> list.fold(wires, fn(d, gate) {
          case resolve_gate(gate, wires) {
            Ok(#(output, value)) -> {
              dict.insert(d, output, value)
            }
            _ -> d
          }
        })

      find_wire_values(
        newdict,
        gates |> list.filter(fn(g) { !dict.has_key(newdict, g.output) }),
      )
    }
  }
}

fn resolve_gate(
  gate: Gate,
  wires: Dict(String, Int),
) -> Result(#(String, Int), Nil) {
  use v1 <- result.try(dict.get(wires, gate.input1))
  use v2 <- result.map(dict.get(wires, gate.input2))

  case gate {
    And(_, _, o) -> #(o, int.bitwise_and(v1, v2))
    Or(_, _, o) -> #(o, int.bitwise_or(v1, v2))
    Xor(_, _, o) -> #(o, int.bitwise_exclusive_or(v1, v2))
  }
}

fn get_number(wires: Dict(String, Int), prefix: String) -> Int {
  dict.to_list(wires)
  |> list.filter(fn(tup) { string.starts_with(tup.0, prefix) })
  |> list.sort(fn(tupa, tupb) { string.compare(tupb.0, tupa.0) })
  |> list.fold(0, fn(value, tup) { { value * 2 } + tup.1 })
}

fn find_gates_with_input(gates: List(Gate), input: String) -> List(Gate) {
  gates
  |> list.filter(fn(g) {
    case g.input1, g.input2 {
      w, _ if w == input -> True
      _, w if w == input -> True
      _, _ -> False
    }
  })
}

fn has_or_gates(gates: List(Gate)) -> Bool {
  case gates {
    [Or(_, _, _), ..] -> True
    [_, ..rest] -> has_or_gates(rest)
    [] -> False
  }
}
