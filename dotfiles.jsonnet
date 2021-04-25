local drone = import 'drone.libsonnet';
local base = drone.base;
local pipeline = base.pipeline;
local fap = drone.fap;

[
  pipeline.newKubernetes(
  ).withSteps(
    [
      fap.step.prettier_lint,
      pipeline.step.new('Build', 'ubuntu:latest')
      .withEnv({
        DEBIAN_FRONTEND: 'noninteractive',
        DISPLAY: ':9.0',
        HOME: '/home/ubuntu',
      })
      .withCommands([
        'pwd',
        'echo $PATH',
        'apt update',
        'apt install -y neovim git curl tar xz-utils apt-transport-https wget',
        'curl -sL https://deb.nodesource.com/setup_10.x | bash -',
        'curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -',
        'echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list',
        'apt update',
        'apt install -y nodejs yarn',

        // Install VS Code',
        'wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg',
        'install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/',
        'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list',
        'apt update',
        'apt install -y libnotify4 libnss3 libxkbfile1 libsecret-1-0 libgtk-3-0 libxss1 libx11-xcb1 libasound2 libice6 libsm6 libxaw7 libxft2 libxmu6 libxpm4 libxt6 x11-apps xbitmaps',
        'apt install -y code',

        'useradd -m ubuntu',
        'mkdir -p /home/ubuntu/git/dotfiles',
        'cp -r ./ /home/ubuntu/git/dotfiles/',
        'su "ubuntu"',
        // 'export HOME=/home/ubuntu',
        // 'export DISPLAY=":9.0"',
        'cd ~',

        // VS Code
        'cat /drone/src/vscode.txt | xargs -L1 code --user-data-dir $HOME --install-extension',

        // Vim
        // 'curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim',
        // 'cp ~/git/dotfiles/rc/vimrc ~/.vimrc',
        // 'which yarn',
        // 'vim +"PlugInstall --sync" +qa > /dev/null',

        // Neovim
        'sh -c \'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim\'',
        'mkdir -p ~/.config/nvim',
        'cp ~/git/dotfiles/rc/vimrc ~/.config/nvim/init.vim',
        'nvim --headless +"PlugInstall --sync" +qa',


        // Ship it
        'mkdir -p /drone/src/dist',
        'tar -cJf /drone/src/dist/dotfiles.tar.xz git',
        'tar -cJf /drone/src/dist/vim.tar.xz .vim',
        'tar -cJf /drone/src/dist/vscode_extensions.tar.xz .vscode/extensions',
      ]),
      fap.step.deploy_scp(path='/fastest/serve/builds/dotfiles', host='core.terra.fap.no'),
      fap.step.discord,
    ]
  ),
]
