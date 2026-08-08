{ config, lib, pkgs, ... }:
let
  cfg = config.services.cyan-skillfish-governor;
  settingsFormat = pkgs.formats.toml { };
  configFile = settingsFormat.generate "cyan-skillfish-governor.toml" cfg.settings;
in
{
  options.services.cyan-skillfish-governor = {
    enable = lib.mkEnableOption "Cyan Skillfish GPU Governor";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The cyan-skillfish-governor package to use.";
      defaultText = lib.literalExpression "cyan-skillfish-governor.packages.\${pkgs.system}.default";
    };

    settings = lib.mkOption {
      default = { };
      description = ''
        Governor configuration written to
        {file}`/etc/cyan-skillfish-governor/config.toml`.
        Defaults match the upstream `default-config.toml`;
        set only the keys you want to change.
      '';
      type = lib.types.submodule {
        freeformType = settingsFormat.type;

        options = {
          timing = {
            intervals = {
              sample = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 2000;
                description = "How often to sample GPU load, in µs.";
              };
              adjust = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 20000;
                description = "How often to consider adjusting the frequency, in µs.";
              };
              finetune = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 1000000000;
                description = "How long since the last adjustment to consider a fine-tuning adjustment, in µs.";
              };
            };

            ramp-rates = {
              normal = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 1;
                description = "Ramp rate for normal adjustments, in MHz/ms.";
              };
              burst = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 200;
                description = "Ramp rate in burst mode, in MHz/ms.";
              };
            };

            burst-samples = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 48;
              description = "Enter burst mode after the GPU has been busy this many samples in a row. 0 disables burst mode.";
            };
          };

          frequency-thresholds = {
            adjust = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 100;
              description = "Minimum size of a proposed adjustment to be carried out, in MHz.";
            };
            finetune = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 10;
              description = "Minimum size of a fine-tuning adjustment to be carried out, in MHz.";
            };
          };

          load-target = {
            upper = lib.mkOption {
              type = lib.types.numbers.between 0 1;
              default = 0.95;
              description = "GPU load above which target frequency is increased.";
            };
            lower = lib.mkOption {
              type = lib.types.numbers.between 0 1;
              default = 0.7;
              description = "GPU load below which target frequency is decreased.";
            };
          };

          safe-points = lib.mkOption {
            default = [
              { frequency = 350; voltage = 700; }
              { frequency = 2000; voltage = 1000; }
            ];
            description = "Known safe/stable power points.";
            type = lib.types.listOf (lib.types.submodule {
              options = {
                frequency = lib.mkOption {
                  type = lib.types.ints.unsigned;
                  description = "GPU frequency in MHz.";
                };
                voltage = lib.mkOption {
                  type = lib.types.ints.unsigned;
                  description = "GPU supply voltage in mV.";
                };
              };
            });
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."cyan-skillfish-governor/config.toml".source = configFile;

    systemd.services.cyan-skillfish-governor = {
      description = "Cyan Skillfish GPU Governor";
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ configFile ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/cyan-skillfish-governor /etc/cyan-skillfish-governor/config.toml";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
