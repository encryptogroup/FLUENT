import xls.modules.fp32_add_2
import float32

type F32 = float32::F32;
pub fn main(x: F32, y: F32) -> F32 {
  fp32_add_2::fp32_add_2(x, y)
}
