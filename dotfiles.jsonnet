local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      pipeline.step.new('Build', 'ubuntu:latest')
      .withEnv({
        DEBIAN_FRONTEND: 'noninteractive',
        DISPLAY: ':9.0',
        HOME: '/home/ubuntu',
      })
      .withCommands([
        'pwd',
        'apt update',
        'apt install -y vim git curl tar xz-utils',
        'curl -sL https://deb.nodesource.com/setup_10.x | bash -',
        'apt install -y nodejs yarnpkg',

        // Install VS Code',
        'curl -o vscode.deb -J -L https://vscode-update.azurewebsites.net/latest/linux-deb-x64/stable',
        'apt install -y libnotify4 libnss3 libxkbfile1 libsecret-1-0 libgtk-3-0 libxss1 libx11-xcb1 libasound2 libice6 libsm6 libxaw7 libxft2 libxmu6 libxpm4 libxt6 x11-apps xbitmaps',
        'dpkg -i vscode.deb && rm -f vscode.deb',

        'useradd -m ubuntu',
        'mkdir -p /home/ubuntu/git/dotfiles',
        'cp -r ./ /home/ubuntu/git/dotfiles/',
        'su "ubuntu"',
        // 'export HOME=/home/ubuntu',
        // 'export DISPLAY=":9.0"',
        'cd ~',

        // Vim
        'curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim',
        'cp ~/git/dotfiles/rc/vimrc ~/.vimrc',
        'which yarn',
        'vim +"PlugInstall --sync" +qa > /dev/null',

        // VS Code
        'cat /drone/src/vscode.txt | xargs -L1 code --user-data-dir $HOME --install-extension',

        // Ship it
        'mkdir -p /drone/src/dist',
        'tar -cJf /drone/src/dist/dotfiles.tar.xz .vim git .vscode/extensions',
      ]),
      fap.step.deploy_builds('/storage/nfs/k8s/builds/dotfiles'),
      fap.step.discord,
    ]
  ),
  fap.secret.discord.id,
  fap.secret.discord.token,
  fap.secret.ssh.deploy,
]
