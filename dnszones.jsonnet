local drone = import 'drone.libsonnet';
local base = drone.base;
local fap = drone.fap;
local pipeline = base.pipeline;
local step = pipeline.step;

local env_secret_dict = {
  TF_VAR_vsphere_user: 'vsphere_user',
  TF_VAR_vsphere_password: 'vsphere_password',
  TF_VAR_vsphere_server: 'vsphere_server',
  CLOUDFLARE_EMAIL: 'cloudflare_email',
  CLOUDFLARE_API_KEY: 'cloudflare_token',
  AWS_ACCESS_KEY_ID: 'aws_access_key_id',
  AWS_SECRET_ACCESS_KEY: 'aws_secret_access_key',
  RANCHER_ACCESS_KEY: 'rancher_access_key',
  RANCHER_SECRET_KEY: 'rancher_secret_key',
};

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.terraform_lint,
      fap.step.terraform_plan(env=base.env_from_secret(env_secret_dict)),
      fap.step.terraform_apply(env=base.env_from_secret(env_secret_dict)),
      fap.step.discord,
    ],
  ),
  fap.secret.cloudflare.email,
  fap.secret.cloudflare.token,
  fap.secret.aws.access,
  fap.secret.aws.secret,
  fap.secret.discord.id,
  fap.secret.discord.token,
]
