#ifndef __FIXPOINT_H__
#define __FIXPOINT_H__

#include <stdlib.h>
#include <math.h>
#include <inttypes.h>

#define FIXEDPOINT_BITS 32 // number of bits that one fixed point value represents
#define FIXEDPOINT_INTEGER_BITS 16 // number of integer bits
#define FIXEDPOINT_FRACTION_BITS (FIXEDPOINT_BITS - FIXEDPOINT_INTEGER_BITS) // number of fraction bits

#define LN_PRECISION 20 // number of iterations for the ln function

typedef int32_t fixedpt;
typedef uint64_t fixedptd;


/**
 * multiplies two fixed point values
 * @param a value 1
 * @param b value 2
 * @return a * b
 */
fixedpt fixedpt_mul(fixedpt a, fixedpt b) {
    return ((fixedptd) a * (fixedptd) b) >> FIXEDPOINT_FRACTION_BITS;
}

/**
 * divides two fixed point values
 * @param a value 1
 * @param b value 2
 * @return a / b
 */
fixedpt fixedpt_div(fixedpt a, fixedpt b) {
    return ((fixedptd) a << FIXEDPOINT_FRACTION_BITS) / b;
}

/**
 * computes a to the power of b
 * @param a value 1
 * @param b value 2
 * @return a^b
 */
fixedpt fixedpt_pow(fixedpt a, int8_t b) {
    int8_t b2 = abs(b);
    fixedpt one = 1 << FIXEDPOINT_FRACTION_BITS;
    fixedpt res = one;
    #pragma hls_unroll yes
    for (uint8_t i = 0; i < b2; i++) {
        res = fixedpt_mul(res, a);
    }
    if (b < 0) {
        res = fixedpt_div(one, res);
    }
    return res;
}

/**
 * computes ln(a)
 * @param a value
 * @return ln(a)
 */
fixedpt fixedpt_ln(fixedpt a) {
    fixedpt result = 0;
    uint8_t v = 1;
    fixedpt fp_v = v << FIXEDPOINT_FRACTION_BITS;
    fixedpt factor = a - (1 << FIXEDPOINT_FRACTION_BITS);
    uint8_t positive = 1;
    while (v <= LN_PRECISION) {
        fixedpt fract = fixedpt_div(factor, fp_v);
        if (positive == 1) {
            result += fract;
        } else {
            positive -= fract;
        }
        positive = 1 - positive;
        v += 1;
        factor = fixedpt_mul(factor, a);
        fp_v = v << FIXEDPOINT_FRACTION_BITS;
    }
    return result;
}

#endif
