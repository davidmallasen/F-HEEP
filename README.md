# F-HEEP

System integrating [fpu_ss](https://github.com/pulp-platform/fpu_ss) into [X-HEEP](https://github.com/esl-epfl/x-heep) via the [eXtension interface](https://docs.openhwgroup.org/projects/openhw-group-core-v-xif).

## Setup

Tested in Ubuntu 22.04.
First, create a python virtual environment and install the required packages:
~~~
python -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r python_requirements.txt
~~~

Then, generate the files from X-HEEP to use the cv32e40x CPU.
For this you will need the `core-v-mini-mcu` conda environment of X-HEEP. Check X-HEEP's `README` for more information.
~~~
deactivate
conda activate core-v-mini-mcu

make mcu-gen CPU=cv32e40x

conda deactivate
source venv/bin/activate
~~~

## Compiling applications

To compile the test application in `sw/applications/fp_test`, run:
~~~
make app PROJECT=fp_test ARCH=rv32imfc
~~~

Remember to check the rest of the flags from the `make app` command as well, in particular `TARGET` and `LINKER`. You can find them in X-HEEP's `README`.

More information on how to building external applications leveraging X-HEEP's compilation flow can be found in the `eXtendingHEEP.md` documentation in X-HEEP.

## Simulating on QuestaSim

To simulate F-HEEP using FuseSoC on QuestaSim run:
~~~
make sim
cd build/davidmallasen_ip_fheep_0.0.1/sim-modelsim/
make run PLUSARGS="c firmware=../../../sw/build/main.hex"
~~~

or for the HDL optimized version:
~~~
make sim-opt
cd build/davidmallasen_ip_fheep_0.0.1/sim-modelsim/
make run RUN_OPT=1 PLUSARGS="c firmware=../../../sw/build/main.hex"
~~~

In any of these cases change `run` with `run-gui` to open the QuestaSim GUI. To visualize the waveform, the HDL optimized version should be run.

In any of these cases add `FUSESOC_FLAGS="--flag=use_external_device_example"` to the `make sim` or `make sim-opt` command if you want to execute from flash memory.

## FPGA Synthesis

We support FPGA synthesis to the pynq-z2 board.

To synthesize F-HEEP using FuseSoC on Vivado run:
~~~
make synth-pynq-z2
~~~

## Vendor
To update the vendorized repositories run:
~~~
make vendor
~~~