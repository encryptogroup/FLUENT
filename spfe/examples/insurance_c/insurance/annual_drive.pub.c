#include <stdint.h>
#include <math.h>
#include "../helper/fixpoint.h"

#include "annual_drive.priv.h"

/**
 * Tarif based on location
 * @param INPUT_A_annualdrivingdist: kilometers driven in a year by the driver
 * @param INPUT_A_basicprice: calculated basic price based on prior calculations
 * @return tarif fraction depending on the distance travelled per year
*/
fixedpt mpc_main(struct annual_drive_inputs inputs) {

  uint16_t INPUT_A_annualdrivingdist = inputs.INPUT_A_annualdrivingdist;
  fixedpt INPUT_A_basicprice = inputs.INPUT_A_basicprice;


    fixedpt price = 0;

    // Limit of driven distance is 40000km/a
    if (INPUT_A_annualdrivingdist > 40000) {
        INPUT_A_annualdrivingdist = 40000;
    }

    // steps
    int8_t factor = (INPUT_A_annualdrivingdist / 5000);

    // a = 1.02
    fixedpt a = 66846;

    // a = 1.02^(steps)
    a = fixedpt_pow(a, factor);

    if (a == 0) {
        price = INPUT_A_basicprice;
    } else {
        price = fixedpt_mul(INPUT_A_basicprice, a);
    }

    return price;
}
