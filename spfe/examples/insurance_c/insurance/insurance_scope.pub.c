#include <stdint.h>
#include <math.h>
#include "../helper/fixpoint.h"

/**
 * Tarif based on self share
 * @param INPUT_A_pricehp: previously calculated haftpflicht price
 * @param INPUT_A_pricetk: previously calculated teilkasko price
 * @param INPUT_A_pricevk: previously calculated vollkasko price
 * @param INPUT_A_selfpart: share payed when an accident happens
 * @param INPUT_A_paket: which paket is taken (0: haftpflicht, 1: teilkasko, 2: vollkasko)
 * @return tarif fraction depending on self share and the paket the insurance taker chose
*/
fixedpt mpc_main(fixedpt INPUT_A_pricehp,
                 fixedpt INPUT_A_pricetk,
                 fixedpt INPUT_A_pricevk,
                 uint16_t INPUT_A_selfpart,
                 uint8_t INPUT_A_paket) {

    fixedpt price = 0;

    // helper = 0.15
    fixedpt helper = 9830;

    fixedpt temp = 0;

    // shifted selfpart
    fixedpt shifted_selfpart = INPUT_A_selfpart << FIXEDPOINT_FRACTION_BITS;

    switch (INPUT_A_paket) {
        case 0: price = INPUT_A_pricehp;
            break;
        case 1: price = INPUT_A_pricetk;
            // temp = 150
            temp = 9830400;
            // temp = selfpart/150
            temp = fixedpt_div(shifted_selfpart, temp);
            // temp = (selfpart/150) * 20%
            temp = fixedpt_mul(temp, helper);
            // price = price - (20% * (selfpart/150)) * price
            price = price - fixedpt_mul(price, temp);
            break;
        case 2: price = INPUT_A_pricevk;
            // temp = 300
            temp = 19660800;
            // temp = selfpart/300
            temp = fixedpt_div(shifted_selfpart, temp);
            // temp = (selfpart/300) * 20%
            temp = fixedpt_mul(temp, helper);
            // price = price - (20% * (selfpart/300)) * price
            price = price - fixedpt_mul(price, temp);
            break;
    }

    return price;
}
