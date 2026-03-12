# Introduction

After reading [webpro's article](https://github.com/webpro/awesome-dotfiles), I discovered many useful dotfiles. I think they are great, but I don't want to copy them directly (I believe everyone's computer setup is unique). I want a configuration that fits me, just like [mathiasbynens](https://github.com/mathiasbynens/dotfiles).

> As [Joshua Clayton said in a recent episode of The Changelog](http://thechangelog.com/post/17827235767/episode-0-7-3-tmux-with-brian-hogan-and-josh-clayton), if you're unhappy with your dotfiles, you're doing it wrong™. Pick and choose what you like from other people's dotfiles. Learn from everyone, follow no one. Build your own lightsaber. Rebuild it from scratch with confidence. Original: https://wynnnetherland.com/journal/dotfiles-discovery

##### If you don't know what dotfiles are, this [article](https://jogendra.dev/i-do-dotfiles) is helpful.

##### If you don't want to read it, here's a short explanation:

> **Dotfiles** are configuration files in **Unix-like systems** (such as macOS and Linux) whose names start with **`.`**.
> They are usually used to store **user-level application settings**.
>
> They are called _dotfiles_ because each filename starts with a **dot**.

> [!IMPORTANT]
>
> Before you start, I need to mention that my shell setup is based on `zsh`.
> If you use another shell (such as bash, fish, or others), I cannot guarantee this setup will work.
> This [repository](https://github.com/mathiasbynens/dotfiles) may help you.
>
> If you want to change your default shell (set `zsh` as default), searching on [Google](google.com) should help.

### The principle: [Do one thing and do it well](https://en.wikiquote.org/wiki/Doug_McIlroy)

I like this principle (we all do, right?). So in my dotfiles, different tools do different jobs, even if a file only has one line, for example:

- `tmux` handles terminal multiplexing
- `zsh` handles the shell
- `neovim` handles text editing
- `git` handles version control

...

# zsh

I use [`ohmyzsh`](https://github.com/ohmyzsh/ohmyzsh) to manage my zsh configuration. It's an open-source, community-driven framework that makes zsh config easier and provides many useful plugins and themes.

I've used two themes: [`powerlevel10k`](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes#powerlevel10k) and [`starship`](https://github.com/starship/starship).

> [!CAUTION]
>
> I don't know whether you prefer `p10k` or `starship`, so I include both.
> However, I currently use starship, so you will see a [`p10k`](./p10k/) folder in this repo.
> If you don't need p10k, you can delete it.
> Likewise, if you need p10k, you can delete the starship config, then move and replace the files from `./p10k` into `./zsh`.

## [powerlevel10k (p10k)](./p10k/)

A Zsh prompt configuration based on [Powerlevel10k](https://github.com/romkatv/powerlevel10k), using a Rainbow + Powerline style, and requiring [Nerd Font](https://www.nerdfonts.com/).

- Left side shows: current directory and Git status
- Right side shows: command exit code, execution time, language versions (Node/Python/Ruby, etc.), K8s/cloud context, and current time
- Enables instant prompt (near-zero startup delay) and transient prompt (simplified previous prompt lines)
- Uses modular config in `zshrc.d/` for easier maintenance

![68991B896A7E070B52E1C9364463BD49](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/68991B896A7E070B52E1C9364463BD49.png)

If you don't like my style, run `p10k configure` in your terminal to reconfigure it. If fonts are missing, the configuration wizard may display incorrectly.

> If you are a Windows user, this [article](https://dev.to/equiman/zsh-on-windows-without-wsl-4ah9) explains it in detail.

## starship

![CleanShot 2026-03-12 at 10.43.32@2x](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/CleanShot%202026-03-12%20at%2010.43.32%402x.png)

A Zsh prompt configuration based on [Starship](https://github.com/starship/starship), with integration for multiple languages and tools.
If the current directory is a Git repository, the prompt shows branch and status.
If the current directory contains a Node.js project, it shows the Node.js version.
If it contains a Python project, it shows the Python version.
Note that for Python version display, you need to activate a Python environment.

![CleanShot 2026-03-12 at 10.46.26@2x](https://raw.githubusercontent.com/genwilliam/picgo_img/main/img/CleanShot%202026-03-12%20at%2010.46.26%402x.png)

### starship.toml

This file needs to be placed in `~/.config`.

```bash
ln -s ~/dotfiles/starship/starship.toml ~/.config/starship.toml
```

This is the Starship configuration file. You can modify it based on your needs.
The format is TOML. You can find more details [here](https://starship.rs/config/).

# git

##### gitconfig

- `gitconfig` contains global Git settings, such as username and email.

- If you want to know what each option means and how it works, see this [article](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration).

- The content here should **not** be used directly; you need to customize it.

One important note: if your email is written directly in config, it may expose your address.
But [GitHub](https://github.com) can hide your email address. See this [article](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address).
You can enable `Keep my email addresses private` in GitHub to get a `noreply` email address.
CLI Git will not use it automatically, but you can put that address in `gitconfig` to avoid exposing your real email.

If you prefer to use your real email locally, you can split your config and create a file such as `.gitconfig.local` to store personal info.

##### gitignore_global

`gitignore_global` contains global Git ignore rules (such as `node_modules`).
You can modify it as needed.
Its path must match the setting in `gitconfig`; otherwise Git won't load these rules.

If you don't like this approach, you can remove it and add a `.gitignore` file in each project instead, which gives more flexible per-project control.

# Brewfile

It contains [Homebrew](https://github.com/Homebrew/brew) packages installed via brew.
Please inspect this file with a text editor first and adjust it to your needs.
It uses Brewfile format. You can find more details [here](https://github.com/Homebrew/brew/blob/master/Library/Homebrew/brew.rb).

Then install with:

```bash
brew bundle --file=./Brewfile
```

### About the `appdir` parameter

`appdir` is an option in Homebrew Brewfile. It specifies where cask apps are installed.
By default, Homebrew installs apps into `/Applications`.
If you want another directory, you can set this parameter, for example:

```sh
brew install --cask devtoys --appdir="~/Applications"
```

#### Why do I use `appdir`?

On macOS, the first user account is always an administrator account.
Administrator accounts belong to the `admin` group and have sudo privileges.
This means they can effectively control the system, including privileged operations, which increases risk.

Tools like `sudo` can have [weaknesses](https://bogner.sh/2014/03/another-mac-os-x-sudo-password-bypass/) that may be exploited by concurrently running programs.

[Apple](https://help.apple.com/machelp/mac/10.12/index.html#/mh11389) recommends this best practice:
use a separate standard account for daily work, and use an administrator account only for installation and system configuration.

You don't have to log in through the macOS login screen as the admin account all the time.
When terminal commands require admin privileges, the system prompts for authentication, then the terminal continues with those privileges.
For this, Apple provides guidance on hiding the admin account and its home directory [here](https://support.apple.com/HT203998).
It's an elegant approach to avoid having a visible “ghost” account.

> Quoted from https://github.com/drduh/macOS-Security-and-Privacy-Guide
>
> [Chinese translation](https://github.com/genwilliam/macOS-Security-and-Privacy-Guide-cn)

> If you don't want to pass this parameter every time you install a cask app, you can search online for alternatives.

# bin

The `bin` folder contains custom commands/scripts. You can modify them as needed.
This folder should be added to your `PATH` environment variable so you can run commands directly in terminal.

# macos

The `macos` folder contains macOS configuration scripts (for example, system preference settings).
You can modify them as needed.
Scripts in this folder should be made executable with `chmod +x`, then run directly in terminal.

The `macos` scripts can use the `defaults` command to modify system preferences.
You can read more about `defaults` [here](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaFundamentals/AddingBehaviortoaCocoaProgram/AddingBehavior.html).

# install.sh

This one-shot script does the following:

- Installs Homebrew
- Installs apps/packages from Brewfile
- Installs oh-my-zsh
- Installs p10k or starship (starship by default)
- Installs zsh plugins
