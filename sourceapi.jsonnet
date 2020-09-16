local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.prettier_lint,
      fap.step.python_lint,
      fap.step.tox,
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/sourceapi'),
      fap.step.deploy_kubernetes('sourceapi'),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.docker.username,
  fap.secret.docker.password,
]
