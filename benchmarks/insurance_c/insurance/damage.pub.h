#include <stdint.h>

typedef struct {
    // how many years ago?
    uint8_t years;

    /*
     * how is it ensured?
     * 0 - no damage
     * 1 - liability
     * 2 - partial covered
     * 3 - fully comprehensive
    */
    uint8_t ensurance;

    // costs in the workshop
    uint16_t workshop_costs;
} damage;
