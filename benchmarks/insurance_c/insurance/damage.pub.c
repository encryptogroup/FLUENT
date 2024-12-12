#include <stdint.h>
#include "../helper/fixpoint.h"
#include <math.h>

#include "damage.pub.h"

/**
 * calculates the percent of surcharge depending on the damage of the last years (only considering two damages)
 * @param INPUT_A_dmg1 first damage
 * @param INPUT_A_dmg2 second damage
 * @param INPUT_B_workshopthres threshold for workshop costs
 * @param INPUT_B_yearsthres threshold for how many years ago a damage is
 * @param INPUT_B_liabilitycosts additional charge for damage with liability ensurance
 * @param INPUT_B_particalcoveredcosts additional charge for damage with partial covered ensurance
 * @param INPUT_B_fullycomprehensivecosts additional charge for damage with fully comprehensived ensurance
 * @param INPUT_B_workshopcosts additional charge for too high costs in the workshop
 * @return percent of surcharge
*/
fixedpt mpc_main(damage INPUT_A_dmg1,
                 damage INPUT_A_dmg2,
                 uint8_t INPUT_B_workshopthres,
                 uint8_t INPUT_B_yearsthres,
                 fixedpt INPUT_B_liabilitycosts,
                 fixedpt INPUT_B_partialcoveredcosts,
                 fixedpt INPUT_B_fullycomprehensivecosts,
                 fixedpt INPUT_B_workshopcosts) {
    fixedpt percent = 0;
    uint8_t dmg1_wscosts = (INPUT_A_dmg1.workshop_costs > INPUT_B_workshopthres);
    uint8_t dmg2_wscosts = (INPUT_A_dmg2.workshop_costs > INPUT_B_workshopthres);
    uint8_t dmg1_years = (INPUT_A_dmg1.years <= INPUT_B_yearsthres);
    uint8_t dmg2_years = (INPUT_A_dmg2.years <= INPUT_B_yearsthres);

    // First accident happened before less than threshold
    if (dmg1_years) {
        // add value based on former insurance type
        switch (INPUT_A_dmg1.ensurance) {
            case 1: percent += INPUT_B_liabilitycosts;
                break;
            case 2: percent += INPUT_B_partialcoveredcosts;
                break;
            case 3: percent += INPUT_B_fullycomprehensivecosts;
                break;
        }
    }
    // First accident costs more than threshold
    if (dmg1_wscosts) {
        percent += INPUT_B_workshopcosts;
    }
    // First accident happened before less than threshold
    if (dmg2_years) {
        // add value based on former insurance type
        switch (INPUT_A_dmg2.ensurance) {
            case 1: percent += INPUT_B_liabilitycosts;
                break;
            case 2: percent += INPUT_B_partialcoveredcosts;
                break;
            case 3: percent += INPUT_B_fullycomprehensivecosts;
                break;
        }
    }
    // First accident costs more than threshold
    if (dmg2_wscosts) {
        percent += INPUT_B_workshopcosts;
    }
    return percent;
}
