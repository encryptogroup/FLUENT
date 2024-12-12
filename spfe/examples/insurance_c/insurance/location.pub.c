#include <stdint.h>

/**
 * Tarif based on location
 * @param INPUT_A_location categorizing: how much traffic is in this location (0: low, 1: medium, 2: high, 3: very high)
 * @return tarif fraction depending on the traffic
*/
uint8_t mpc_main(uint8_t INPUT_A_location) {
    uint8_t price = 0;
    switch (INPUT_A_location) {
        case 0:price = 12;
            break;
        case 1:price = 28;
            break;
        case 2:price = 46;
            break;
        case 3:price = 69;
            break;
    }
    return price;
}
