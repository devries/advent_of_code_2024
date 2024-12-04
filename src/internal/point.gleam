pub type Point =
  #(Int, Int)

pub fn add(p1: Point, p2: Point) -> Point {
  #(p1.0 + p2.0, p1.1 + p2.1)
}

pub fn mul(p: Point, m: Int) -> Point {
  #(m * p.0, m * p.1)
}
