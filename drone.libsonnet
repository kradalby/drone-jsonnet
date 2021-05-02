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

local dnsConfig = { nameservers: ['1.1.1.1', '1.0.0.1'] };

local base = {
  platform(os, arch): {
    os: os,
    arch: arch,
  },
  platformToNodeSelector(platform): {
    'kubernetes.io/arch': platform.arch,
    'kubernetes.io/os': platform.os,
    drone: true,
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
    newKubernetes(
      name='Kubernetes',
      nodeSelector={ drone: true },
    ):: self.new().withType('kubernetes')
        .withName(name)
        .withNodeSelector(nodeSelector)
        // .withDnsConfig(dnsConfig)
        .withPlatform(base.platform('linux', 'amd64')),
    newMacOS(
      name='macOS'
    ):: self.new()
        .withType('exec')
        .withName(name)
        .withPlatform(base.platform('darwin', 'amd64')),
    newVmwarePacker(
      name='VMware Packer'
    ):: self.new()
        .withType('exec')
        .withName(name)
        .withPlatform(base.platform('linux', 'amd64'))
        .withNode({ packer: true, vmware: true }),
    withName(name):: self + { name: name },
    withKind(kind):: self + { kind: kind },
    withType(type):: self + { type: type },
    withPlatform(platform):: self + { platform: platform },
    withNode(n):: self + { node: n },
    withDependsOn(n):: self + { depends_on: n },
    withNodeSelector(ns):: self + { node_selector: ns },
    withDnsConfig(c):: self + { dns_config: c },
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
    'latest-${DRONE_STAGE_OS}-${DRONE_STAGE_ARCH}',
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
    github_pages_push: {
      username: base.secret.new(
        name='gh_username',
        path='gh-pages-push',
        key='username',
      ),
      token: base.secret.new(
        name='gh_token',
        path='gh-pages-push',
        key='token'
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

    go_test:
      step.new('Go test', 'golang:1.16-buster')
      .withCommands([
        'go test ./...',
      ]),

    go_build:
      step.new('Go build', 'golang:1.16-buster')
      .withCommands([
        'go get github.com/mitchellh/gox',
        'gox -osarch "!darwin/386" -output="dist/{{.Dir}}_{{.OS}}_{{.Arch}}"',
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
          'make build',
        ]
      ),

    swift_test(packages=[], image='swift:latest'):
      step.new('Swift test', image)
      .withCommands(
        (if packages != [] then
           [
             'apt update',
             'apt install -y %s' % std.join(' ', packages),
           ] else [])
        +
        [
          'make test',
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
          'make build-release',
          'mkdir -p dist/',
          'mv .build/release/%s dist/' % name,
        ]
      ),

    extract_from_container(name='', container_path='', image='kradalby/container-file-extractor:latest'):
      step.new('Extract from container', image)
      .withWhen(fap.when.master)
      .withCommands(
        [
          'container-file-extractor "%s" "%s" "%s"' % [name, '${DRONE_COMMIT_SHA:0:8}', container_path],
          'mkdir -p dist/',
          'mv output/%s/* dist/.' % container_path,
        ]
      ),

    deploy_scp(path='', host=''):
      step.new('Deploy with scp', 'appleboy/drone-scp')
      .withWhen(fap.when.master)
      .withEnv({
        SSH_KEY: {
          from_secret: 'ssh_key',
        },
      })
      .withSettings({
        host: host,
        rm: true,
        source: [
          'dist/*',
        ],
        strip_components: 1,
        target: path,
        username: 'deploy',
      }),

    deploy_rsync(
      path='',
      host='core.terra.fap.no',
      source='dist/',
      exclude=[],
      include=[],
      args=[]
    ):
      step.new('Deploy with rsync', 'drillster/drone-rsync')
      .withWhen(fap.when.master)
      .withSettings({
        hosts: [host],
        source: [
          source,
        ],
        target: path,
        include: include,
        exclude: exclude,
        args: std.join(' ', args),
        user: 'deploy',
        key: {
          from_secret: 'ssh_key',
        },
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
      .withSettings({
        repo: 'build-only',
        dry_run: true,
        purge: true,
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
        purge: true,
      }),

    docker_manifest(repo='', platforms=[]):
      step.new('Publish manifests %s' % repo, 'plugins/manifest')
      .withWhen(fap.when.master)
      .withSettings(dockerCommonSettings {
        template: '%s:latest-OS-ARCH' % repo,
        target: repo,
        platforms: platforms,
        ignore_missing: true,
      }),

    github_pages_publish(directory='dist'):
      step.new('Publish to GitHub Pages', 'plugins/gh-pages')
      .withWhen(fap.when.master)
      .withSettings({
        pages_directory: directory,
        username: {
          from_secret: 'github_pages_push_user',
        },
        password: {
          from_secret: 'github_pages_push_token',
        },
      }),

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

    terraform_lint:
      step.new('Lint', 'wata727/tflint')
      .withCommands([
        'tflint .',
      ]),


    tox:
      step.new('Python tox test', 'themattrix/tox:latest')
      .withCommands([
        'cp config.py.example config.py',
        'tox',
      ]),

    prettier_lint:
      step.new('Prettier lint', 'node:lts-buster')
      .withCommands([
        'npm install prettier',
        'echo .pre-commit-config.yaml >> .prettierignore',
        'npx prettier --check "**/*.{ts,js,md,yaml,yml,sass,css,scss}"',
      ]),

    elm_lint:
      step.new('Elm lint', 'node:lts-buster')
      .withCommands([
        'npm install elm-analyse elm-format',
        'npx elm-analyse',
        'npx elm-format --validate src/',
      ]),

    go_lint:
      step.new('Go lint', 'golang:1.16-buster')
      .withCommands([
        'curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin',
        'golangci-lint run -v --timeout 10m',
      ]),
    // step.new('Go lint', 'golangci/golangci-lint:latest')
    // .withCommands([
    //   'golangci-lint run -v --timeout 10m',
    // ]),

    swift_lint:
      step.new('Swift lint', 'swift:5.4-bionic')
      .withCommands([
        'git clone -b swift-5.4-branch https://github.com/apple/swift-format.git /tmp/swift-format',
        'cd /tmp/swift-format',
        'swift build --configuration release',
        'cd -',
        '/tmp/swift-format/.build/release/swift-format format --recursive  Sources/ Package.swift',
        '/tmp/swift-format/.build/release/swift-format lint --recursive  Sources/ Package.swift',
      ]),

    python_lint:
      step.new('Python lint', 'python:latest')
      .withCommands([
        'python -m pip install black',
        'python -m black --check',
      ]),

    super_lint:
      step.new('Super lint', 'github/super-linter:latest')
      .withEnv({
        RUN_LOCAL: 'true',
        DEFAULT_WORKSPACE: '/drone/src',
        ANSIBLE_DIRECTORY: '/drone/src',
      })
      .withCommands([
      ]),
  },
};

{
  base: base,
  fap: fap,
}
