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
      aoc_utils.run_part_and_print("Part 2", fn() { solve_p2(lines, 45) })
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
pub fn solve_p2(lines: List(String), bits: Int) -> Result(String, String) {
  use #(wires, gates) <- result.map(parse(lines))

  let avals = find_a(gates)
  let bvals = find_b(gates)
  list.range(0, bits)
  |> list.map(fn(i) {
    let a = dict.get(avals, i)
    let b = dict.get(bvals, i)
    io.debug(#(i, a, b))
    trace_gate(gates, i, "")
  })
  todo
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

fn find_a(gates: List(Gate)) -> Dict(Int, String) {
  list.fold(gates, dict.new(), fn(d, gate) {
    case gate {
      Xor(a, _, c) -> {
        case string.starts_with(a, "x") || string.starts_with(a, "y") {
          True -> {
            let val = string.drop_start(a, 1) |> int.parse |> result.unwrap(0)
            dict.insert(d, val, c)
          }
          False -> d
        }
      }
      _ -> d
    }
  })
}

fn find_b(gates: List(Gate)) -> Dict(Int, String) {
  list.fold(gates, dict.new(), fn(d, gate) {
    case gate {
      And(a, _, c) -> {
        case string.starts_with(a, "x") || string.starts_with(a, "y") {
          True -> {
            let val = string.drop_start(a, 1) |> int.parse |> result.unwrap(0)
            dict.insert(d, val, c)
          }
          False -> d
        }
      }
      _ -> d
    }
  })
}

fn get_number(wires: Dict(String, Int), prefix: String) -> Int {
  dict.to_list(wires)
  |> list.filter(fn(tup) { string.starts_with(tup.0, prefix) })
  |> list.sort(fn(tupa, tupb) { string.compare(tupb.0, tupa.0) })
  |> list.fold(0, fn(value, tup) { { value * 2 } + tup.1 })
}

// Create an initial condition for testing a bit on x and
// y with the other bits off.
fn setup_test(
  bit: Int,
  max_bit: Int,
  x: Int,
  y: Int,
  carry: Int,
) -> Dict(String, Int) {
  list.range(0, max_bit)
  |> list.map(fn(i) {
    let xkey = "x" <> string.pad_start(int.to_string(i), 2, "0")
    let ykey = "y" <> string.pad_start(int.to_string(i), 2, "0")

    case i {
      v if v == bit - 1 -> {
        case carry {
          1 -> [#(xkey, 1), #(ykey, 1)]
          _ -> [#(xkey, 0), #(ykey, 0)]
        }
      }

      v if v == bit -> {
        [#(xkey, x), #(ykey, y)]
      }

      _ -> [#(xkey, 0), #(ykey, 0)]
    }
  })
  |> list.flatten
  |> dict.from_list
}

fn get_test_result(wires: Dict(String, Int), bit: Int) -> #(Int, Int) {
  let zkey = "z" <> string.pad_start(int.to_string(bit), 2, "0")
  let ckey = "z" <> string.pad_start(int.to_string(bit + 1), 2, "0")

  #(
    dict.get(wires, zkey) |> result.unwrap(0),
    dict.get(wires, ckey) |> result.unwrap(0),
  )
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
fn trace_gate(gates: List(Gate), i: Int, c: String) {
  let x = "x" <> string.pad_start(int.to_string(i), 2, "0")
  let y = "y" <> string.pad_start(int.to_string(i), 2, "0")
  let z = "z" <> string.pad_start(int.to_string(i), 2, "0")

  case i {
    0 -> {
      find_gates(gates, x, y)
    }
    _ -> {
      find_gates(gates, x, y)
      |> io.debug
    }
  }
}

fn find_gates(gates: List(Gate), i1: String, i2: String) -> List(Gate) {
  gates
  |> list.filter(fn(g) {
    { g.input1 == i1 && g.input2 == i2 } || { g.input1 == i2 && g.input2 == i1 }
  })
}
