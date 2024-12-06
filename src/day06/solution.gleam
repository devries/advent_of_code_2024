import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import internal/aoc_utils
import internal/point.{type Point}

pub fn main() {
  let filename = "inputs/day06.txt"

  let lines_result = aoc_utils.read_lines(from: filename)
  case lines_result {
    Ok(lines) -> {
      // If the file was converting into a list of lines
      // successfully then run each part of the problem
      io.println("Part 1: " <> aoc_utils.solution_or_error(solve_p1(lines)))
      io.println("Part 2: " <> aoc_utils.solution_or_error(solve_p2(lines)))
    }
    Error(_) -> io.println("Error reading file")
  }
}

// Part 1
pub fn solve_p1(lines: List(String)) -> Result(String, String) {
  let grid = parse(lines)

  use guard <- result.map({
    find_guard(grid)
    |> result.replace_error("unable to find guard")
  })

  wander(guard, grid)
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  let grid = parse(lines)

  use guard <- result.map({
    find_guard(grid)
    |> result.replace_error("unable to find guard")
  })

  let obstructions = obstruct(guard, grid)
  set.drop(obstructions, [guard.position])
  // plot_grid_with_obstructions(grid, obstructions)

  set.size(obstructions)
  |> int.to_string
}

type Person {
  Person(position: Point, direction: Point)
}

type MotionError {
  Collision
  OffMap
}

fn parse(lines: List(String)) -> Dict(Point, String) {
  use grid, line, y <- list.index_fold(lines, dict.new())
  let characters = string.to_graphemes(line)

  use grid, c, x <- list.index_fold(characters, grid)
  let p = #(x, y)
  dict.insert(grid, p, c)
}

fn find_guard(grid: Dict(Point, String)) -> Result(Person, Nil) {
  grid
  |> dict.to_list
  |> list.fold_until(Error(Nil), fn(_, grid_tuple) {
    case grid_tuple {
      #(p, "^") -> list.Stop(Ok(Person(p, #(0, -1))))
      _ -> list.Continue(Error(Nil))
    }
  })
}

fn forward(p: Person, grid: Dict(Point, String)) -> Result(Person, MotionError) {
  let destination = point.add(p.position, p.direction)

  case dict.get(grid, destination) {
    Ok("#") -> Error(Collision)
    Error(Nil) -> Error(OffMap)
    _ -> Ok(Person(destination, p.direction))
  }
}

fn right(p: Person) -> Person {
  let new_direction = case p.direction {
    #(0, -1) -> #(1, 0)
    #(1, 0) -> #(0, 1)
    #(0, 1) -> #(-1, 0)
    #(-1, 0) -> #(0, -1)
    _ -> #(0, -1)
  }
  Person(p.position, new_direction)
}

// Return the number of steps in a wandering for part 1
fn wander(p: Person, grid: Dict(Point, String)) -> Int {
  let visited = set.from_list([p.position])
  wander_acc(p, grid, visited)
}

fn wander_acc(p: Person, grid: Dict(Point, String), acc: set.Set(Point)) -> Int {
  case forward(p, grid) {
    Error(OffMap) -> set.size(acc)
    Error(Collision) -> wander_acc(right(p), grid, acc)
    Ok(pnew) -> wander_acc(pnew, grid, set.insert(acc, pnew.position))
  }
}

fn obstruct(p: Person, grid: Dict(Point, String)) -> set.Set(Point) {
  obstruct_acc(p, grid, set.from_list([p.position]), set.new())
}

// In this case the accumulator will be a tuple of the set of position/direction states
// as well as a set of places to put obstructions
fn obstruct_acc(
  p: Person,
  grid: Dict(Point, String),
  visited: set.Set(Point),
  obstructions: set.Set(Point),
) -> set.Set(Point) {
  case forward(p, grid) {
    Error(OffMap) -> obstructions
    Error(Collision) -> obstruct_acc(right(p), grid, visited, obstructions)
    Ok(pnew) -> {
      // Since the new position is unobstructed, test if an obstruction would have caused
      // a cycle
      let new_obstructions = case test_for_cycle(p, pnew, grid, visited) {
        True -> set.insert(obstructions, pnew.position)
        False -> obstructions
      }
      obstruct_acc(
        pnew,
        grid,
        set.insert(visited, pnew.position),
        new_obstructions,
      )
    }
  }
}

// Check for a cycle when starting at position p, with next step as pnew
// in the grid grid having visited the set of visited points.
fn test_for_cycle(
  p: Person,
  pnew: Person,
  grid: Dict(Point, String),
  visited: set.Set(Point),
) -> Bool {
  // This is somewhat tortured logic, but if it is possible to take a step forward
  // and you haven't been in that location before, then explore it as a potential
  // obstruction location.
  case set.contains(visited, pnew.position) {
    // In this case the guard has walked there and an obstruction has already
    // been checked for that position
    True -> False

    // Since the guard has not been in that location, try putting an obstruction
    // in that location.
    False ->
      continue_test_for_cycle(
        p,
        dict.insert(grid, pnew.position, "#"),
        set.from_list([p]),
      )
  }
}

fn continue_test_for_cycle(
  p: Person,
  grid: Dict(Point, String),
  states: set.Set(Person),
) -> Bool {
  case forward(p, grid) {
    Error(OffMap) -> False
    Error(Collision) ->
      continue_test_for_cycle(right(p), grid, set.insert(states, right(p)))
    Ok(pnew) -> {
      case set.contains(states, pnew) {
        True -> True
        False -> continue_test_for_cycle(pnew, grid, set.insert(states, pnew))
      }
    }
  }
}

fn find_max(grid: Dict(Point, String)) -> #(Int, Int) {
  let #(points, _) = dict.to_list(grid) |> list.unzip

  list.fold(points, #(0, 0), fn(max, p) {
    #(int.max(max.0, p.0), int.max(max.1, p.1))
  })
}

pub fn plot_grid_with_obstructions(
  grid: Dict(Point, String),
  obstructions: set.Set(Point),
) -> Nil {
  let #(xmax, ymax) = find_max(grid)

  use y <- list.each(list.range(0, ymax))
  use x <- list.each(list.range(0, xmax))

  let p = #(x, y)
  case set.contains(obstructions, p) {
    True -> io.print("O")
    False -> io.print(dict.get(grid, p) |> result.unwrap(" "))
  }
  case x == xmax {
    True -> io.println("")
    False -> Nil
  }
}
