{ config, ... }:
let

in
{
  sops.templates."jellyfin.env".content = ''
  
  '';
}
