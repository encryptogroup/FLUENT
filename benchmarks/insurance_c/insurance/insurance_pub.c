#include "../helper/fixpoint.h"
#include <math.h>
#include <stdint.h>

#include "../libc/musl/src/stdlib/abs.c"

#define mpc_main categorize_car
#include "categorize_car.pub.c"
#undef mpc_main

#define mpc_main age
#include "age.pub.c"
#undef mpc_main

#define mpc_main driver
#include "driver.pub.c"
#undef mpc_main

#define mpc_main damage_fn
#include "damage.pub.c"
#undef mpc_main

#define mpc_main location
#include "location.pub.c"
#undef mpc_main

#define mpc_main flensburg
#include "flensburg.pub.c"
#undef mpc_main

#define mpc_main car_usage
#include "car_usage.pub.c"
#undef mpc_main

#define mpc_main calculate_basic_price
#include "calculate_basic_price.pub.c"
#undef mpc_main

#define mpc_main saison
#include "saison.pub.c"
#undef mpc_main

#define mpc_main annual_drive
#include "annual_drive.pub.c"
#undef mpc_main

#define mpc_main driver_person
#include "driver_person.pub.c"
#undef mpc_main

#define mpc_main insurance_scope
#include "insurance_scope.pub.c"
#undef mpc_main

#define mpc_main extras
#include "extras.pub.c"
#undef mpc_main

#define mpc_main discount
#include "discount.pub.c"
#undef mpc_main

#define mpc_main protletter
#include "protletter.pub.c"
#undef mpc_main

#pragma hls_top
fixedpt insurance(
    // categorization of the car
    uint8_t INPUT_A_hsn, uint16_t INPUT_A_tsn, uint8_t INPUT_A_firstlic,
    uint8_t INPUT_A_takerlic,

    // driver's personal information
    uint8_t INPUT_A_age, uint8_t INPUT_A_policyholder,
    uint8_t INPUT_A_drivers_under_25, uint8_t INPUT_A_driving_license,
    uint8_t INPUT_A_job,

    // previous damage of the driver
    damage INPUT_A_dmg1, damage INPUT_A_dmg2,

    // driver's background
    uint8_t INPUT_A_location, uint8_t INPUT_A_points,
    uint8_t INPUT_A_parkingspace, uint8_t INPUT_A_carusage,

    // car usage information
    uint8_t INPUT_A_month, uint16_t INPUT_A_annualdrivingdist,

    // damage free classes
    uint8_t INPUT_A_damagefreeclasshp, uint8_t INPUT_A_damagefreeclassvk,

    // scope of the insurance
    uint16_t INPUT_A_selfpart, uint8_t INPUT_A_paket, uint8_t INPUT_A_workshop,
    uint8_t INPUT_A_marder,

    // discounts
    uint8_t INPUT_A_payment, uint8_t INPUT_A_clubmember,
    uint8_t INPUT_A_publictransport, uint8_t INPUT_A_access,

    // protection letter
    uint8_t INPUT_A_protlet,

    // threshold for age of driver
    uint8_t INPUT_B_age_threshold,

    // threshold for damages
    uint8_t INPUT_B_workshopthres, uint8_t INPUT_B_yearsthres,

    // additional charges for damages
    fixedpt INPUT_B_liabilitycosts, fixedpt INPUT_B_partialcoveredcosts,
    fixedpt INPUT_B_fullycomprehensivecosts, fixedpt INPUT_B_workshopcosts

) {

  struct categorize_car_result categorize_car_result = categorize_car(
      {INPUT_A_hsn, INPUT_A_tsn, INPUT_A_firstlic, INPUT_A_takerlic});

  uint8_t age_result = age(INPUT_A_age, INPUT_B_age_threshold);

  uint16_t driver_result =
      driver({age_result, INPUT_A_policyholder, INPUT_A_drivers_under_25,
             INPUT_A_driving_license,
             INPUT_A_job});

  fixedpt damage_result = damage_fn(
      INPUT_A_dmg1, INPUT_A_dmg2, INPUT_B_workshopthres, INPUT_B_yearsthres,
      INPUT_B_liabilitycosts, INPUT_B_partialcoveredcosts,
      INPUT_B_fullycomprehensivecosts, INPUT_B_workshopcosts);

  uint8_t location_result = location(INPUT_A_location);

  fixedpt flensburg_result = flensburg(INPUT_A_points);

  uint8_t car_usage_result = car_usage({INPUT_A_parkingspace, INPUT_A_carusage});

  fixedpt calculate_basic_price_result = calculate_basic_price(
      categorize_car_result.OUTPUT_catcar, location_result, driver_result,
      car_usage_result, damage_result, flensburg_result);

  fixedpt saison_result = saison(INPUT_A_month, calculate_basic_price_result);

  fixedpt annual_drive_result =
      annual_drive({INPUT_A_annualdrivingdist, saison_result});

  struct driver_person_result driver_person_result =
      driver_person(INPUT_A_damagefreeclasshp, INPUT_A_damagefreeclassvk,
                    annual_drive_result);

  fixedpt insurance_scope_result = insurance_scope(
      driver_person_result.OUTPUT_pricehp, driver_person_result.OUTPUT_pricetk,
      driver_person_result.OUTPUT_pricevk, INPUT_A_selfpart, INPUT_A_paket);

  fixedpt extras_result =
      extras(insurance_scope_result, INPUT_A_workshop, INPUT_A_marder,
             categorize_car_result.OUTPUT_catcar);

  fixedpt discount_result =
      discount(insurance_scope_result, INPUT_A_payment, INPUT_A_clubmember,
               INPUT_A_publictransport, INPUT_A_access);

  fixedpt protletter_result = protletter(insurance_scope_result, extras_result,
                                         discount_result, INPUT_A_protlet);

  return protletter_result;
}
