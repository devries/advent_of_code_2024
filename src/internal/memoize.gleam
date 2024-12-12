import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor

// Memoization in Gleam threw me for a loop, but an actor can hold
// the information I need. Below are the building blocks of an
// actor that holds a dict with a stone number and generations as
// a key, and the total count of stones will be descended from it
// after than many generations.

pub type Message(a, b) {
  Put(key: a, value: b)
  Get(reply_with: Subject(Result(b, Nil)), key: a)
  Shutdown
}

pub type Cache(a, b) =
  Subject(Message(a, b))

pub fn handle_message(message: Message(a, b), current: Dict(a, b)) {
  case message {
    Put(key, value) -> actor.continue(dict.insert(current, key, value))
    Get(client, key) -> {
      process.send(client, dict.get(current, key))
      actor.continue(current)
    }
    Shutdown -> actor.Stop(process.Normal)
  }
}

// To check a cache first for a result first, before the rest of the function
// runs add
//    use <- cache_check(cache, #(param1, param2, ...))
// It will look up those parameters in the cache and return a value if found.
// otherwise it continues with the function and records the response for those
// parameters.
pub fn cache_check(cache: Cache(a, b), key: a, callback: fn() -> b) -> b {
  let result = process.call(cache, Get(_, key), 100)

  case result {
    Ok(v) -> v
    Error(Nil) -> {
      let result = callback()
      process.send(cache, Put(key, result))
      result
    }
  }
}

pub fn cache_init() -> Cache(a, b) {
  let assert Ok(cache) = actor.start(dict.new(), handle_message)

  cache
}

pub fn cache_shutdown(cache: Cache(a, b)) {
  process.send(cache, Shutdown)
}

// To initialize a cache for the rest of a function, add
//     use cache <- with_cache()
// to the function. The rest of the function is a callback
// with an actor holding the cache.
pub fn with_cache(callback: fn(Cache(a, b)) -> c) -> c {
  let cache = cache_init()

  let result = callback(cache)

  cache_shutdown(cache)
  result
}
