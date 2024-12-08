pub type Point =
  #(Int, Int)

/// p1+p2
pub fn add(p1: Point, p2: Point) -> Point {
  #(p1.0 + p2.0, p1.1 + p2.1)
}

/// m*p
pub fn mul(p: Point, m: Int) -> Point {
  #(m * p.0, m * p.1)
}

/// p1-p2
pub fn sub(p1: Point, p2: Point) {
  #(p1.0 - p2.0, p1.1 - p2.1)
}
