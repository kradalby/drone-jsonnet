local drone = import 'drone.libsonnet';
local base = drone.base;
local fap = drone.fap;
local pipeline = base.pipeline;
local step = pipeline.step;

local env_secret_dict = {
  SSH_KEY: 'ssh_key_database',
  SSH_KNOWN_HOSTS: 'ssh_known_hosts_database',
  AWS_ACCESS_KEY_ID: 'aws_access_key_id',
  AWS_SECRET_ACCESS_KEY: 'aws_secret_access_key',
  TF_VAR_aspargesgaarden_db_password: 'aspargesgaarden_db_password',
  TF_VAR_bork_db_password: 'bork_db_password',
  TF_VAR_dex_db_password: 'dex_db_password',
  TF_VAR_drone_db_password: 'drone_db_password',
  TF_VAR_lan_recess_no_db_password: 'lan_recess_no_db_password',
  TF_VAR_nextcloud_db_password: 'nextcloud_db_password',
  TF_VAR_nextcloud2020_db_password: 'nextcloud2020_db_password',
  TF_VAR_p0sx_pp25_db_password: 'p0sx_pp25_db_password',
  TF_VAR_p0sx_pp26_db_password: 'p0sx_pp26_db_password',
  TF_VAR_p0sx_pp27_db_password: 'p0sx_pp27_db_password',
  TF_VAR_p0sx_pp28_db_password: 'p0sx_pp28_db_password',
  TF_VAR_provider_db_password: 'provider_db_password',
  TF_VAR_sourceapi_db_password: 'sourceapi_db_password',
  TF_VAR_studlan_db_password: 'studlan_db_password',
  TF_VAR_trondelan_db_password: 'trondelan_db_password',
  TF_VAR_turbo_enigma_db_password: 'turbo_enigma_db_password',
  TF_VAR_smstore_db_password: 'smstore_db_password',
};

local sshSetup = [
  'mkdir -p ~/.ssh',
  'echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts',
  'echo -n "$SSH_KEY" > ~/.ssh/id_ed25519',
  'cat ~/.ssh/id_ed25519',
  'cat ~/.ssh/known_hosts',
  'chmod 700 ~/.ssh/id_ed25519',
  'ssh -Nf -L 127.0.0.1:5433:/var/run/postgresql/.s.PGSQL.5432 postgres@database.terra.fap.no',
];

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.terraform_lint,
      fap.step.terraform_plan(env=base.env_from_secret(env_secret_dict)) {
        commands: sshSetup + super.commands,
      },
      fap.step.terraform_apply(env=base.env_from_secret(env_secret_dict)) {
        commands: sshSetup + super.commands,
      },
      fap.step.discord,
    ],
  ),
  fap.secret.cloudflare.email,
  fap.secret.cloudflare.token,
  fap.secret.aws.access,
  fap.secret.aws.secret,
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.ssh.database,
  fap.secret.ssh.database_known_host,
]
