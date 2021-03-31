local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/gso'),
      fap.step.deploy_kubernetes('gso'),
    ]
  ),
]
