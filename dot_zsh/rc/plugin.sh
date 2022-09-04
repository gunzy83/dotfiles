rc_chk=(~/.zsh/rc/*.zsh(N))
for file in $rc_chk; do
    source $file
done
