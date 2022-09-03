# not needed on Manjaro/Arch, completion is installed with the package
{{- if or (eq .chezmoi.osRelease.id "solus") (eg .chezmoi.os "darwin") -}}
eval "$(op completion zsh)"; compdef _op op
{{ end -}}
