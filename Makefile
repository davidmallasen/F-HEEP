# Copyright 2023 David Mallasén Quintana
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: David Mallasén <dmallase@ucm.es>
# Description: F-HEEP top-level makefile

MAKE = make

all: help

vendor: vendor-xheep

vendor-xheep:
	./util/vendor.py hw/vendor/esl_epfl_x_heep.vendor.hjson -v --update

sim:
	fusesoc --cores-root . run --no-export --target=sim $(FUSESOC_FLAGS) --setup --build davidmallasen:ip:fheep:0.0.1 2>&1 | tee build_sim.log

sim-opt: sim
	$(MAKE) -C build/davidmallasen_ip_fheep_0.0.1/sim-modelsim opt

synth-pynq-z2:
	fusesoc --cores-root . run --no-export --target=pynq-z2 --setup --build davidmallasen:ip:fheep:0.0.1 2>&1 | tee build_synth-pynq-z2.log

clean:
	rm -rf build

help:
	@echo "[WIP] See the Makefile for options"

# Include X-HEEP targets
export HEEP_DIR = hw/vendor/esl_epfl_x_heep/
XHEEP_MAKE = $(HEEP_DIR)/external.mk
include $(XHEEP_MAKE)
