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
      fap.step.prettier_lint,
      fap.step.elm_lint,
      fap.step.docker_build,
      fap.step.docker_publish('kradalby/hugin') +
      {
        environment: base.env_from_secret(env_secret_dict),
        settings+: {
          build_args_from_env: std.objectFields(env_secret_dict),
        },
      },
      fap.step.extract_from_container(name='kradalby/hugin', container_path='usr/share/nginx/html'),
      fap.step.deploy_rsync(
        path='/fastest/serve/hugin/',
        exclude=['content', 'munin.json', '50x.html', 'people.json', 'legacy_people.json'],
        args=['--delete', '--omit-dir-times', '--no-perms'],
      ),
      // fap.step.deploy_kubernetes('hugin'),
      // fap.step.deploy_kubernetes('hugindemo', repo='kradalby/hugin') +
      // {
      //   environment+: {
      //     KUBERNETES_CERT: {
      //       from_secret: 'demo_kubernetes_cert',
      //     },
      //     KUBERNETES_SERVER: {
      //       from_secret: 'demo_kubernetes_server',
      //     },
      //     KUBERNETES_token: {
      //       from_secret: 'demo_kubernetes_token',
      //     },
      //   },
      // },
      fap.step.discord,
    ]
  ),
]
