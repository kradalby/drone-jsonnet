local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

local platforms = [
  base.platform('linux', 'amd64'),
  // base.platform('linux', 'arm64'),
];

// nodeSelector={
//   drone: true,
//   'kubernetes.io/arch': platform.arch,
// }
[
  pipeline.newKubernetes(
    name=platform.arch,
  )
  .withPlatform(platform)
  .withNodeSelector(base.platformToNodeSelector(platform))
  .withSteps(
    [
      fap.step.prettier_lint,
      fap.step.python_lint,
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/speedtest-exporter'),
      fap.step.discord,
    ]
  )
  for platform in platforms
] +
[
  pipeline.newKubernetes(
    name='Docker manifests'
  ).withSteps([
    fap.step.docker_manifest('kradalby/speedtest-exporter', [
      p.os + '/' + p.arch
      for p in platforms
    ],),
  ]).withDependsOn([p.arch for p in platforms]),
]
