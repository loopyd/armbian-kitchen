# The Recipie Folder

This folder allows you to load in your own recipie cards to automate the kitchen in an unattended manner. You can modify the included files as you need to suit your own image.

## Recipie Cards

### ``config-grassypi.conf``

This is a armbian build configuration file.  You can take a look at [Build Options](https://docs.armbian.com/Developer-Guide_Build-Options/) in the [Armbian Developer Documentation](https://docs.armbian.com/Developer-Guide_Welcome/) to learn more about available options.

These options are passed directly to ``compile.sh`` from the [Armbian Build Framework](https://github.com/armbian/build) at runtime.

### ``linux-rk35xx-vendor.config``

Kernel configuration file for the image.  You can modify it to your liking.

### ``userpatches/``

This folder allows you to make userpatch customizations.  You can have a look at [User Configurations](https://docs.armbian.com/Developer-Guide_User-Configurations/) in the [Armbian Developer Documentation](https://docs.armbian.com/Developer-Guide_Welcome/) to learn more about what this folder is for.

### ``lib.config``

You can create this file (not included) to hold secrets.  Ensure that this file remains excluded in ``.gitignore`` to follow best practices.

### Inlcuded Custom Extensions

The following custom extensions can be used with this kitchen, and are included in the recipe:

| Name | Description | Link |
| ------ | ---------------------- | ------ |
| ``rtl8852be-fix`` | Fix the rtw89 drivers for the vendor kernel for the "recommended" Wi-Fi module. | [src](./userpatches/extensions/rtl8852be-fix/) |
| ``xrdp`` | Enable access to your node via XRDP remote desktop | [src](./userpatches/extensions/xrdp/) |
| ``pingpong`` | DePin service to contribute your device execution power to the DePin network | [src](./userpatches//extensions/pingpong/) |
| ``docker`` | Install and run docker-ce on your device. | [src](./userpatches/extensions/docker/) |
