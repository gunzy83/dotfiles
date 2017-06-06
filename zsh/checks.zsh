
dotfiles-repo-changes() {
	cd $DOTFILES_DIR
	if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
		echo "Dotfiles is dirty"
	fi
}

dotfiles-repo-changes
