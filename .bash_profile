# CONFIG {{{

# use vi to edit commands
set -o vi

#}}}

# ALIASES {{{

  # Config {{{

    # use servers with vim
    alias vim='/Applications/MacVim.app/Contents/MacOS/Vim --servername VIM'
    # use MacVim as gvim
    alias gvim="open -a MacVim"
    # edit bash profile (this file)
    alias vbp="vim ~/.bash_profile"
    # source bash profile
    alias sbp="source ~/.bash_profile"
    # move up one directory
    alias ..="cd .."
    # edit local .vimrc
    alias vrc="vim ~/.vimrc.local"
    # edit .vimrc
    alias vrcreal="vim ~/.vimrc"
    # edit local vim bundles for vundle
    alias vbun="vim ~/.vimrc.bundles.local"
    # cd scripts
    alias cdscripts="cd ~/.bash_scripts/my_scripts"
    # make sudo check if the next command is an alias
    alias sudo="sudo "
    # edit .slate
    alias vslate="vim ~/.slate"
    # cd to dropbox
    alias ~~="cd ~/Dropbox/"

  # }}}

  # Latex {{{

    # run latexmk with following options:
    # compile to pdf
    # 'preview continuously'
    # run despite erros
    alias ltx="latexmk -pdf -pvc"

    # vim the .tex files in the current directory
    alias vtex="find . -iname "*.tex" -exec vim {} \;"
    # mvim the .tex files in the current directory
    alias mtex="find . -iname "*.tex" -exec mvim {} \;"

  # }}}

  # Dev {{{

    # edit .gitconfig
    alias vgrc="vim ~/.gitconfig"
    # edit .hgrc
    alias vhgrc="vim ~/.hgrc"
    # cd dev
    alias cdd="cd ~/Dropbox/dev/"
    # copy current directory to htdocs to run php server locally with MAMP
    alias pphp="sudo rm -r /Applications/MAMP/htdocs; mkdir /Applications/MAMP/htdocs; cp -r ~/Dropbox/jobs-internships-etc/web-resume/ /Applications/MAMP/htdocs"
    # edit app.coffee
    alias vsp="vim ~/Dropbox/dev/coffeescript/fairdiv/src/app.coffee"
    # cd splitr
    alias cdsp="cd ~/Dropbox/dev/coffeescript/fairdiv/"

  # }}}

  # School {{{

    # ssh to brown cs
    alias sshcs="ssh wmayner@ssh.cs.brown.edu"
    # cd multicore
    alias cdcs="cd ~/Dropbox/school/semester-7/multicore/"
    # cd crypto
    alias cdcrypto="cd ~/Dropbox/school/semester-7/crypto/"
    # cd incompleteness
    alias cdinc="cd ~/Dropbox/school/semester-7/incompleteness/exercises1"
    # edit exercises1
    alias vex1="gvim ~/Dropbox/school/semester-7/incompleteness/exercises1/exercises1-handin.tex"

  # }}}

  # Summerwork {{{

    # cd summerwork
    alias cdpaper="cd ~/Dropbox/iit-reu/repos/summerwork/research\ paper/"
    # edit summerwork
    alias vpaper="gvim ~/Dropbox/iit-reu/repos/summerwork/research\ paper/paper.tex"

  # }}}

  # Resume {{{

    # cd web-resume
    alias cdres="cd ~/Dropbox/jobs-internships-etc/web-resume/"
    # edit index.php
    alias vres="vim ~/Dropbox/jobs-internships-etc/web-resume/index.php"
    # edit paper resume
    alias vpres="gvim ~/Dropbox/jobs-internships-etc/resumes/resume.tex"
    # cd paper resume
    alias cdpres="cd ~/Dropbox/jobs-internships-etc/resumes/"

  # }}}

# }}}

# SCRIPTS {{{

  # my scripts
  export PATH=~/.bash_scripts/my-scripts:$PATH

  # fuzzycd {{{
    # commented out for now because of strange hangs
    # export PATH=~/.bash_scripts/fuzzycd/:$PATH
    # source ~/.bash_scripts/fuzzycd/fuzzycd_bash_wrapper.sh
  # }}}

# }}}

# MISC {{{

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
# dont let MacVim fork another process from the parent
export VISUAL='mvim -f'

##
# Your previous /Users/will/.bash_profile file was backed up as /Users/will/.bash_profile.macports-saved_2012-12-03_at_22:17:57
##

# MacPorts Installer addition on 2012-12-03_at_22:17:57: adding an appropriate PATH variable for use with MacPorts.
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.

# Put /usr/local/bin/ back at beginning of $PATH
export PATH=usr/local/bin:$PATH

# }}}
