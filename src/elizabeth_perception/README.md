# elizabeth_perception

## Start cameras systemd

This could have been done using [robot_upstart](https://github.com/clearpathrobotics/robot_upstart) but it doesn't seem to accept yaml launch files.

Service file can be found in [extra/elizabeth-perception@.service](./extra/elizabeth-perception@.service).

Possibly update `User` and `WorkingDirectory`, the latter should be the ROS 2 workspace.

``` sh
sudo cp extra/elizabeth-perception@.service /etc/systemd/system/
sudo systemctl daemon-reload
```

The service file is a template and accepts `oak_usb` or `realsense`, e.g. `elizabeth-perception@oak_usb.service`.

### Start on boot

``` sh
sudo systemctl enable --now elizabeth-perception@oak_usb.service

systemctl status elizabeth-perception@oak_usb.service

journalctl -f -u elizabeth-perception@oak_usb.service
```

### Start when USB camera connected

``` sh
sudo systemctl disable --now elizabeth-perception@oak_usb.service
sudo cp extra/99-elizabeth-perception.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Uninstall systemd and udev files

```sh
sudo systemctl disable --now elizabeth-perception@oak_usb.service
sudo systemctl disable --now elizabeth-perception@realsense.service

sudo rm /etc/systemd/system/elizabeth-perception@.service
sudo systemctl daemon-reload
sudo systemctl reset-failed``

sudo rm -f /etc/udev/rules.d/99-elizabeth-perception.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```
