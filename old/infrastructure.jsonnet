local drone = import 'drone.libsonnet';
local base = drone.base;
local fap = drone.fap;
local pipeline = base.pipeline;
local step = pipeline.step;

local env_secret_dict = {
  VSPHERE_USER: 'vsphere_user',
  VSPHERE_PASSWORD: 'vsphere_password',
  VSPHERE_SERVER: 'vsphere_server',
  CLOUDFLARE_EMAIL: 'cloudflare_email',
  CLOUDFLARE_API_KEY: 'cloudflare_token',
  AWS_ACCESS_KEY_ID: 'aws_access_key_id',
  AWS_SECRET_ACCESS_KEY: 'aws_secret_access_key',
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
  fap.secret.vsphere.server,
  fap.secret.vsphere.user,
  fap.secret.vsphere.password,
]
