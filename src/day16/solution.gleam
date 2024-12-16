// import gleam/deque
import envoy
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import internal/aoc_utils
import internal/dijkstra
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day16.txt"

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
  let maze = parse(lines)

  let start = State(maze.start, #(1, 0))

  let pqueue = dijkstra.push(dijkstra.new(), 0, start, None)
  use #(score, _) <- result.map({
    find_endpoint(maze, pqueue)
    |> result.replace_error("Error in search")
  })
  int.to_string(score)
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let maze = parse(lines)

  let start = State(maze.start, #(1, 0))

  let pqueue = dijkstra.push(dijkstra.new(), 0, start, None)
  use #(score, _) <- result.map({
    find_endpoint(maze, pqueue)
    |> result.replace_error("Error in search")
  })

  // find all routes
  let routings = find_all_optimal_path_tiles(maze, pqueue, score, dict.new())

  let end_states =
    dict.keys(routings)
    |> list.filter(fn(s) { s.position == maze.end })

  let found_tiles =
    get_states(end_states, routings, set.new())
    |> set.fold(set.new(), fn(tiles, state) {
      set.insert(tiles, state.position)
    })

  case envoy.get("AOC_DEBUG") {
    Ok(_) -> print_best_pathways(maze, found_tiles)
    _ -> Nil
  }

  found_tiles
  |> set.size
  |> int.to_string
}

type Maze {
  Maze(map: Dict(Point, String), start: Point, end: Point)
}

fn parse(lines: List(String)) -> Maze {
  use grid, line, y <- list.index_fold(
    lines,
    Maze(dict.new(), #(0, 0), #(0, 0)),
  )
  let characters = string.to_graphemes(line)

  use grid, c, x <- list.index_fold(characters, grid)

  let p = #(x, y)
  case c {
    "." -> grid
    "S" -> Maze(..grid, start: p)
    "E" -> Maze(..grid, end: p)
    _ -> Maze(..grid, map: dict.insert(grid.map, p, c))
  }
}

type State {
  State(position: Point, direction: Point)
}

fn find_endpoint(
  grid: Maze,
  pqueue: dijkstra.Queue(State),
) -> Result(#(Int, State), Nil) {
  use #(newpqueue, score, state) <- result.try(dijkstra.pop(pqueue))

  case state.position == grid.end {
    True -> Ok(#(score, state))

    False -> {
      let forward_state =
        State(point.add(state.position, state.direction), state.direction)
      let left_state =
        State(state.position, point.rotate_right(state.direction))
      let right_state =
        State(state.position, point.rotate_left(state.direction))

      let turn_states = [
        #(score + 1000, left_state),
        #(score + 1000, right_state),
      ]
      let next_states = case dict.get(grid.map, forward_state.position) {
        Ok("#") -> turn_states
        _ -> [#(score + 1, forward_state), ..turn_states]
      }

      let newpqueue = dijkstra.push_list(newpqueue, next_states, Some(state))
      find_endpoint(grid, newpqueue)
    }
  }
}

fn find_all_optimal_path_tiles(
  grid: Maze,
  pqueue: dijkstra.Queue(State),
  max_score: Int,
  state_track: Dict(State, #(Int, List(State))),
) -> Dict(State, #(Int, List(State))) {
  let current = dijkstra.pop(pqueue)

  // This is a little messy, but what I am doing is searching all paths with
  // scores less than or equal to the maximum score and saving for each
  // optimal state along the maze the previous states that could get there.
  // Then I just crawl through from the end state to all the previous states
  // and find all the tiles in those states.

  case current {
    Error(Nil) -> state_track
    Ok(d) -> {
      let #(newpqueue, score, state) = d

      case state.position == grid.end {
        True ->
          find_all_optimal_path_tiles(grid, newpqueue, max_score, state_track)

        False -> {
          let forward_state =
            State(point.add(state.position, state.direction), state.direction)
          let left_state =
            State(state.position, point.rotate_right(state.direction))
          let right_state =
            State(state.position, point.rotate_left(state.direction))

          let turn_states = [
            #(score + 1000, left_state),
            #(score + 1000, right_state),
          ]
          let next_states =
            case dict.get(grid.map, forward_state.position) {
              Ok("#") -> turn_states
              _ -> [#(score + 1, forward_state), ..turn_states]
            }
            |> list.filter(fn(s) { s.0 <= max_score })

          let new_tracker =
            list.fold(next_states, state_track, fn(track, s) {
              update_state_tracker(track, state, s.1, s.0)
            })

          let newpqueue =
            dijkstra.push_list(newpqueue, next_states, Some(state))
          find_all_optimal_path_tiles(grid, newpqueue, max_score, new_tracker)
        }
      }
    }
  }
}

// The state tracker keeps track of the lowest cost way to get to a state
// as well as the previous states which lead to that state. This allows us
// to follow the states back and find the multiple ways to find the optimal
// solution.
fn update_state_tracker(
  tracker: Dict(State, #(Int, List(State))),
  prevstate: State,
  newstate: State,
  score: Int,
) -> Dict(State, #(Int, List(State))) {
  let current_best = dict.get(tracker, newstate)

  case current_best {
    Ok(#(n, _)) if n < score -> tracker
    Ok(#(n, prev)) if n == score ->
      dict.insert(tracker, newstate, #(n, [prevstate, ..prev]))
    _ -> dict.insert(tracker, newstate, #(score, [prevstate]))
  }
}

fn get_states(
  to: List(State),
  tracker: Dict(State, #(Int, List(State))),
  found: set.Set(State),
) -> set.Set(State) {
  case to {
    [] -> found
    [first, ..rest] -> {
      case set.contains(found, first) {
        False -> {
          let newfound = set.insert(found, first)
          case dict.get(tracker, first) {
            Ok(#(_, previous)) -> {
              get_states(list.flatten([rest, previous]), tracker, newfound)
            }
            // The initial point had no previous state, this is probably that.
            _ -> get_states(rest, tracker, newfound)
          }
        }
        True -> get_states(rest, tracker, found)
      }
    }
  }
}

fn print_best_pathways(grid: Maze, tiles: set.Set(Point)) {
  let #(xmax, ymax) = find_max(grid.map)

  list.each(list.range(0, ymax), fn(y) {
    list.each(list.range(0, xmax), fn(x) {
      let p = #(x, y)
      case set.contains(tiles, p), dict.get(grid.map, p) {
        True, _ -> io.print("O")
        _, Ok(v) -> io.print(v)
        _, _ -> io.print(" ")
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
