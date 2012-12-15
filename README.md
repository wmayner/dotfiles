dotfiles
========

My environment. This is here mainly so I can pull it if I need to work on another machine for a few days for some reason, but since you're reading this you might as well check it out in case there's something you could use.

Vim
---

- **spf13**:
I use [spf13, Steve Francia's excellent Vim distribution][1], as a base. I've tweaked some things in his `.vimrc` and his `.vimrc.bundles` though, so they're included here.

- **LaTeX editing**:
I've set things up so that you can use Vim and the pdf viewer Skim to edit LaTeX and see a near-continuous preview of the output (it updates after every insert and on every write).

- **Obsessive keymapping optimization**:
I've got a bunch of key mappings, and they're reasonably well-documented. Check 'em out if you're also obsessed with vim optimization!

Shell
----

I use zsh, with [oh-my-zsh, a "community driven framework for managing your zsh configuration."][2] It's totally awesome.

Dependencies
------------

 - zsh configuration depends on [oh-my-zsh][2], which should be cloned into your `$HOME`.

[1]: https://github.com/spf13/spf13-vim "spf13-vim"
[2]: https://github.com/spf13/spf13-vi://github.com/robbyrussell/oh-my-zsh "oh-my-zsh"
