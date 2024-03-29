local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.prettier_lint,
      fap.step.swift_lint,
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/aspargesgaarden2'),
      fap.step.extract_from_container(name='kradalby/aspargesgaarden2', container_path='usr/share/nginx/html'),
      fap.step.github_pages_publish(),
      fap.step.discord,
    ]
  ),
]
