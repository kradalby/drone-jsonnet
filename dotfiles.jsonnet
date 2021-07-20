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
        'apt install -y git curl tar xz-utils apt-transport-https wget ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip software-properties-common psmisc',

        // Add node
        'curl -sL https://deb.nodesource.com/setup_16.x | bash -',
        'curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -',
        'echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list',
        'apt update',
        'apt install -y nodejs yarn',
        'npm install --global zx',

        // Add go
        'add-apt-repository ppa:longsleep/golang-backports',
        'apt update',
        'apt install -y golang-go',

        // Add user
        'useradd -m ubuntu',
        'mkdir -p /home/ubuntu/git/dotfiles',
        'cp -r ./ /home/ubuntu/git/dotfiles/',

        // Install neovim
        'mkdir -p $HOME/local/nvim',
        'wget https://github.com/neovim/neovim/releases/download/v0.5.0/nvim-linux64.tar.gz -O nvim.tar.gz',
        'tar xzvf nvim.tar.gz --directory=$HOME/local/nvim --strip-components=1',

        // Install VS Code',
        // 'wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg',
        // 'install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/',
        // 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list',
        // 'apt update',
        // 'apt install -y libnotify4 libnss3 libxkbfile1 libsecret-1-0 libgtk-3-0 libxss1 libx11-xcb1 libasound2 libice6 libsm6 libxaw7 libxft2 libxmu6 libxpm4 libxt6 x11-apps xbitmaps',
        // 'apt install -y code',

        // Become user
        'su "ubuntu"',
        'cd ~',

        // VS Code
        // 'cat /drone/src/vscode.txt | xargs -L1 code --user-data-dir $HOME --install-extension',

        // Vim
        // 'curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim',
        // 'cp ~/git/dotfiles/rc/vimrc ~/.vimrc',
        // 'which yarn',
        // 'vim +"PlugInstall --sync" +qa > /dev/null',

        // Neovim
        'mkdir -p ~/.config',

        'mkdir -p $HOME/.local/share/nvim/lsp_servers/.zx',
        'cd $HOME/.local/share/nvim/lsp_servers/.zx; npm install zx; cd -',

        'cp -r ~/git/dotfiles/rcconfig/nvim ~/.config/nvim',
        '$HOME/local/nvim/bin/nvim --headless +"autocmd User PackerComplete sleep 100m | qall" +PackerSync',
        'sleep 30',
        '$HOME/local/nvim/bin/nvim --headless +"TSInstallSync maintained" +qa',
        '$HOME/local/nvim/bin/nvim +"LspInstall terraformls" &',
        'sleep 180',
        // 'killall nvim',
        '$HOME/local/nvim/bin/nvim --headless +"TSInstallSync maintained" +qa',
        '$HOME/local/nvim/bin/nvim +"LspInstall terraformls" &',
        'sleep 180',
        // 'killall nvim',
        '$HOME/local/nvim/bin/nvim --headless +"TSInstallSync maintained" +qa',
        '$HOME/local/nvim/bin/nvim +"LspInstall terraformls" &',
        'sleep 180',


        'mkdir -p $HOME/apps',
        'wget https://nightly.link/Kethku/neovide/workflows/build/main/neovide-windows.exe.zip -O $HOME/apps/neovide.exe.zip',
        'wget https://github.com/alacritty/alacritty/releases/download/v0.8.0/Alacritty-v0.8.0-portable.exe -O $HOME/apps/alacritty.exe',

        // Ship it
        'mkdir -p /drone/src/dist',
        'tar -cJf /drone/src/dist/dotfiles.tar.xz git',
        // 'tar -cJf /drone/src/dist/vim.tar.xz .vim',
        // 'tar -cJf /drone/src/dist/vscode_extensions.tar.xz .vscode/extensions',
        'tar -cJf /drone/src/dist/nvim.tar.xz .config/nvim .local/share/nvim local/nvim',
        'tar -cJf /drone/src/dist/terminal.tar.xz apps',
      ]),
      fap.step.deploy_scp(path='/fastest/serve/builds/dotfiles', host='core.terra.fap.no'),
      fap.step.discord,
    ]
  ),
]
