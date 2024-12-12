#include <stdint.h>
#include "../helper/fixpoint.h"
#include <math.h>

/**
 * adds the price for points in Flensburg
 * @param INPUT_A_price current price
 * @param INPUT_A_points number of points in Flensburg
 * @return new price
*/
fixedpt mpc_main(uint8_t INPUT_A_points) {
    fixedpt result = 0;
    if (INPUT_A_points != 0) {
        // result = 0.05
        result = 3276;
    }
    return result;
}
