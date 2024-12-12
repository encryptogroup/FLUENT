#include <stdint.h>

/**
 * Compute if the driver is at least the age threshold years old
 * @param INPUT_A_age age of the driver
 * @return 1 if the driver is at least the age threshold years old, 0 otherwise
 */
uint8_t mpc_main(uint8_t INPUT_A_age, uint8_t INPUT_B_age_threshold) {
    uint8_t result = 1;
    if (INPUT_A_age < INPUT_B_age_threshold) {
        result = 0;
    }
    return result;
}
