import gleam/list
import gleam/result
import gleam/string
import simplifile

/// Read Advent of Code input file and split into a list of lines.
pub fn read_lines(
  from filepath: String,
) -> Result(List(String), simplifile.FileError) {
  use content <- result.map(simplifile.read(from: filepath))

  content
  |> string.trim_end
  |> string.split("\n")
}

pub fn solution_or_error(v: Result(String, String)) -> String {
  case v {
    Ok(solution) -> solution
    Error(error) -> "ERROR: " <> error
  }
}

pub fn chunk_around_empty_strings(lines: List(String)) -> List(List(String)) {
  lines
  |> list.chunk(fn(x) { x == "" })
  |> list.filter(fn(x) {
    case x {
      [item, ..] if item == "" -> False
      _ -> True
    }
  })
}
