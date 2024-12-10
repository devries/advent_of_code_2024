import gleam/deque
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import internal/aoc_utils

pub fn main() {
  let filename = "inputs/day09.txt"

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
  use drive <- result.map(parse(lines))

  drive
  |> deque.from_list
  |> compress
  |> checksum
  |> int.to_string
}

// Part 2
pub fn solve_p2(lines: List(String)) -> Result(String, String) {
  use drive <- result.map(parse(lines))

  drive
  |> deque.from_list
  |> defrag([])
  |> deque.to_list
  |> checksum
  |> int.to_string
}

// A group has a file with id of number and length of length
// followed by spaces spaces.
type Group {
  Group(number: Int, length: Int, spaces: Int)
}

fn parse(lines: List(String)) -> Result(List(Group), String) {
  use line <- result.try({
    list.first(lines)
    |> result.replace_error("Empty Input")
  })
  use digits <- result.try({
    string.to_graphemes(line)
    |> list.map(int.parse)
    |> result.all
    |> result.replace_error("Unable to parse input")
  })

  digits
  |> list.sized_chunk(2)
  |> list.index_map(fn(vals, idx) {
    case vals {
      [length] -> Ok(Group(idx, length, 0))
      [length, spaces] -> Ok(Group(idx, length, spaces))
      _ -> Error("Unexpected chunk")
    }
  })
  |> result.all
}

fn compress(drive: deque.Deque(Group)) -> List(Group) {
  continue_compress(drive, [])
  |> list.reverse
}

fn continue_compress(drive: deque.Deque(Group), acc: List(Group)) -> List(Group) {
  case deque.pop_front(drive) {
    Error(_) -> acc
    Ok(#(head, new_drive)) -> {
      case head.spaces {
        0 -> continue_compress(new_drive, [head, ..acc])
        spaces -> {
          case deque.pop_back(new_drive) {
            Error(_) -> [head, ..acc]
            Ok(#(tail, popped_drive)) -> {
              case tail.length {
                l if l == spaces ->
                  continue_compress(popped_drive, [
                    Group(..tail, spaces: 0),
                    Group(..head, spaces: 0),
                    ..acc
                  ])
                l if l > spaces ->
                  continue_compress(
                    deque.push_back(
                      popped_drive,
                      Group(..tail, length: l - spaces),
                    ),
                    [
                      Group(..tail, length: spaces, spaces: 0),
                      Group(..head, spaces: 0),
                      ..acc
                    ],
                  )
                l ->
                  continue_compress(
                    deque.push_front(
                      popped_drive,
                      Group(..tail, spaces: spaces - l),
                    ),
                    [Group(..head, spaces: 0), ..acc],
                  )
              }
            }
          }
        }
      }
    }
  }
}

fn checksum(values: List(Group)) -> Int {
  checksum_accumulation(values, 0, 0)
}

fn checksum_accumulation(values: List(Group), index: Int, sum: Int) -> Int {
  case values {
    [] -> sum
    [first, ..rest] -> {
      let check =
        list.range(index, index + first.length - 1)
        |> list.map(fn(idx) { idx * first.number })
        |> int.sum

      let new_index = index + first.length + first.spaces
      checksum_accumulation(rest, new_index, check + sum)
    }
  }
}

/// Work from the back of the drive and insert the last file into the first empty space on the drive
/// large enough to hold it. If there is no such space, add that element to the tail stack and move
/// on to the next file at the back of the deque.
fn defrag(
  drive: deque.Deque(Group),
  tail_stack: List(Group),
) -> deque.Deque(Group) {
  case deque.pop_back(drive) {
    Error(_) -> deque.from_list(tail_stack)
    Ok(#(tail, rest_drive)) -> {
      case insert_group(rest_drive, tail, []) {
        Error(_) -> defrag(rest_drive, [tail, ..tail_stack])
        Ok(new_drive) -> defrag(new_drive, tail_stack)
      }
    }
  }
}

/// This function inserts group in the drive deque in the first region where there is
/// enough space after an existing file. The stack is an accumulator for all the areas
/// popped from the deque which will need to be restored to the deque after a suitable
/// space is found.
fn insert_group(
  drive: deque.Deque(Group),
  group: Group,
  stack: List(Group),
) -> Result(deque.Deque(Group), Nil) {
  case deque.pop_front(drive) {
    Error(_) -> Error(Nil)
    Ok(#(head, rest_drive)) -> {
      case head.spaces {
        l if l >= group.length -> {
          // We found a place to put the group, but we need to add the empty space to the
          // last element. This maintains the length of the file/space groupings on the drive.

          case deque.pop_back(rest_drive) {
            Error(_) -> {
              // There are no other elements in the drive aside from the
              // head and the group we are trying to find space for.
              // Just add the extra space to the group itself.

              deque.push_front(
                rest_drive,
                Group(..group, spaces: head.spaces + group.spaces),
              )
            }

            Ok(#(tail, temp_drive)) -> {
              // Add the size of the entire group to the spaces of the
              // drive's last element.

              deque.push_back(
                temp_drive,
                Group(..tail, spaces: tail.spaces + group.length + group.spaces),
              )
              |> deque.push_front(
                Group(..group, spaces: head.spaces - group.length),
              )
            }
          }
          |> deque.push_front(Group(..head, spaces: 0))
          |> restore_stack(stack)
          |> Ok
        }
        _ -> insert_group(rest_drive, group, [head, ..stack])
      }
    }
  }
}

fn restore_stack(
  drive: deque.Deque(Group),
  stack: List(Group),
) -> deque.Deque(Group) {
  case stack {
    [] -> drive
    [first, ..rest] -> restore_stack(deque.push_front(drive, first), rest)
  }
}
