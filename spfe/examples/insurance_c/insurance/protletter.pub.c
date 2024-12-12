#include <stdint.h>
#include "../helper/fixpoint.h"
/**
 * Computes price based on using a protection letter
 * @param INPUT_A_price previously calculated price
 * @param INPUT_A_extra_surcharge calculated price of extras
 * @param INPUT_A_discount_surcharge calculated price of discount
 * @param INPUT_A_protlet 1 if the insurance taker wants a protection letter, 0 otherwise
 * @return adds 19 to the price if the insurance taker wants a protection letter, 0 otherwise
 */
fixedpt mpc_main(fixedpt INPUT_A_price,
                 fixedpt INPUT_A_extra_surcharge,
                 fixedpt INPUT_A_discount_surcharge,
                 uint8_t INPUT_A_protlet) {
    fixedpt price = INPUT_A_price + INPUT_A_extra_surcharge + INPUT_A_discount_surcharge;
    if (INPUT_A_protlet) {
        // price += 19
        price += 1245184;
    }
    return price;
}
