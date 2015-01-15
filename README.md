dotfiles
========

This is my OSX environment. Check out the `linux` branch for the linux version.


Install
-------

1. Run

  ```sh
  cd ~
  git clone https://github.com/wmayner/dotfiles.git ~/dotfiles
  cd ~/dotfiles
  rake install
  ```

  Don't forget to follow the prompts and back everything up!

2. Install the external dependencies:
  * [spf13-vim][1]
  * [oh-my-zsh][2]
  * [Powerline][4]

4. In the `.zshrc`, set `DOTFILES=~/path/to/this/repo>`. I just use `~/dotfiles`.

Then you should be all set. Some files you'll want to personalize right away:

- `zsh/zshrc.symlink` and `globalenv.symlink`: set up your own path variables
- `aliases.symlink`: create your own aliases
- `git/gitconfig.symlink`: commit as yourself


Components
----------

All `*.symlink` files get symlinked into your `$HOME` when you run `rake
install`. This is so you can keep everything versioned in the repo.

### Shell ###

* I use `zsh` (rather than `bash`), with [oh-my-zsh][2].

* Every `*.zsh` file gets sourced into `zsh`. The idea is to split `zsh`
  configuration into separate files and categories, rather than having a
  monolithic `.zshrc`.

* The prompt is supplied by [Powerline][4] (I just use the default theme).

* Aliases are defined in `aliases.symlink`.

* I use iTerm2 rather than the native OSX terminal; it's more customizable:

  - The colorscheme is Solarized, the same one used in Vim by spf13. See the
    link for details on how to set it up for iTerm2.
  - In order for the `zsh` prompt to render properly, you need to set up your
    terminal to use a powerline-enabled font. Install one of the fonts from
    [here](https://github.com/Lokaltog/powerline-fonts) and then set it as the
    font in `iTerm2 > Preferences > Profiles > Text`.
    There's a few special files in the hierarchy.

### Vim ###

- **spf13**:
  I use [spf13, Steve Francia's excellent Vim distribution][1], as a base. I've
  tweaked some things in his `.vimrc` and his `.vimrc.bundles` though, so
  they're included here.

- **LaTeX editing**:
  I've set things up so that you can use Vim and the pdf viewer Skim to edit
  LaTeX and see a near-continuous preview of the output (it updates after every
  insert and on every write).

- **Obsessive keymapping optimization**:
  I've got a bunch of key mappings, and they're reasonably well-documented.
  Check 'em out if you're also obsessed with vim optimization!


Thanks
------

The structure and content of this repo is inspired by @holman's [dotfiles][3];
the Rakefile is entirely his, and so are parts of this README. As mentioned
above, [spf13-vim][1], [oh-my-zsh][2], and [Powerline][4] form the basis of my
vim and shell configuration. Thanks to all the people involved in these
excellent projects.

[1]: https://github.com/spf13/spf13-vim "spf13-vim"
[2]: https://github.com/robbyrussell/oh-my-zsh "oh-my-zsh"
[3]: https://github.com/holman/dotfiles "holman/dotfiles"
[4]: https://github.com/powerline/powerline "powerline"
