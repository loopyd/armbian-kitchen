# Armbian Kitchen
## Zesty Armbian Image Builder

This bash builder framework allows you to build and develop on Armbian images yourself.

## Kitchen Utensils

This table gives short explainers on each of this toolchain's script
| Script | Description |
| ------ | --------------- |
| ``ezflash.sh`` | Allows you to easily flash image to your device EMMC. |
| ``cook.sh`` | Easy-bake oven |
| ``shop.sh`` | Downloader for tools and repositories used by this project.  Use it to get your ingredients. |
| ``lib.sh`` | Common bash functions used by other utensils, part of DeiLib.  Don't modify. |

If you want help on any of the kitchen utensils, you may run ``--help`` at any time during invocation.

## Recipie Cards

### ``armbian.cfg``

This is an example armbian configuration file.  You can take a look at compile.sh options in Armbian documentation to learn more about this.

### ``userpatches/``

This folder allows you to make customizations.  Here I'm providing some for ``orangepi-5-plus`` as examples.
