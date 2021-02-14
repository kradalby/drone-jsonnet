local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;


[
  pipeline.newKubernetes(
  ).withSteps(
    [
      // fap.step.super_lint,
      fap.step.prettier_lint,
      fap.step.elm_lint,
      fap.step.kaniko_build,
      fap.step.kaniko_publish('kradalby/resume'),
      fap.step.extract_from_container(name='kradalby/resume', container_path='usr/share/nginx/html'),
      fap.step.github_pages_publish(),
      fap.step.discord,
    ]
  ),
]
