#include <stdint.h>
#include <math.h>
#include "../helper/fixpoint.h"

/**
 * Categorize the driver depending on the private data
 * @param INPUT_A_catcar value of categorize_car function
 * @param INPUT_A_location value of location function
 * @param INPUT_A_catdriver value of driver function
 * @param INPUT_A_carusage value of car_usage function
 * @param INPUT_A_damage_percent surcharge based on prior car accidents
 * @param INPUT_A_flensburg_percent surcharge based on points in flensburg
 * @return returns basic price for insurance based on prior calculations
*/
fixedpt mpc_main(uint16_t INPUT_A_catcar,
                 uint8_t INPUT_A_location,
                 uint16_t INPUT_A_catdriver,
                 uint8_t INPUT_A_carusage,
                 fixedpt INPUT_A_damage,
                 fixedpt INPUT_A_flensburg_percent) {

    fixedpt a = (INPUT_A_catcar << FIXEDPOINT_FRACTION_BITS);
    fixedpt b = fixedpt_mul(a, INPUT_A_flensburg_percent);
    fixedpt c = INPUT_A_damage;
    fixedpt d = (INPUT_A_location << FIXEDPOINT_FRACTION_BITS);
    fixedpt e = (INPUT_A_catdriver << FIXEDPOINT_FRACTION_BITS);
    fixedpt f = (INPUT_A_carusage << FIXEDPOINT_FRACTION_BITS);

    return a + b + c + d + e + f;

}
