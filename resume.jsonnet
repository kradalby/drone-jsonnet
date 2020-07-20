local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.node_lint,
      fap.step.kaniko_build,
      fap.step.kaniko_publish('kradalby/resume'),
      fap.step.extract_from_container(name='kradalby/resume', container_path='usr/share/nginx/html'),
      fap.step.github_pages_publish(),
      fap.step.deploy_kubernetes('resume'),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.docker.username,
  fap.secret.docker.password,
  fap.secret.github_pages_push.username,
  fap.secret.github_pages_push.token,
]
