local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local step = pipeline.step;
local fap = drone.fap;

[
  pipeline.newMacOS(
    name='MacOS',
  ).withSteps(
    [
      step.new('Lint')
      .withCommands([
        'make lint',
      ]),

      step.new('Build')
      .withCommands([
        'brew bundle',
        'make build',
      ]),

      step.new('Install on local system')
      .withCommands([
        'cp ./.build/x86_64-apple-macosx/debug/munin /Users/kradalby/bin/.',
      ])
      .withWhen(fap.when.master),

      step.new('Publish')
      .withCommands([
        'make publish',
      ])
      .withWhen(fap.when.master),
    ]
  ),
]
