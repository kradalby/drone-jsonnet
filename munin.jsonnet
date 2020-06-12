local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local step = pipeline.step;
local fap = drone.fap;

[
  pipeline.newMacOS()
  .withSteps(
    [
      step.new('Ensure tooling')
      .withEnv({
        PATH: fap.variables.path.macos,
      })
      .withCommands([
        'brew bundle',
      ]),
      step.new('Lint')
      .withEnv({
        PATH: fap.variables.path.macos,
      })
      .withCommands([
        'make lint',
      ]),

      step.new('Build')
      .withEnv({
        PATH: fap.variables.path.macos,
      })
      .withCommands([
        'make build',
      ]),

      step.new('Install on local system')
      .withCommands([
        'cp ./.build/x86_64-apple-macosx/debug/munin /Users/kradalby/bin/.',
      ])
      .withWhen(fap.when.master),

      step.new('Publish')
      .withEnv({
        PATH: fap.variables.path.macos,
      })
      .withCommands([
        'make publish',
      ])
      .withWhen(fap.when.master),
    ]
  ),
]
