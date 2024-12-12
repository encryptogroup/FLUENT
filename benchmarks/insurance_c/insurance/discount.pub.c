#include <stdint.h>
#include "../helper/fixpoint.h"
#include <math.h>

/**
 * Compute the discount based on the insurance taker's possibilities and payments
 * @param INPUT_A_price previously calculated price
 * @param INPUT_A_payment payment cycle (0: 1 year, 1: half, 2: quarter, 3: monthly)
 * @param INPUT_A_clubmember 1 if insurance taker is a club member, 0 otherwise
 * @param INPUT_A_publictransport 1 if insurance taker has yearly card for public transport, 0 otherwise
 * @param INPUT_A_access 1 if insurance taker has access to another car, 0 otherwise
 * @return 1 if the driver is at least the age threshold years old, 0 otherwise
 */
fixedpt mpc_main(fixedpt INPUT_A_price,
                 uint8_t INPUT_A_payment,
                 uint8_t INPUT_A_clubmember,
                 uint8_t INPUT_A_publictransport,
                 uint8_t INPUT_A_access) {

    fixedpt discount = 0;

    switch (INPUT_A_payment) {
        case 0:
            // discount = 0
            discount = 0;
            break;
        case 1:
            // discount = 0.01
            discount = 655;
            break;
        case 2:
            // discount = 0.03
            discount = 1966;
            break;
        case 3:
            // discount = 0.05
            discount = 3276;
            break;
    }

    if (INPUT_A_clubmember) {
        // discount -= 0.05
        discount -= 3276;
    }

    if (INPUT_A_publictransport) {
        // discount -= 0.013
        discount -= 851;
    }

    if (INPUT_A_access) {
        // discount -= 0.015
        discount -= 983;
    }

    return fixedpt_mul(INPUT_A_price, discount);
}
