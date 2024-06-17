#!/usr/bin/env sh

# Adapted from https://github.com/luxonis/depthai-ros/blob/79e2127499df8f4bdd495899c73a77027a3a9655/install_dependencies.sh
# after suggestion from https://github.com/luxonis/depthai-ros/issues/540#issuecomment-2168977882

set -e

dpkg -r --force-depends ros-noetic-depthai

echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"' | sudo tee /etc/udev/rules.d/80-movidius.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
cd /tmp
git clone --recursive https://github.com/luxonis/depthai-core.git --branch v2.24.0
cmake -Hdepthai-core -Bdepthai-core/build -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build depthai-core/build --target install
cd /tmp
rm -r depthai-core
