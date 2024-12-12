#include <stdint.h>
#include <math.h>
#include "../helper/fixpoint.h"

#include "driver_person.pub.h"

/**
 * Tarif based on job and SF
 * @param INPUT_A_damagefreeclasshp: damagefreeclass based on kasko
 * @param INPUT_A_damagefreeclassvk: damagefreeclass based on haftpflicht
 * @param INPUT_A_price previously calculated price
*/
struct driver_person_result mpc_main(uint8_t INPUT_A_damagefreeclasshp, uint8_t INPUT_A_damagefreeclassvk, fixedpt INPUT_A_price) {

    fixedpt price = INPUT_A_price;

    // EASIER: 0 - 35(eig: S, M, 1/2), hp: SF5 - SF35: (0,5 - 0.01*(SF-5)), SF4 - SF0 : 55%, 60%, 70%, 85%, 100%
    // helphp = 0.5
    fixedpt helphp = 32768;
    // EASIER: 0 - 35, vk: SF 5 - SF 35: (0,7 - 0.01*(SF-5)), SF4 - SF0: 75%, 85%, 95%, 105%, 115%;
    // helpvk = 0.7
    fixedpt helpvk = 45875;

    // FOR HAFTPFLICHT
    fixedpt a = INPUT_A_damagefreeclasshp << FIXEDPOINT_FRACTION_BITS;
    if (INPUT_A_damagefreeclasshp > 4) {
        // help1 = 0.01
        fixedpt help1 = 655;
        // helphp = 0.5 - 0.01 * (damagefreeclasshp - 5)
        helphp = helphp - fixedpt_mul(help1, (a - (5 << FIXEDPOINT_FRACTION_BITS)));
    } else {
        switch (INPUT_A_damagefreeclasshp) {
            case 4:
                // helphp = 0.55
                helphp = 36044;
                break;
            case 3:
                // helphp = 0.6
                helphp = 39321;
                break;
            case 2:
                // helphp = 0.7
                helphp = 45875;
                break;
            case 1:
                // helphp = 0.85
                helphp = 55705;
                break;
            case 0:
                // helphp = 1
                helphp = 65536;
                break;
        }
    }

    // FOR KASKO
    fixedpt b = INPUT_A_damagefreeclassvk << FIXEDPOINT_FRACTION_BITS;
    if (INPUT_A_damagefreeclassvk > 4) {
        // help1 = 0.01
        fixedpt help1 = 655;
        // helpvk = 0.7 - 0.01 * (damagefreeclassvk - 5)
        helpvk = helpvk - fixedpt_mul(help1, (b - (5 << FIXEDPOINT_FRACTION_BITS)));
    } else {
        switch (INPUT_A_damagefreeclassvk) {
            case 4:
                // helphp = 0.75
                helpvk = 49152;
                break;
            case 3:
                // helphp = 0.85
                helpvk = 55705;
                break;
            case 2:
                // helphp = 0.95
                helpvk = 62259;
                break;
            case 1:
                // helphp = 1.05
                helpvk = 68812;
                break;
            case 0:
                // helphp = 1.15
                helpvk = 75366;
                break;
        }
    }
    // helphp * 1.5 * price || helpvk * 1.5 * price
    struct driver_person_result result;
    result.OUTPUT_pricehp = fixedpt_mul(helphp, fixedpt_mul(price, 81920));
    result.OUTPUT_pricetk = fixedpt_mul(helpvk, fixedpt_mul(price, 81920));
    result.OUTPUT_pricevk = fixedpt_mul(helpvk, fixedpt_mul(price, 81920));
    return result;
}
