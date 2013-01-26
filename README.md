dotfiles
========

My environment. This is here mainly so I can pull it if I need to work on another machine for a few days for some reason, but you should check it out in case there's something you can use. It uses a Rakefile for install and uninstall, so you can try out the whole setup pretty easily. It's for Mac OSX, but many parts of it will work on Linux too.

Install
-------

Run this:

```sh
git clone https://github.com/wmayner/dotfiles.git ~/dotfiles
cd ~/dotfiles
rake install
```

Files you'll want to personalize right away:
- `zsh/zshrc.symlink` and `env.symlink`: set up your own path variables
- `aliases.symlink`: create your own aliases
- `git/gitconfig.symlink`: commit as yourself

Components
----------

There's a few special files in the hierarchy.

- **\*.zsh**: Any files ending in `.zsh` get sourced into your zsh environment.
- **\*.symlink**: Any files ending in `*.symlink` get symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked in when you run `rake install`.

Vim
---

- **spf13**:
I use [spf13, Steve Francia's excellent Vim distribution][1], as a base.
I've tweaked some things in his `.vimrc` and his `.vimrc.bundles` though, so they're included here.

- **LaTeX editing**:
I've set things up so that you can use Vim and the pdf viewer Skim to edit LaTeX and see a near-continuous preview of the output (it updates after every insert and on every write).

- **Obsessive keymapping optimization**:
I've got a bunch of key mappings, and they're reasonably well-documented.
Check 'em out if you're also obsessed with vim optimization!

Shell
----

I use zsh, with [oh-my-zsh, a "community driven framework for managing your zsh configuration."][2]
It's totally awesome. Aliases are defined in aliases.symlink.

Dependencies
------------

 - zsh configuration depends on [oh-my-zsh][2]. Make sure you set `$ZSH` to point to it.
 - Running the Rakefile depends on `rake`, which you can install by running `sudo gem install rake`.
 - I use iTerm2 rather than terminal; it's more customizable.
   * The colorscheme is Solarized, the same one used in Vim by spf13. See the link for details on how to set it up for iTerm2.
   * In order for the zsh prompt to render properly, you need to set up iTerm2 to use a powerline-enabled font.
     I've included Inconsolata-dz-powerline, which is nice for programming.
     Open it in Finder to install it and then set it as the font in iTerm2 > Preferences > Profiles > Text.

Thanks
------

The structure and content of this repo is inspired by @holman's [dotfiles][3]; the Rakefile is entirely his, and so are parts of this README.
As mentioned above, [spf13-vim][1] and [oh-my-zsh][2] form the basis of my vim and shell configuration.
Thanks to all the people involved in these excellent projects for making programming feel like skiing in powder.

[1]: https://github.com/spf13/spf13-vim "spf13-vim"
[2]: https://github.com/spf13/spf13-vi://github.com/robbyrussell/oh-my-zsh "oh-my-zsh"
[3]: https://github.com/holman/dotfiles "holman/dotfiles"
