// Add secrets:
// drone secret add kradalby/packer --name vcenter_password --data $VCENTER_PASSWORD
// drone secret add kradalby/packer --name vcenter_login --data $VCENTER_LOGIN
// drone secret add kradalby/packer --name vcenter_host --data $VCENTER_HOST

local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local step = pipeline.step;
local fap = drone.fap;

local env_secret_dict = {
  VCENTER_HOST: 'vcenter_host',
  VCENTER_LOGIN: 'vcenter_login',
  VCENTER_PASSWORD: 'vcenter_password',
};

[
  pipeline.newVmwarePacker(
  ).withSteps(
    [
      step.new('Build Ubuntu 20.04')
      .withEnv(base.env_from_secret(env_secret_dict))
      .withCommands([
        'cd ubuntu',
        'packer build 2004.json',
      ])
      .withWhen(fap.when.master { event+: ['cron'] }),
    ]
  ),
]
