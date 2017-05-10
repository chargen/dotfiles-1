# dotfiles

## Installation

```bash
git clone https://github.com/reaperhulk/dotfiles.git && cd dotfiles && ./install_dotfiles.sh
```

There is a secondary script `macos_defaults.sh` that will set up many of the defaults I prefer...

Finally, there is a Brewfile that can be executed via `brew bundle`.


This will create symlinks, not copy. You can then update with a fresh git pull at any time.

You will need to separately install vundle and then run `:PluginInstall` before vim will
work properly.

##Requirements
Assumes the presence of the following from brew (or other sources):
* ag
* pyenv
* pyenv-virtualenvwrapper
