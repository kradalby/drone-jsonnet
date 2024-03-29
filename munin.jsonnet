local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local step = pipeline.step;
local fap = drone.fap;

local packages = ['libexif-dev', 'libmagickwand-6.q16-dev', 'libiptcdata0-dev', 'libsqlite3-dev'];

[
  pipeline.newKubernetes(name='Docker build')
  .withSteps(
    [
      fap.step.prettier_lint,
      fap.step.swift_lint,
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/munin'),
      fap.step.discord,
    ]
  ),
  pipeline.newKubernetes(name='Swift build')
  .withSteps(
    [
      fap.step.prettier_lint,
      fap.step.swift_lint,
      fap.step.swift_test(packages=packages, image='kradalby/swift:5.4-groovy'),
      fap.step.swift_build(packages=packages, image='kradalby/swift:5.4-groovy'),
      fap.step.swift_release(packages=packages,
                             name='munin',
                             image='kradalby/swift:5.4-groovy'),
      fap.step.deploy_scp(path='/fastest/serve/builds/munin/linux_x64', host='core.terra.fap.no'),
      fap.step.discord,
    ]
  ),
]
// pipeline.newMacOS()
// .withSteps(
// [
// step.new('Ensure tooling and deps')
// .withEnv({
// PATH: fap.variables.path.macos,
// })
// .withCommands([
// 'brew bundle',
// ]),
// step.new('Lint')
// .withEnv({
// PATH: fap.variables.path.macos,
// })
// .withCommands([
// 'make lint',
// ]),
//
// step.new('Build')
// .withEnv({
// PATH: fap.variables.path.macos,
// })
// .withCommands([
// 'make build-release',
// ]),
//
// step.new('Build cross-platform')
// .withEnv({
// PATH: fap.variables.path.macos,
// })
// .withCommands([
// 'make build-cross',
// ]),
//
// step.new('Install on local system')
// .withCommands([
// 'cp ./.build/release/munin /Users/kradalby/bin/.',
// ])
// .withWhen(fap.when.master),
//
// step.new('Publish')
// .withEnv({
// PATH: fap.variables.path.macos,
// })
// .withCommands([
// 'make publish',
// ])
// .withWhen(fap.when.master),
// ]
// ),
