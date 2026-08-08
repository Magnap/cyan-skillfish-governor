# Cyan Skillfish GPU governor
GPU governor for the AMD Cyan Skillfish APU.
Continously maintains a target frequency, and adjusts the actual GPU frequency when the deviation is too great.
If the CPU is continously busy for too long, ramps up the target frequency rapidly.

Takes a TOML config file path as its only argument.
Keys are:
* `timing`
  * `intervals`: in µs
    * `sample`: how often to sample GPU load
      (it's a single bit, so needs to be sampled more often than you'd think)
    * `adjust`: how often to consider adjusting the frequency
    * `finetune` how long since the last adjustment to consider making a fine-tuning adjustment
  * `burst-samples`: while the GPU has been busy for this many samples in a row,
    enter "burst mode", increasing the frequency at the `timing.ramp_rates.burst` rate.
    Set to 0 to disable burst mode.
  * `ramp_rates`: how quickly to increase/decrease GPU frequency, in MHz/ms
    * `normal`: ramp rate for normal adjustments
    * `burst`: ramp rate in burst mode
* `frequency-thresholds`: in MHz
  * `adjust`: how large a proposed adjustment must be to actually be carried out
  * `finetune`: how large a fine-tuning adjustment must be to be actually carried out
* `load-target`: as a fraction
  * `upper`: GPU load above which target frequency is increased
  * `lower`: GPU load below which target frequency is decreased
* `safe-points`: known safe/stable power points, array of tables with two keys:
  * `frequency`: GPU frequency in MHz
  * `voltage`: GPU supply voltage in mV

See also `default-config.toml`.

## NixOS

This fork ships a flake with a package and a NixOS module. Add the input and
import the module:

```nix
{
  inputs.cyan-skillfish-governor.url = "github:ktaf/cyan-skillfish-governor";

  # in your nixosSystem:
  # modules = [ inputs.cyan-skillfish-governor.nixosModules.default ];
}
```

Then enable the service. All configuration keys above are available under
`settings` and merge with the upstream defaults key by key, so you only set
what you want to change:

```nix
services.cyan-skillfish-governor = {
  enable = true;

  # optional — defaults shown in default-config.toml
  settings = {
    load-target = {
      upper = 0.9;
      lower = 0.6;
    };
    safe-points = [
      { frequency = 350; voltage = 700; }
      { frequency = 2000; voltage = 1000; }
    ];
  };
};
```

The rendered TOML is written to `/etc/cyan-skillfish-governor/config.toml`,
and the service restarts automatically when it changes on rebuild.