# F-HEEP

System integrating [fpu_ss](https://github.com/pulp-platform/fpu_ss) into [X-HEEP](https://github.com/esl-epfl/x-heep) via the [eXtension interface](https://docs.openhwgroup.org/projects/openhw-group-core-v-xif).

## Setup

First, create a python virtual environment and install the required packages:

~~~bash
python -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r python_requirements.txt
~~~

Then, generate the files from X-HEEP to use the [cv32e40px](https://github.com/esl-epfl/cv32e40px) CPU.
For this you will need the `core-v-mini-mcu` conda environment of X-HEEP. Check X-HEEP's `README` for more information.

~~~bash
deactivate
conda activate core-v-mini-mcu

make mcu-gen CPU=cv32e40px

conda deactivate
source venv/bin/activate
~~~

## Compiling applications

To compile the test application in `sw/applications/fp_test`, run:

~~~bash
make app PROJECT=fp_test ARCH=rv32imfc
~~~

Remember to check the rest of the flags from the `make app` command as well, in particular `TARGET` and `LINKER`. You can find them in X-HEEP's documentation.

More information on how to building external applications leveraging X-HEEP's compilation flow can be found in the `eXtendingHEEP.md` documentation in X-HEEP.

If you need more memory for your application, you can increase the number of memory banks
with the `MEMORY_BANKS` argument of `mcu-gen`. For example:

~~~bash
make mcu-gen CPU=cv32e40px MEMORY_BANKS=4
~~~

## Simulating on QuestaSim

To simulate F-HEEP using FuseSoC on QuestaSim run:

~~~bash
make sim
cd build/davidmallasen_ip_fheep_0.0.1/sim-modelsim/
make run PLUSARGS="c firmware=../../../sw/build/main.hex"
~~~

or for the HDL optimized version:

~~~bash
make sim-opt
cd build/davidmallasen_ip_fheep_0.0.1/sim-modelsim/
make run RUN_OPT=1 PLUSARGS="c firmware=../../../sw/build/main.hex"
~~~

In any of these cases change `run` with `run-gui` to open the QuestaSim GUI. To visualize the waveform, the HDL optimized version should be run.

If you want to execute from flash memory, you will also need the `boot_sel=1 execute_from_flash=1`
flags when running. For example, to run with `flash_exec`:

~~~bash
make sim-opt
cd build/davidmallasen_ip_fheep_0.0.1/sim-modelsim/
make run RUN_OPT=1 PLUSARGS="c firmware=../../../sw/build/main.hex boot_sel=1 execute_from_flash=1"
~~~

## Running on FPGA

We support FPGA synthesis to the pynq-z2 board.

To synthesize F-HEEP using FuseSoC on Vivado (tested on Vivado 2022.2) run:

~~~bash
make synth-pynq-z2
~~~

Then to program the bitstream, open Vivado,

~~~text
open --> Hardware Manager --> Open Target --> Autoconnect --> Program Device
~~~

and choose the file `F-HEEP/build/davidmallasen_ip_fheep_0.0.1/synth-pynq-z2/davidmallasen_ip_fheep_0.0.1.bit`.

To run applications on it using the EPFL programmer first recompile the application to
target the `pynq-z2`. Then follow the instructions to [program the flash](https://x-heep.readthedocs.io/en/latest/How_to/ProgramFlash.html)
and then to [execute from flash](https://x-heep.readthedocs.io/en/latest/How_to/ExecuteFromFlash.html).

Finally, you can see the output of the application using picocom:

~~~bash
picocom -b 9600 -r -l --imap lfcrlf /dev/ttyUSB2
~~~

## Vendor

To update the vendorized repositories run:

~~~bash
make vendor
~~~

When revendorizing X-HEEP, remember to regenerate the files from X-HEEP to use the cv32e40px CPU as stated in the [Setup](#setup).
