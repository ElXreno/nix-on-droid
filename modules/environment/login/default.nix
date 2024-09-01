# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, initialPackageInfo, targetSystem, ... }:

with lib;

let
  cfg = config.environment.files;

  login = pkgs.callPackage ./login.nix { inherit config; };

  loginInner = pkgs.callPackage ./login-inner.nix {
    inherit config initialPackageInfo targetSystem;
  };
in

{

  ###### interface

  options = {

    environment.files = {
      login = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Login script.";
      };

      loginInner = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Login-inner script.";
      };

      prootStatic = mkOption {
        type = types.package;
        internal = true;
        description = "<literal>proot-static</literal> package.";
      };
    };

  };


  ###### implementation

  config = {

    build.activation = {
      installLogin = ''
        if ! diff /bin/login ${login} > /dev/null; then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin
          $DRY_RUN_CMD cp $VERBOSE_ARG ${login} /bin/.login.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /bin/.login.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /bin/.login.tmp /bin/login
        fi
      '';

      installLoginInner = ''
        if (test -e /usr/lib/.login-inner.new && ! diff /usr/lib/.login-inner.new ${loginInner} > /dev/null) || \
            (! test -e /usr/lib/.login-inner.new && ! diff /usr/lib/login-inner ${loginInner} > /dev/null); then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /usr/lib
          $DRY_RUN_CMD cp $VERBOSE_ARG ${loginInner} /usr/lib/.login-inner.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /usr/lib/.login-inner.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /usr/lib/.login-inner.tmp /usr/lib/.login-inner.new
        fi
      '';

      installProotStatic = ''
        if (test -e /bin/.proot-static.new && ! diff /bin/.proot-static.new ${cfg.prootStatic}/bin/proot-static > /dev/null) || \
            (! test -e /bin/.proot-static.new && ! diff /bin/proot-static ${cfg.prootStatic}/bin/proot-static > /dev/null); then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin
          $DRY_RUN_CMD cp $VERBOSE_ARG ${cfg.prootStatic}/bin/proot-static /bin/.proot-static.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /bin/.proot-static.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /bin/.proot-static.tmp /bin/.proot-static.new
        fi
      '';
    };

    environment.files = {
      inherit login loginInner;

      prootStatic =
        let
          crossCompiledPaths = {
            aarch64-linux = "/nix/store/7qd99m1w65x2vgqg453nd70y60sm3kay-proot-termux-static-aarch64-unknown-linux-android-unstable-2024-05-04";
            x86_64-linux = "/nix/store/pakj3svvw84rhkzdc6211yhc2cgvc21f-proot-termux-static-x86_64-unknown-linux-android-unstable-2024-05-04";
          };
        in
        "${crossCompiledPaths.${targetSystem}}";
    };

  };

}
