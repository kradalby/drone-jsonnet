local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.prettier_lint,
      fap.step.kaniko_build,
      fap.step.kaniko_publish('kradalby/flexiday'),
      fap.step.extract_from_container(name='kradalby/flexiday', container_path='usr/share/nginx/html'),
      fap.step.github_pages_publish(),
      // fap.step.deploy_kubernetes('flexiday'),
      fap.step.discord,
    ]
  ),
]
