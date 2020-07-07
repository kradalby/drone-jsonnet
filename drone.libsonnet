local droneStatus = ['success', 'failure'];
local MACOS_PATH = [
  '/usr/local/opt/coreutils/libexec/gnubin',
  '/usr/local/opt/ruby/bin',
  '/usr/local/opt/gnu-tar/libexec/gnubin',
  '/usr/local/opt/gnu-sed/bin',
  '/usr/local/bin',
  '/usr/bin',
  '/bin',
  '/usr/sbin',
  '/sbin',
  '/usr/local/share/dotnet',
];

local base = {
  platform(os, arch): {
    os: os,
    arch: arch,
  },
  env_from_secret(dict): {
    [key]: {
      from_secret: dict[key],
    }
    for key in std.objectFields(dict)
  },
  secret:: {
    new(
      name='',
      path='',
      key=''
    ): {
      kind: 'secret',
      name: name,
      get: {
        path: path,
        name: key,
      },
    },
  },
  pipeline:: {
    new():: self.withKind('pipeline'),
    newKubernetes(name='Kubernetes', nodeSelector={ drone: true },):: self.new().withType('kubernetes').withName(name).withNodeSelector(nodeSelector),
    newMacOS(name='macOS'):: self.new().withType('exec').withName(name).withPlatform(base.platform('darwin', 'amd64')),
    newVmwarePacker(name='VMware Packer'):: self.new().withType('exec').withName(name).withPlatform(base.platform('linux', 'amd64')).withNode({ packer: true, vmware: true }),
    withName(name):: self + { name: name },
    withKind(kind):: self + { kind: kind },
    withType(type):: self + { type: type },
    withPlatform(platform):: self + { platform: platform },
    withNode(n):: self + { node: n },
    withNodeSelector(ns):: self + { node_selector: ns },
    withSteps(steps):: self + if std.type(steps) == 'array' then { steps: steps } else { steps: [steps] },
    step:: {
      new(name='', image=''):: self.withName(name).withImage(image).withAlwaysPull(),
      withName(name):: self + { name: name },
      withImage(image):: self + if image != '' then { image: image } else {},
      withAlwaysPull():: self + { pull: 'always' },
      withCommands(commands):: self + if std.type(commands) == 'array' then { commands: commands } else { commands: [commands] },
      withTrigger(trigger):: self + { trigger: trigger },
      withEnv(envs):: self + { environment: envs },
      withWhen(when):: self + { when: when },
      withSettings(settings):: self + { settings: settings },
    },
    trigger:: {
      new():: self + {},
      withBranch(branch):: self + if std.type(branch) == 'array' then { branch: branch } else { branch: [branch] },
      withEvent(e):: self + if std.type(e) == 'array' then { event: e } else { event: [e] },
      withStatus(s):: self + if std.type(s) == 'array' then { status: s } else { status: [s] },
      withStatusAll():: self.withStatus(droneStatus),
    },
    when:: {
      new():: self + {},
      withBranch(branch):: self + if std.type(branch) == 'array' then { branch: branch } else { branch: [branch] },
      withEvent(e):: self + if std.type(e) == 'array' then { event: e } else { event: [e] },
      withStatus(s):: self + if std.type(s) == 'array' then { status: s } else { status: [s] },
      withStatusAll():: self.withStatus(droneStatus),
    },
  },
};

local pipeline = base.pipeline;
local step = pipeline.step;

local dockerCommonSettings = {
  tags: [
    'latest',
    '${DRONE_COMMIT_SHA:0:8}',
  ],
  username: {
    from_secret: 'docker_username',
  },
  password: {
    from_secret: 'docker_password',
  },
};

local fap = {
  secret:: {
    cloudflare: {
      email: base.secret.new(
        name='cloudflare_email',
        path='cloudflare',
        key='email'
      ),
      token: base.secret.new(
        name='cloudflare_token',
        path='cloudflare',
        key='token'
      ),
    },
    aws: {
      access: base.secret.new(
        name='aws_access_key_id',
        path='aws',
        key='access_key_id'
      ),
      secret: base.secret.new(
        name='aws_secret_access_key',
        path='aws',
        key='secret_access_key'
      ),
    },
    discord: {
      id: base.secret.new(
        name='discord_webhook_id',
        path='discord-build',
        key='id'
      ),
      token: base.secret.new(
        name='discord_webhook_token',
        path='discord-build',
        key='token'
      ),
    },
    ssh: {
      deploy: base.secret.new(
        name='ssh_key',
        path='ssh',
        key='deploy'
      ),
      database: base.secret.new(
        name='ssh_key_database',
        path='ssh',
        key='database'
      ),
      database_known_host: base.secret.new(
        name='ssh_known_hosts_database',
        path='ssh',
        key='database_known_host'
      ),
    },
    docker: {
      username: base.secret.new(
        name='docker_username',
        path='docker',
        key='username',
      ),
      password: base.secret.new(
        name='docker_password',
        path='docker',
        key='password'
      ),
    },
    vsphere: {
      server: base.secret.new(
        name='vsphere_server',
        path='vcenter',
        key='host',
      ),
      user: base.secret.new(
        name='vsphere_user',
        path='vcenter',
        key='login',
      ),
      password: base.secret.new(
        name='vsphere_password',
        path='vcenter',
        key='password'
      ),
    },
  },
  trigger:: {
    local t = pipeline.trigger,
    master: t.withBranch('master').withEvent('push'),
    pr: t.withEvent('pull_request'),
  },
  when:: {
    local w = pipeline.when,
    master: w.withBranch('master').withEvent('push'),
    exclude: w.new() + { branch: { exclude: ['master'] } },
  },
  variables:: {
    path: {
      macos: std.join(':', MACOS_PATH),
    },
  },
  step:: {
    discord:
      step.new('Notify Discord', 'appleboy/drone-discord')
      .withWhen(pipeline.when.withStatusAll())
      .withSettings({
        webhook_id: {
          from_secret: 'discord_webhook_id',
        },
        webhook_token: {
          from_secret: 'discord_webhook_token',
        },
        message: |||
          {{#success build.status}}
          ✅  Build #{{build.number}} of `{{repo.name}}` succeeded.

          📝  Commit by {{commit.author}} on `{{commit.branch}}`:
          ``` {{commit.message}} ```
          🌐  {{ build.link }}

          ✅  duration: {{duration build.started build.finished}}
          ✅  started: {{datetime build.started "2006/01/02 15:04" "UTC"}}
          ✅  finished: {{datetime build.finished "2006/01/02 15:04" "UTC"}}

          {{else}}
          @everyone
          ❌  Build #{{build.number}} of `{{repo.name}}` failed.

          📝  Commit by {{commit.author}} on `{{commit.branch}}`:
          ``` {{commit.message}} ```
          🌐  {{ build.link }}

          ✅  duration: {{duration build.started build.finished}}
          ✅  started: {{datetime build.started "2006/01/02 15:04" "UTC"}}
          ✅  finished: {{datetime build.finished "2006/01/02 15:04" "UTC"}}

          {{/success}}
        |||,
      }),

    email:
      step.new('Email', 'drillster/drone-email')
      .withWhen(pipeline.when.withStatusAll())
      .withSettings({
        from: 'drone@drone.fap.no',
        host: 'smtp.fap.no',
        port: 25,
        skip_verify: true,
      }),

    gox:
      step.new('Go build', 'golang:1.14.4-stretch')
      .withCommands([
        'go get github.com/mitchellh/gox',
        'gox -output="dist/{{.Dir}}_{{.OS}}_{{.Arch}}"',
      ]),

    golint:
      step.new('Go lint', 'golangci/golangci-lint:latest')
      .withCommands([
        'golangci-lint run -v --timeout 10m',
      ]),

    swift_build(packages=[], image='swift:latest'):
      step.new('Swift build', image)
      .withCommands(
        (if packages != [] then
           [
             'apt update',
             'apt install -y %s' % std.join(' ', packages),
           ] else [])
        +
        [
          'make test',
          'make build',
        ]
      ),

    swift_release(packages=[], name='', image='swift:latest'):
      step.new('Swift release', image)
      .withWhen(fap.when.master)
      .withCommands(
        (if packages != [] then
           [
             'apt update',
             'apt install -y %s' % std.join(' ', packages),
           ] else [])
        +
        [
          'make test',
          'make build-release',
          'mkdir -p dist/',
          'mv .build/release/%s dist/' % name,
        ]
      ),

    deploy_builds(path=''):
      step.new('Deploy to builds', 'appleboy/drone-scp')
      .withWhen(fap.when.master)
      .withEnv({
        SSH_KEY: {
          from_secret: 'ssh_key',
        },
      })
      .withSettings({
        host: 'storage.terra.fap.no',
        rm: true,
        source: [
          'dist/*',
        ],
        strip_components: 1,
        target: path,
        username: 'deploy',
      }),

    deploy_kubernetes(name='', repo=''):
      step.new('Deploy %s to Kubernetes' % name, 'kradalby/drone-kubectl')
      .withWhen(fap.when.master)
      .withEnv({
        APP: name,
        REPO: if repo != '' then repo else 'kradalby/%s' % name,
        KUBERNETES_CERT: {
          from_secret: 'kubernetes_cert',
        },
        KUBERNETES_SERVER: {
          from_secret: 'kubernetes_server',
        },
        KUBERNETES_TOKEN: {
          from_secret: 'kubernetes_token',
        },
      })
      .withCommands([
        'kubectl -n $APP set image deployment/$APP $APP=$REPO:${DRONE_COMMIT_SHA:0:8} --record',
        'kubectl -n $APP rollout status deployment $APP',
      ]),

    node_lint:
      step.new('Node lint', 'node:10')
      .withCommands([
        'make install',
        'make lint',
      ]),

    kaniko_build:
      step.new('Build container image', 'banzaicloud/drone-kaniko:0.5.1')
      .withTrigger(fap.trigger.pr)
      .withWhen(fap.when.exclude),

    kaniko_publish(repo=''):
      step.new('Publish image %s' % repo, 'banzaicloud/drone-kaniko:0.5.1')
      .withWhen(fap.when.master)
      .withSettings(dockerCommonSettings {
        repo: repo,
      }),

    docker_build:
      step.new('Build container image', 'plugins/docker')
      .withEnv({
        DOCKER_BUILDKIT: 1,
      })
      .withTrigger(fap.trigger.pr)
      .withWhen(fap.when.exclude),

    docker_publish(repo=''):
      step.new('Publish image %s' % repo, 'plugins/docker')
      .withWhen(fap.when.master)
      .withEnv({
        DOCKER_BUILDKIT: 1,
      })
      .withSettings(dockerCommonSettings {
        repo: repo,
      }),

    github_pages_publish(directory=''):
      step.new('Publish to GitHub Pages', 'plugins/gh-pages')
      .withWhen(fap.when.master)
      .withSettings({
        pages_directory: directory,
      }),

    terraform_lint:
      step.new('Lint', 'wata727/tflint')
      .withCommands([
        'tflint .',
      ]),

    terraform_plan(env={}):
      step.new('Plan', 'hashicorp/terraform:light')
      .withEnv(env)
      .withCommands([
        'terraform version',
        'terraform init',
        'terraform validate',
        'terraform plan',
      ]),

    terraform_apply(env={}):
      step.new('Apply', 'hashicorp/terraform:light')
      .withEnv(env)
      .withCommands([
        'terraform init',
        'terraform apply -auto-approve',
      ]),

    tox:
      step.new('Python tox test', 'themattrix/tox:latest')
      .withCommands([
        'cp config.py.example config.py',
        'tox',
      ]),
  },
};

{
  base: base,
  fap: fap,
}
