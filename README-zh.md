中文 | [English](README.md)

# 简介

看了[webpro的文章](https://github.com/webpro/awesome-dotfiles)，发现了很多有用的点文件(dotfiles)。我觉得它们很棒，但我不想直接复制它们(我相信每个人的电脑配置都是独一无二的)。我想要一个适合我的配置文件。就像[mathiasbynens](https://github.com/mathiasbynens/dotfiles)一样。

> 正如[Joshua Clayton在最近一期《The Changelog》节目](http://thechangelog.com/post/17827235767/episode-0-7-3-tmux-with-brian-hogan-and-josh-clayton)中所说，归根结底，如果你觉得自己的配置文件不够完美，那你就做错了™。（顺便说一句，[他的配置文件](https://github.com/joshuaclayton/dotfiles/)非常出色。）从其他配置文件中挑选你喜欢的部分。保留有效的，舍弃无效的。打造你自己的光剑。充满信心地重新构建它。原文:https://wynnnetherland.com/journal/dotfiles-discovery

##### 如果不知道什么是dotfiles,你会觉得这篇[文章](https://jogendra.dev/i-do-dotfiles)会很有用

##### 如果你不想看,下面是一个简洁的解释:

> **Dotfiles（点文件）**指的是在 **类 Unix 系统**（如 macOS、Linux）中，以 **`.` 开头命名的配置文件**。
> 它们通常用来保存 **用户级别的程序配置**。
>
> 之所以叫 _dotfiles_，是因为文件名前面有一个 **点（dot）**。

> [!IMPORTANT]
>
> 在开始之前,我需要提醒一下,我的shell配置是基于`zsh`进行配置,如果你用其他的shell(比如bash, fish或者其他),我不确定能否成功,这里有个[仓库](https://github.com/mathiasbynens/dotfiles)会帮到你
>
> 如果你想更改默认shell (把`zsh`作为默认shell) ,通过[Google](google.com)一定能帮助到你

### [让每个程序只做好一件事](https://en.wikiquote.org/wiki/Doug_McIlroy)原则

我喜欢这个原则(我们都喜欢不是吗),所以在我的dotfiles中,不同的程序负责不同的事情,即使一个文件只写一行,比如:

- `tmux`负责终端复用
- `zsh`负责shell
- `neovim`负责nvim文本编辑
- `git`负责git

......

# zsh

> 在开始之前,请先阅读[zsh/bash的加载顺序](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)

> 结论：
>
> 对于 bash，将配置放在 ~/.bashrc 文件中，并让 ~/.bash_profile 文件执行它。
> 对于 zsh，将配置放在 ~/.zshrc 文件中，该文件始终会被执行。

###### 浅谈我的理解:

| 文件        | 启动顺序 | 何时加载                   | Shell 类型                                     | 每次启动都会执行吗     | 典型用途                                    |
| ----------- | -------- | -------------------------- | ---------------------------------------------- | ---------------------- | ------------------------------------------- |
| `.zshenv`   | 1        | **所有 zsh 启动时**        | login / interactive / non-interactive / script | ✅ 是                  | 基础环境变量（`PATH`、`LANG`、`EDITOR` 等） |
| `.zprofile` | 2        | **login shell 启动时**     | login shell                                    | ❌ 否（只在 login 时） | 登录初始化、`brew shellenv`、PATH 初始化    |
| `.zshrc`    | 3        | **交互 shell 启动时**      | interactive shell                              | ❌ 否（仅交互 shell）  | alias、prompt、plugin、completion           |
| `.zlogin`   | 4        | **login shell 启动完成后** | login shell                                    | ❌ 否（只在 login 时） | 登录后任务、欢迎信息、启动程序              |

我使用[`ohmyzsh`](https://github.com/ohmyzsh/ohmyzsh)来管理我的zsh配置,它是一个开源的、社区驱动的框架,可以帮助你轻松地管理你的zsh配置文件,并且提供了很多有用的插件和主题.

我使用过两个主题,[`powerlevel10k`](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#powerlevel10k),和[`starship`](https://github.com/starship/starship)

> [!CAUTION]
>
> 我不知道你是喜欢`p10k`还是`starship`,所以我把两个都放上来,然而,我使用的starship,所以你会看到我仓库有个[`p10k`](./p10k/)文件夹,如果你不需要p10k,你可以删除它,同样的,如果你需要p10k,你可以删除starship的配置文件,只不过需要把p10k的配置文件移动并替换到`./zsh`中.

## [powerlevel10k(p10k)](./p10k/)

基于 [Powerlevel10k](https://github.com/romkatv/powerlevel10k) 的 Zsh 提示符配置，风格为 Rainbow + Powerline，需要 [Nerd Font](https://www.nerdfonts.com/)。

- 左侧显示：当前目录、Git 状态
- 右侧显示：命令退出码、执行耗时、语言版本（Node/Python/Ruby 等）、K8s / 云平台上下文、当前时间
- 启用 instant prompt（零延迟启动）与 transient prompt（历史命令简洁化）
- `zshrc.d/` 中采用模块化配置，便于维护

![68991B896A7E070B52E1C9364463BD49](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/68991B896A7E070B52E1C9364463BD49.png)

如果你觉得我的样式不好看,你可以在终端输入: `p10k configure`来重新配置,如果字体没有下载的话,配置会显示出错

> 如果你是Windows用户,这篇[文章](https://dev.to/equiman/zsh-on-windows-without-wsl-4ah9)会详细讲解这个内容

## starship

![CleanShot 2026-03-12 at 10.43.32@2x](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/CleanShot%202026-03-12%20at%2010.43.32%402x.png)

基于 [Starship](https://github.com/starship/starship) 的 Zsh 提示符配置，支持多种语言和工具的集成。如果当前的目录是一个 Git 仓库，提示符会显示 Git 分支和状态信息；如果当前目录包含 Node.js 项目，则显示 Node.js 版本；如果当前目录包含 Python 项目，则显示 Python 版本,需要注意的是,你需要激活python环境才能显示。

![CleanShot 2026-03-12 at 10.46.26@2x](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/CleanShot%202026-03-12%20at%2010.46.26%402x.png)

### starship.toml

这个文件需要放到`~/.config`里

```bash
ln -s ~/dotfiles/starship/starship.toml ~/.config/starship.toml
```

这是starship的配置文件,你可以根据自己的需要进行修改,这个文件的格式是TOML格式,你可以在[这里](https://starship.rs/config/)找到更多关于starship配置的信息.

# git

##### gitconfig

- gitconfig文件包含了git的全局配置,比如用户名,邮箱等

- 想知道这个配置项有什么,工作的原理是什么,请看这篇[文章](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)

- 这里面的内容**不可以**直接使用,你需要进行一些配置

这里需要注意的是,邮箱地址如果写入配置中,会暴露你的邮箱地址,但是[GitHub](https://github.com)会隐藏你的邮箱地址,具体请看这篇[文章](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address),你可以在GitHub开启`Keep my email addresses private`,github会为你生成一个`noreply`的邮箱地址,但命令行 Git 不会自动使用它,你可以把这个邮箱地址写入gitconfig中,这样就不会暴露你的真实邮箱地址了.

如果你喜欢使用真实邮箱在本地, 你可以拆分配置,新建一个例如`.gitconfig.local`的文件来存储个人信息

##### gitignore_global

gitignore_global文件包含了全局的git忽略规则,比如node_modules等,你可以根据自己的需要进行修改,这个文件的路径需要和gitconfig中的配置一致,否则git不会使用这个文件中的规则.

如果你觉得不好,也可以删除,并在每个项目中添加`.gitignore`文件,来指定项目的忽略规则,这样可以更灵活的管理不同项目的忽略规则.

# tmux

我的tmux配置是基于[oh-my-tmux](https://github.com/gpakosz/.tmux)
自动安装这个配置如下:

```bash
curl -fsSL "https://github.com/gpakosz/.tmux/raw/refs/heads/master/install.sh#$(date +%s)" | bash
```

# nvim

基于[nvchad](https://nvchad.com/)的nvim配置,添加了:

1. 一些类似vs code的快捷键(nvim/lua/mappings.lua)
2. 在终端只使用`nvim`这个命令打开nvim的时候(没有加上文件名),打开一个默认目录,而不是一个空的nvim界面(nvim/lua/autocmds.lua)

> 请你修改默认目录在`nvim/lua/autocmds.lua`中,否则会报错没有这个目录

如果还没有nvim,你可以使用下面的命令来安装(macOS):

```bash
brew install nvim
```

或者在[官网](https://neovim.io/)下载

# Brewfile

它包含了使用brew安装的[Homebrew](https://github.com/Homebrew/brew)包,请你先使用文本编辑器查看这个文件里面的东西,并按需修改,这个文件的格式是Homebrew的Brewfile格式,你可以在[这里](https://github.com/Homebrew/brew/blob/master/Library/Homebrew/brew.rb)找到更多关于Brewfile的信息.

最后,你可以使用下面这个命令来安装:

```bash
brew bundle --file=./Brewfile
```

### 关于 `appdir`参数

`appdir`参数是Homebrew的Brewfile中的一个选项,它指定了安装的应用程序的目录,默认情况下,Homebrew会把应用程序安装到`/Applications`目录下,但是如果你想把应用程序安装到其他目录下,你可以使用这个参数来指定目录,比如:

```sh
brew install --cask devtoys --appdir="~/Applications"
```

#### 为什么我使用了`appdir`参数?

在Macos系统中,第一个用户账户始终是管理员账户。管理员账户属于 admin 组，并拥有 sudo 权限，它可以篡夺其他账户（尤其是 root），从而对系统具有实际控制权。管理员执行的任何程序都可能获得同等权限，因此存在安全风险。

像 sudo 这样的工具存在可被并发运行程序利用的[弱点](https://bogner.sh/2014/03/another-mac-os-x-sudo-password-bypass/)。

[Apple](https://help.apple.com/machelp/mac/10.12/index.html#/mh11389) 认为的最佳实践是：日常工作使用单独的标准账户，安装与系统配置使用管理员账户。

并不要求一定要通过 macOS 登录界面登录管理员账户。当终端命令需要管理员权限时，系统会提示认证，随后终端会继续使用这些权限。为此，Apple 提供了隐藏管理员账户及其主目录的[建议](https://support.apple.com/HT203998)。这是一种优雅的方案，可避免出现可见的“幽灵”账户。

> 引用自https://github.com/drduh/macOS-Security-and-Privacy-Guide
>
> [中文](https://github.com/genwilliam/macOS-Security-and-Privacy-Guide-cn)

> 如果你不想每次下载一个cask程序都使用这个参数,你可以Google到你需要的东西

# bin

bin文件夹包含了一些自定义的命令,你可以根据自己的需要进行修改,这个文件夹需要添加到你的PATH环境变量中,这样你就可以在终端中直接使用这些命令了.

# macos

macos文件夹包含了一些macOS的配置,比如系统偏好设置等,你可以根据自己的需要进行修改,这个文件夹中的脚本需要使用`chmod +x`命令来赋予执行权限,然后你就可以在终端中直接运行这些脚本了.

macos可以使用 `defaults` 命令来修改系统偏好设置,你可以在[这里](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaFundamentals/AddingBehaviortoaCocoaProgram/AddingBehavior.html)找到更多关于`defaults`命令的信息.

# install.sh

这是一键下载完成以下工作的命令:

- 安装Homebrew
- 安装Brewfile中的程序
- 安装ohmyzsh
- 安装p10k或者starship(默认)
- 安装zsh插件
