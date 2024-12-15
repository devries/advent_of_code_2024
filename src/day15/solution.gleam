import envoy
import gleam/dict.{type Dict}
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day15.txt"

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
  let assert Ok(#(robot, grid, moves)) = parse(lines)

  moves
  |> list.fold(#(robot, grid), fn(state, direction) {
    move_robot(state.0, direction, state.1)
  })
  |> pair.second
  |> dict.to_list
  |> list.map(fn(kvpair) {
    case kvpair.1 {
      "O" -> kvpair.0.0 + { kvpair.0.1 * 100 }
      _ -> 0
    }
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let assert Ok(#(robot, grid, moves)) = parse_doublewide(lines)

  moves
  |> list.fold(#(robot, grid), fn(state, direction) {
    let #(r, g) = move_robot(state.0, direction, state.1)
    case envoy.get("AOC_DEBUG") {
      Ok(_) -> {
        print_grid(g, r)
        let _ = erlang.get_line(":")
        Nil
      }
      _ -> Nil
    }
    #(r, g)
  })
  |> pair.second
  |> dict.to_list
  |> list.map(fn(kvpair) {
    case kvpair.1 {
      "[" -> kvpair.0.0 + { kvpair.0.1 * 100 }
      _ -> 0
    }
  })
  |> int.sum
  |> int.to_string
  |> Ok
}

fn parse(
  lines: List(String),
) -> Result(#(Point, Dict(Point, String), List(Point)), String) {
  case aoc_utils.chunk_around_empty_strings(lines) {
    [gridlines, movelines] -> {
      let grid = parse_grid(gridlines)
      let assert Ok(#(robot, grid)) = get_robot(grid)
      let assert Ok(moves) = parse_moves(movelines)

      Ok(#(robot, grid, moves))
    }
    _ -> Error("Unable to parse input")
  }
}

fn parse_doublewide(
  lines: List(String),
) -> Result(#(Point, Dict(Point, String), List(Point)), String) {
  case aoc_utils.chunk_around_empty_strings(lines) {
    [gridlines, movelines] -> {
      let grid = double_wide(gridlines) |> parse_grid
      let assert Ok(#(robot, grid)) = get_robot(grid)
      let assert Ok(moves) = parse_moves(movelines)

      Ok(#(robot, grid, moves))
    }
    _ -> Error("Unable to parse input")
  }
}

fn parse_grid(lines: List(String)) -> Dict(Point, String) {
  use grid, line, y <- list.index_fold(lines, dict.new())
  let characters = string.to_graphemes(line)

  use grid, c, x <- list.index_fold(characters, grid)

  let p = #(x, y)
  dict.insert(grid, p, c)
}

fn get_robot(
  grid: Dict(Point, String),
) -> Result(#(Point, Dict(Point, String)), Nil) {
  use robot <- result.map({
    grid
    |> dict.to_list
    |> list.find(fn(tup) { tup.1 == "@" })
  })

  #(robot.0, dict.insert(grid, robot.0, "."))
}

fn parse_moves(lines: List(String)) -> Result(List(Point), Nil) {
  lines
  |> string.concat
  |> string.to_graphemes
  |> list.map(fn(d) {
    case d {
      "^" -> Ok(#(0, -1))
      ">" -> Ok(#(1, 0))
      "v" -> Ok(#(0, 1))
      "<" -> Ok(#(-1, 0))
      _ -> Error(Nil)
    }
  })
  |> result.all
}

// Push stuff over in direction starting at point to with previous
// value as the item type. Return rearranged grid or Error if can't
// push.

type Move {
  Move(object: String, destination: Point)
}

fn push_direction(
  direction: Point,
  to: List(Move),
  grid: Dict(Point, String),
) -> Result(Dict(Point, String), Nil) {
  // If a # is there return Error
  // if all . then just move,
  // if [] or O and . then iterate (remove . points)

  use next <- result.try(
    list.try_fold(to, [], fn(next_movers, mover) {
      case dict.get(grid, mover.destination) {
        // If there is a wall ahead, return error -> no move
        Ok("#") -> Error(Nil)

        // If there is a space ahead, you don't need to worry about this column anymore
        Ok(".") -> Ok(next_movers)

        // If there is anything else, you need to move that to the next space.
        Ok(v) ->
          Ok([Move(v, point.add(mover.destination, direction)), ..next_movers])
        Error(Nil) -> panic as "I am pushing off grid"
      }
    }),
  )

  // Put all the objects you just moved into the grid.
  let grid =
    list.fold(to, grid, fn(grid, mover) {
      dict.insert(grid, mover.destination, mover.object)
    })

  // If we moved half a box, we need to make sure we also move the other half.
  // If the other half isn't there also be sure to leave space where it came
  // from.
  let #(grid, next) =
    list.fold(next, #(grid, []), fn(tup, mover) {
      let #(newgrid, bulked_next) = tup
      case mover.object {
        "[" -> {
          let matching = Move("]", point.add(mover.destination, #(1, 0)))
          case list.contains(next, matching) {
            True -> #(newgrid, [mover, ..bulked_next])
            False -> {
              #(
                dict.insert(
                  newgrid,
                  point.sub(matching.destination, direction),
                  ".",
                ),
                [matching, mover, ..bulked_next],
              )
            }
          }
        }
        "]" -> {
          let matching = Move("[", point.add(mover.destination, #(-1, 0)))
          case list.contains(next, matching) {
            True -> #(newgrid, [mover, ..bulked_next])
            False -> #(
              dict.insert(
                newgrid,
                point.sub(matching.destination, direction),
                ".",
              ),
              [mover, matching, ..bulked_next],
            )
          }
        }
        _ -> #(newgrid, [mover, ..bulked_next])
      }
    })

  // If there are any more items to move, iterate.
  case next {
    [] -> Ok(grid)
    _ -> push_direction(direction, next, grid)
  }
}

fn move_robot(
  robot: Point,
  direction: Point,
  grid: Dict(Point, String),
) -> #(Point, Dict(Point, String)) {
  let new_robot = point.add(robot, direction)

  case push_direction(direction, [Move(".", new_robot)], grid) {
    Ok(g) -> #(new_robot, g)
    _ -> #(robot, grid)
  }
}

fn double_wide(lines: List(String)) -> List(String) {
  lines
  |> list.map(fn(line) {
    line
    |> string.to_graphemes
    |> list.map(fn(c) {
      case c {
        "#" -> "##"
        "O" -> "[]"
        "." -> ".."
        "@" -> "@."
        c -> c <> c
      }
    })
    |> string.concat
  })
}

fn print_grid(grid: Dict(Point, String), robot: Point) -> Nil {
  let #(xmax, ymax) = find_max(grid)

  list.each(list.range(0, ymax), fn(y) {
    list.each(list.range(0, xmax), fn(x) {
      case robot == #(x, y) {
        True -> io.print("@")
        False -> {
          let assert Ok(c) = dict.get(grid, #(x, y))
          io.print(c)
        }
      }
    })
    io.println("")
  })
  io.println("")
}

fn find_max(grid: Dict(Point, String)) -> #(Int, Int) {
  let #(points, _) = dict.to_list(grid) |> list.unzip

  list.fold(points, #(0, 0), fn(max, p) {
    #(int.max(max.0, p.0), int.max(max.1, p.1))
  })
}
