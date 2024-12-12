#include <stdint.h>

#include "driver.priv.h"

/**
 * Categorize the driver depending on the private data
 * @param INPUT_A_age_driver is the driver older than 24 years?
 * @param INPUT_A_policyholder
 * 0 - insurance taker
 * 1 - spouse
 * 2 - child
 * 3 - loaner
 * 4 - lessor
 * @param INPUT_A_drivers_under_25 number of drivers under age 25 except of the driver
 * @param INPUT_A_diving_license since how many years does the driver own their driving license
 * @param INPUT_A_job: which job does the insurance taker have
 * (0: unemployed, 1: farmer, 2: independent worker 3: employee, 4:  official)
*/
uint16_t mpc_main(struct driver_inputs inputs) {
  uint8_t INPUT_A_age_driver = inputs.INPUT_A_age_driver;
  uint8_t INPUT_A_policyholder = inputs.INPUT_A_policyholder;
  uint8_t INPUT_A_drivers_under_25 = inputs.INPUT_A_drivers_under_25;
  uint8_t INPUT_A_driving_license = inputs.INPUT_A_driving_license;
  uint8_t INPUT_A_job = inputs.INPUT_A_job;

    uint16_t price = 0;

    // Job selection
    switch (INPUT_A_job) {
        case 0:
            price = 50;
            break;
        case 1:
            price = 35;
            break;
        case 2:
            price = 30;
            break;
        case 3:
            price = 25;
            break;
        case 4:
            price = 20;
            break;
    }

    // Driver under 25?
    if (INPUT_A_age_driver == 0) {
        price += 65;
    }

    // Policy holder selection
    switch (INPUT_A_policyholder) {
        case 0: price += 45;
            break;
        case 1: price += 55;
            break;
        case 2: price += 73;
            break;
        case 3: price += 114;
            break;
        case 4: price += 106;
            break;
    }

    // How many drivers are younger than 25
    if (INPUT_A_drivers_under_25 == 0) {
        price += 0;
    } else {
        price += 13 * INPUT_A_drivers_under_25;
    }

    // Possession of driving license more than 5 years?
    if (INPUT_A_driving_license < 5) {
        price += 73;
    }

    return price;
}
