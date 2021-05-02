local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local step = pipeline.step;
local fap = drone.fap;

local packages = ['libexif-dev', 'libiptcdata-dev'];

[
  pipeline.newKubernetes()
  .withSteps(
    [
      fap.step.prettier_lint,
      fap.step.swift_lint,
      fap.step.swift_test(packages=[], image='kradalby/swift:5.4-hirsute'),
      fap.step.swift_build(packages=[], image='kradalby/swift:5.4-hirsute'),
      fap.step.discord,
    ]
  ),
]
