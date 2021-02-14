local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.prettier_lint,
      fap.step.go_lint,
      fap.step.go_test,
      fap.step.go_build,
      fap.step.deploy_scp(path='/fastest/serve/builds/terraform-provider-opnsense', host='core.terra.fap.no'),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.ssh.deploy,
]
