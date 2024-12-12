import float32
import xls.modules.fp32_mul_2

type F32 = float32::F32;
pub fn main(x: F32, y: F32) -> F32 {
  fp32_mul_2::fp32_mul_2(x, y)
}
