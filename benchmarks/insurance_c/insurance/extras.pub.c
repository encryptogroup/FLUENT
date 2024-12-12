#include <stdint.h>
#include <math.h>
#include "../helper/fixpoint.h"

/**
 * Compute price based on taking a marderschadenabdeckung and additional workshop
 * @param INPUT_A_price previously calculated price
 * @param INPUT_A_workshop 1 if the insurance taker wants workshop choice by insurance company, 0 otherwise
 * @param INPUT_A_mader 1 if the insurance taker wants marder coverage, 0 otherwise
 * @param INPUT_A_categorizedcar categorization of the car insured (0: cheap, 3: expensive)
 * @return the price after coverage of wished package
 */
fixedpt mpc_main(fixedpt INPUT_A_price,
                 uint8_t INPUT_A_workshop,
                 uint8_t INPUT_A_marder,
                 uint16_t INPUT_A_categorizedcar) {
    fixedpt adder = 0;
    if (INPUT_A_workshop) {
        // adder = 0.08
        adder = 5242;
    }
    if (INPUT_A_marder) {
        // steps
        fixedpt a = (INPUT_A_categorizedcar + 1) << FIXEDPOINT_FRACTION_BITS;
        // adder += 0.02 * steps
        adder += fixedpt_mul(a, 1310);
    }

    return fixedpt_mul(adder, INPUT_A_price);
}
