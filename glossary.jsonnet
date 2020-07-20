local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/glossary'),
      fap.step.extract_from_container(name='kradalby/glossary', container_path='usr/share/nginx/html'),
      fap.step.github_pages_publish(),
      fap.step.deploy_kubernetes('glossary'),
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
