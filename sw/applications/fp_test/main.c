#include <stdio.h>
#include <stdint.h>
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

int fadd_test() {
    float a, b, c, d, e, f, g;

    a = 658124288;
    b = 196128704;
    c = -589761024;
    d = 0;
    e = 0;
    f = 0;
    g = 0;

    asm volatile (
        "flw    ft0,0(%4)      \n"
        "flw    ft1,0(%5)      \n"
        "flw    ft2,0(%6)      \n"

        "fadd.s ft3,ft0,ft1    \n"
        "fadd.s ft4,ft1,ft0    \n"
        "fsw    ft3,0(%7)      \n"
        "fsw    ft4,0(%8)      \n"

        "fadd.s ft5,ft2,ft1    \n"
        "fadd.s ft6,ft0,ft2    \n"
        "fsw    ft5,0(%9)      \n"
        "fsw    ft6,0(%10)     \n"

        : "=rm" (d), "=rm" (e), "=rm" (f), "=rm" (g)
        : "r" (&a), "r" (&b), "r" (&c), 
          "r" (&d), "r" (&e), "r" (&f), "r" (&g)
        : "ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6"
    );

    if (d == 854252992 && e == 854252992 
        && f == -393632320 && g == 68363264) {
        printf("FADD test OK\n");
        return 0;
    }
    else {
        printf("FADD test FAIL - Values: %x %x %x %x %x %x %x\n", 
               a, b, c, d, e, f, g);
        return 1;
    }
}

int feq_test() {
    float a, b, c, d, e, f;

    a = 658124288;
    b = 196128704;
    c = -589761024;
    d = 1;
    e = 0;
    f = 0;

    asm volatile (
        "flw    ft0,0(%3)      \n"
        "flw    ft1,0(%4)      \n"
        "flw    ft2,0(%5)      \n"

        "feq.s  t3,ft0,ft1    \n" 
        "feq.s  t4,ft1,ft1    \n" 
        "feq.s  t5,ft2,ft2    \n"
        "sw     t3,0(%6)      \n"
        "sw     t4,0(%7)      \n"
        "sw     t5,0(%8)      \n"

        : "=rm" (d), "=rm" (e), "=rm" (f)
        : "r" (&a), "r" (&b), "r" (&c), 
          "r" (&d), "r" (&e), "r" (&f)
        : "t3", "t4", "t5", "ft0", "ft1", "ft2"
    );

    if (d == 0 && e == 1 && f == 1) {
        printf("FEQ test OK\n");
        return 0;
    }
    else {
        printf("FEQ test FAIL - Values: %x %x %x %x %x %x\n", 
               a, b, c, d, e, f);
        return 1;
    }
}

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

int main() {
    printf("Hello F-HEEP!\n");

    fadd_test();
    feq_test();

    return 0;
}
