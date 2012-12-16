# get environment
source ~/.env
# get aliases
source $ALIASES

# Use .localrc for SUPER SECRET CRAP that you don't
# want in your public, versioned repo.
if [[ -a ~/.zshrc.local ]]
then
  source ~/.zshrc.local
fi
