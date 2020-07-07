local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local step = pipeline.step;
local fap = drone.fap;

[
  pipeline.newKubernetes()
  .withSteps(
    [
      // fap.step.golint,
      fap.step.swift_build(packages=[]),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.ssh.deploy,
]
