{
  config,
  disko,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.disko.cfg;
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.disko.cfg = {
    mainDevice = mkOption {
      type = types.str;
      description = "Main disk name";
    };
  };

  config = {
    disko.devices.disk.ssd = {
      device = cfg.mainDevice;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "root"
              ];
              mountpoint = "/";
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}
