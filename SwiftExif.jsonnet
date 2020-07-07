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
      // fap.step.golint,
      fap.step.swift_build(packages=[], image='kradalby/swift:groovy'),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.ssh.deploy,
]
