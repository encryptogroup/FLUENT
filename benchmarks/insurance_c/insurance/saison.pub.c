
#include <stdint.h>
#include <math.h>
#include "../helper/fixpoint.h"

/**
 * Computes the discount per month depending on the saison
 * @param INPUT_A_month number of months of the saison
 * @param INPUT_A_price current price
 * @return discount per month for duration of saison
 */
fixedpt mpc_main(uint8_t INPUT_A_month, fixedpt INPUT_A_price) {

    fixedpt a = (12 - INPUT_A_month) << FIXEDPOINT_FRACTION_BITS;
    fixedpt b = 12 << FIXEDPOINT_FRACTION_BITS;

    // months / 12
    fixedpt c = fixedpt_div(a, b);

    // d = 1.2
    fixedpt d = 78643;

    // e = 0.8
    fixedpt e = 52428;

    // temp = 0.25
    fixedpt temp = 16384;

    // temp = 0.25 * month / 12
    temp = fixedpt_mul(c, temp);

    // pow = 1.2^(-12 + (12 - months))
    fixedpt pow = fixedpt_pow(d, -12 + (12 - INPUT_A_month));

    // factor = (0.8 * (0.25 * months / 12 + 1.2^(-12 + (12 - months)) - 2.3))
    fixedpt factor = fixedpt_mul(temp + pow - 150732, e) + 49152;

    // factor * price + 0.25
    return -fixedpt_mul(factor, INPUT_A_price);
}

