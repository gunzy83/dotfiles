# run the play (perhaps even tap into ansible as an API rather than have a play?)
# add file to inventory
# remove file from inventory (place the file in the link location, unless -D flag is set)
# sync role

import os
import logging
from invoke import task, Collection

@task
def sync_roles(ctx):
    _check_virtual_env()

    command = "$PYENV_VIRTUAL_ENV/bin/ansible-galaxy install --role-file roles.yml"
    result = ctx.run(command, pty=True)

@task
def install(ctx):
    _check_virtual_env()

    command = "$PYENV_VIRTUAL_ENV/bin/ansible-playbook -i local play.yml -v"
    result = ctx.run(command, pty=True)


def _check_virtual_env():
    if not os.getenv("PYENV_VIRTUAL_ENV"):
        logging.error("Not running inside a virtualenv. Exiting...")
        exit(1)

ns = Collection()
ns.add_task(sync_roles)
ns.add_task(install)