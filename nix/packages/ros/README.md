# generated using ros2nix

[wentash/ros2nix](https://github.com/wentasah/ros2nix).

## Should match `dependencies.repos`!

## Add more

```sh
nix run github:wentasah/ros2nix -- \
    --output-as-nix-pkg-name \
    --output-as-pkg-dir \
    --patches \
    --fetch flake-inputs \
    --flake \
    --no-overlay \
    --no-shell \
    --nixfmt \
    $(find . -name package.xml)
```
