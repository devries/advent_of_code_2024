import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import internal/aoc_utils
import internal/dijkstra
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day20.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      aoc_utils.run_part_and_print("Part 1", fn() { solve_p1(lines, 100) })
      aoc_utils.run_part_and_print("Part 2", fn() { solve_p2(lines, 100) })
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(
  lines: List(String),
  saving_floor: Int,
) -> Result(String, String) {
  let track = parse(lines)

  let pqueue = dijkstra.push(dijkstra.new(), 0, track.start, None)
  use route <- result.map({
    find_path(track, pqueue)
    |> result.replace_error("Unable to find route")
  })

  let route_times =
    list.index_map(route, fn(p, idx) { #(p, idx) }) |> dict.from_list

  find_shortcuts(route, route_times, 2, [])
  |> list.filter(fn(s) { s.savings >= saving_floor })
  |> list.length
  |> int.to_string
}

// Part 2
pub fn solve_p2(
  lines: List(String),
  saving_floor: Int,
) -> Result(String, String) {
  let track = parse(lines)

  let pqueue = dijkstra.push(dijkstra.new(), 0, track.start, None)
  use route <- result.map({
    find_path(track, pqueue)
    |> result.replace_error("Unable to find route")
  })

  let route_times =
    list.index_map(route, fn(p, idx) { #(p, idx) }) |> dict.from_list

  count_shortcuts(route, route_times, 20, saving_floor, 0)
  |> int.to_string
}

type Track {
  Track(start: Point, end: Point, walls: Set(Point))
}

fn parse(lines: List(String)) -> Track {
  use track, line, y <- list.index_fold(
    lines,
    Track(#(0, 0), #(0, 0), set.new()),
  )
  let characters = string.to_graphemes(line)

  use track, c, x <- list.index_fold(characters, track)

  case c {
    "S" -> Track(..track, start: #(x, y))
    "E" -> Track(..track, end: #(x, y))
    "#" -> Track(..track, walls: set.insert(track.walls, #(x, y)))
    _ -> track
  }
}

fn find_path(
  track: Track,
  pqueue: dijkstra.Queue(Point),
) -> Result(List(Point), Nil) {
  use #(newpqueue, score, pos) <- result.try(dijkstra.pop(pqueue))

  case pos == track.end {
    True -> {
      dijkstra.get_path(newpqueue, pos)
    }

    False -> {
      let next_points =
        list.map(point.directions, point.add(_, pos))
        |> list.filter(fn(p) { !set.contains(track.walls, p) })
        |> list.map(fn(p) { #(score + 1, p) })

      let newpqueue = dijkstra.push_list(newpqueue, next_points, Some(pos))
      find_path(track, newpqueue)
    }
  }
}

// Get offsets N steps away dropping the points directly adjacent
fn get_offsets(steps: Int, offset: Point) -> Set(Point) {
  get_offsets_acc(steps, offset, set.new())
  |> set.delete(offset)
  |> set.drop(list.map(point.directions, point.add(offset, _)))
}

fn get_offsets_acc(
  steps: Int,
  offset: Point,
  positions: Set(Point),
) -> Set(Point) {
  case steps {
    0 -> positions
    _ -> {
      use new_positions, dir <- list.fold(point.directions, positions)

      let npos = point.add(offset, dir)
      case set.contains(new_positions, npos) {
        True -> new_positions
        False ->
          get_offsets_acc(steps - 1, npos, set.insert(new_positions, npos))
      }
    }
  }
}

type Shortcut {
  Shortcut(start: Point, end: Point, savings: Int)
}

fn find_shortcuts(
  route: List(Point),
  route_times: Dict(Point, Int),
  cheat_length: Int,
  shortcuts: List(Shortcut),
) -> List(Shortcut) {
  case route {
    [first, ..rest] -> {
      let assert Ok(stime) = dict.get(route_times, first)

      get_offsets(cheat_length, first)
      |> set.to_list
      |> list.fold(shortcuts, fn(sc, pos) {
        case dict.get(route_times, pos) {
          Ok(etime) -> {
            case etime - stime {
              save if save > 2 -> [
                Shortcut(first, pos, save - cheat_length),
                ..sc
              ]
              _ -> sc
            }
          }
          _ -> sc
        }
      })
      |> find_shortcuts(rest, route_times, cheat_length, _)
    }
    [] -> shortcuts
  }
}

fn count_shortcuts(
  route: List(Point),
  route_times: Dict(Point, Int),
  cheat_length: Int,
  min_save: Int,
  shortcuts: Int,
) -> Int {
  case route {
    [first, ..rest] -> {
      let count =
        get_shortcuts_within_range(rest, first, route_times, cheat_length, [])
        |> list.filter(fn(sc) { sc.savings >= min_save })
        |> list.length
      count_shortcuts(
        rest,
        route_times,
        cheat_length,
        min_save,
        shortcuts + count,
      )
    }
    [] -> shortcuts
  }
}

fn get_shortcuts_within_range(
  remaining: List(Point),
  from: Point,
  route_times: Dict(Point, Int),
  cheat_length: Int,
  shortcuts: List(Shortcut),
) -> List(Shortcut) {
  let assert Ok(stime) = dict.get(route_times, from)

  case remaining {
    [first, ..rest] -> {
      case point.distance(from, first) {
        d if d <= cheat_length -> {
          let assert Ok(etime) = dict.get(route_times, first)
          get_shortcuts_within_range(rest, from, route_times, cheat_length, [
            Shortcut(from, first, etime - stime - d),
            ..shortcuts
          ])
        }
        _ ->
          get_shortcuts_within_range(
            rest,
            from,
            route_times,
            cheat_length,
            shortcuts,
          )
      }
    }
    [] -> shortcuts
  }
}
