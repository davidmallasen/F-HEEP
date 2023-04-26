#include <stdio.h>
#include <stdlib.h>

// #include "csr.h"
// #include "hart.h"
// #include "handler.h"
// #include "core_v_mini_mcu.h"
// #include "gpio.h"

// #define VCD_TRIGGER_GPIO 0

// static gpio_t gpio;

// void dump_on(void);
// void dump_off(void);

// void dump_on(void) {
//   gpio_params_t gpio_params;
//   gpio_params.base_addr = mmio_region_from_addr((uintptr_t)GPIO_AO_START_ADDRESS);
//   gpio_init(gpio_params, &gpio);
//   gpio_output_set_enabled(&gpio, VCD_TRIGGER_GPIO, true);

//   gpio_write(&gpio, VCD_TRIGGER_GPIO, true);
// }

// void dump_off(void) {
//   gpio_write(&gpio, VCD_TRIGGER_GPIO, false);
// }

float __attribute__((noinline)) floatMul(float A, float B) { 
    return A * B; 
}

int main(int argc, char *argv[]) {
    /* write something to stdout */
    printf("Hello F-HEEP! %x\n", floatMul(0.1f, 0.4f));
    return EXIT_SUCCESS;
}