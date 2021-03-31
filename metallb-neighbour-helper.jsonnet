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
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/metallb-neighbour-helper'),
    ]
  ),
]
