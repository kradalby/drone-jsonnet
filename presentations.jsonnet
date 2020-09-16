local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.prettier_lint,
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/presentations'),
      fap.step.deploy_kubernetes('presentations'),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.docker.username,
  fap.secret.docker.password,
]
