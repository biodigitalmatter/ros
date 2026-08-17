{ lib, ... }:

{
  flake.modules.generic.data =
    { ... }:
    {
      options.data = {
        ros.environmentVariables = lib.mkOption {
          type = with lib.types; attrsOf str;
          description = "ROS related environment variables";
        };

        publicSshKeys = lib.mkOption {
          type = with lib.types; listOf str;
          description = "Public SSH key to add to user and root";
        };
      };
      config.data = {
        ros.environmentVariables = {
          ROS_DOMAIN_ID = "55";
          RMW_IMPLEMENTATION = "rmw_fastrtps_cpp";
          FASTDDS_BUILTIN_TRANSPORTS = "LARGE_DATA";
        };
        publicSshKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQClHAMa2N/60UTLWIvaTzyKXvKWLXhNLAAvo77kGzuakRxoMeh31cwiRUHnU3Rm2TbQsv5KhS0TAsoG/FrgoCB/Fo29w4/GuxZl80CfTd6QT2Dt/t1gpeFZk8/TMl61sCaQVwrwOzCjryn1ZoiY+fkX4bNOHDJHguQ40ID4ayLaepZeItA3vPw80ftDC4c6/HsljYT5aE3cFeyK8/MOqNAa5jqnTrrXZCdOA5rIWv7mFHdQ2FS9CreQTohJBAoOLZwoZ0ZArvjNkhrwCkeDM9Qu41dLxKRkdfSgaPInY+RQZnw5hBRooj1opuAe325l5iooj2b1v/389p2ZEZnEtWzr/xgkGht6WiLyat9VztJQaA8nklRuYK1zXJYRfRKPvtNS29x6CIYHTem4txWMEujkqT/w1h1qpUPZtGgnbLMTkadYysEonKOd/un2iTGblhXspkxmvjlXhcvI7ZGrjoCWKYwG/C+2WjEevErq84mqkkP3EGRxIuHOp1w1jInc7MnXVhUC/3cgdv72HsplF3tVpMswavMZ+zwSns6YTztDk5+38HOMC9sy2Pekf6Id6vhZsMvi5qXROrYsqunREi+FyDNO6o23N7ZyDcdUnetv8x+dlPoDF88km323R9GahbLBhl2p744xVwmkq9zaY2CJW51HtWHvogmrbaTy9H55lQ== clarence gpg"
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGsx8DLlfgM7FPtgJhSifRJ69IeLBdfQGZyks79jt2bpAAAABHNzaDo= clarence fido2"
        ];
      };
    };
}
