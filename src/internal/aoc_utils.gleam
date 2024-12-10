import birl
import birl/duration.{type Duration}
import gleam/int
import gleam/io
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

pub fn time_execution(
  timed_function: fn() -> a,
  callback: fn(Duration, a) -> Nil,
) {
  let start = birl.now()
  let result = timed_function()
  let duration = birl.difference(birl.now(), start)

  callback(duration, result)
}

pub fn duration_string(d: Duration) -> String {
  case d {
    duration.Duration(micros) if micros < 10_000 ->
      int.to_string(micros) <> " μs"
    duration.Duration(micros) if micros < 10_000_000 ->
      int.to_string(micros / 1000) <> " ms"
    duration.Duration(micros) -> int.to_string(micros / 1_000_000) <> " s"
  }
}

pub fn run_part_and_print(
  label: String,
  part: fn() -> Result(String, String),
) -> Nil {
  use duration, result <- time_execution(part)
  io.println(
    label
    <> " ("
    <> duration_string(duration)
    <> ")"
    <> ": "
    <> solution_or_error(result),
  )
}
