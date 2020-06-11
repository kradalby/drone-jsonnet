local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.golint,
      fap.step.gox,
      fap.step.email,
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
]
