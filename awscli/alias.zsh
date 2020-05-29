if [ $(pyenv virtualenvs --bare --skip-aliases | grep "$DOTFILES_AWSCLI_VENV" | wc -l) -eq 0 ]; then
  pyenv virtualenv-delete -f awscli
  pyenv install $DOTFILES_AWSCLI_PYTHON --skip-existing
  pyenv virtualenv $DOTFILES_AWSCLI_PYTHON $DOTFILES_AWSCLI_VENV_NAME && pyenv activate $DOTFILES_AWSCLI_VENV && pip install awscli && pyenv deactivate $DOTFILES_AWSCLI_VENV
fi

alias aws='$HOME/.pyenv/versions/$DOTFILES_AWSCLI_VENV/bin/aws'
alias aws_completer='$HOME/.pyenv/versions/$DOTFILES_AWSCLI_VENV/bin/aws_completer'
