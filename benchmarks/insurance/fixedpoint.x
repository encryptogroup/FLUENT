import std

const FIXEDPOINT_BITS = u32:32;
const FIXEDPOINT_INTEGER_BITS = u32:16;
const FIXEDPOINT_FRACTION_BITS = FIXEDPOINT_BITS - FIXEDPOINT_INTEGER_BITS;

const FIXEDPOINT_ONE = u32:1 << FIXEDPOINT_FRACTION_BITS;

fn fixedpt_mul(a: u32, b:u32) -> u32 {
  (((a as u64) * (b as u64)) >> FIXEDPOINT_FRACTION_BITS) as u32
}

fn fixedpt_div(a: u32, b:u32) -> u32 {
  (((a as u64) << FIXEDPOINT_FRACTION_BITS) / (b as u64)) as u32
}

fn fixedpt_pow(a: u32, b: s8) -> u32 {
  let b2 = std::abs(b);
  let result = FIXEDPOINT_ONE;
  let p = a;

  let work = for (i, (n, p, result)) in range(u32:0, u32:8) {
    let result = if (n & s8:1) == s8:1 { fixedpt_mul(result, p) } else { result };

    (n >> 1, fixedpt_mul(p, p), result)
  }((b2, p, result));
  let result = work[2];
  if (b < s8:0) { fixedpt_div(FIXEDPOINT_ONE, result) } else { result }
}
