#!/bin/bash

# supervisor takes parameters as: build <ssh_userid> <passwd>
./chaperone-base.sh build vmware vmware

# chaperone:  takes parameters as: <ssh_userid>
./chaperone-dev.sh vmware

# chaperone-lxde: takes no parameters
./chaperone-lxde.sh
