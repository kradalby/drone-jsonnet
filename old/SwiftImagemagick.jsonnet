local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local step = pipeline.step;
local fap = drone.fap;

local packages = ['libmagickcore-dev'];

[
  pipeline.newKubernetes()
  .withSteps(
    [
      fap.step.prettier_lint,
      fap.step.swift_lint,
      fap.step.swift_test(packages=packages, image='kradalby/swift:groovy'),
      fap.step.swift_build(packages=packages, image='kradalby/swift:groovy'),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.ssh.deploy,
]
