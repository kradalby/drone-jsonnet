local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

local env_secret_dict = {
  HUGIN_MAPBOX_ACCESS_TOKEN: 'hugin_mapbox_access_token',
  HUGIN_ROLLBAR_ACCESS_TOKEN: 'hugin_rollbar_access_token',
  HUGIN_SENTRY_DSN: 'hugin_sentry_dsn',
};

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.node_lint,
      fap.step.kaniko_build,
      fap.step.kaniko_publish('kradalby/hugin') +
      {
        environment: base.env_from_secret(env_secret_dict),
        settings+: {
          build_args_from_env: std.objectFields(env_secret_dict),
        },
      },
      fap.step.extract_from_container(name='kradalby/hugin', container_path='usr/share/nginx/html'),
      fap.step.deploy_builds(path='/storage/serve/builds/hugin'),
      fap.step.deploy_kubernetes('hugin'),
      fap.step.deploy_kubernetes('hugindemo', repo='kradalby/hugin') +
      {
        environment+: {
          KUBERNETES_CERT: {
            from_secret: 'demo_kubernetes_cert',
          },
          KUBERNETES_SERVER: {
            from_secret: 'demo_kubernetes_server',
          },
          KUBERNETES_token: {
            from_secret: 'demo_kubernetes_token',
          },
        },
      },
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.docker.username,
  fap.secret.docker.password,
  fap.secret.ssh.deploy,
]
