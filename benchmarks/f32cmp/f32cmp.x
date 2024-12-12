import float32

type F32 = float32::F32;
pub fn main(x: F32, y: F32) -> u1 {
  float32::lt_2(x, y)
}
