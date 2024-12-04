pub type Point {
  Point(x: Int, y: Int)
}

pub fn new(x: Int, y: Int) -> Point {
  Point(x, y)
}

pub fn add(p1: Point, p2: Point) -> Point {
  Point(p1.x + p2.x, p1.y + p2.y)
}

pub fn mul(p: Point, m: Int) -> Point {
  Point(m * p.x, m * p.y)
}
