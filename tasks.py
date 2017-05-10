# run the play (perhaps even tap into ansible as an API rather than have a play?)
# add file to inventory
# remove file from inventory (place the file in the link location, unless -D flag is set)
# sync role

import os
import logging
import yaml
from invoke import task, Collection

logging.basicConfig(format='%(levelname)s: %(message)s')

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


@task
def add_dotfile(ctx, src_path, repo_path, incl_mode=True):
    # check that the src path exists
    src_path_is_dir = os.path.isdir(src_path)
    if not os.path.exists(src_path):
        logging.critical("Source path does not exist!")
        exit(2)
    if os.path.islink(src_path):
        logging.critical("Source path already contains a symlink.")
        exit(3)
    if src_path_is_dir:
        actual_repo_path = repo_path if not repo_path.endswith('/') else repo_path.rstrip('/')
    else:
        actual_repo_path = repo_path if not repo_path.endswith('/') else repo_path + os.path.basename(src_path)
    
    full_repo_path = "{0}/{1}".format( )
    inventory = read_current_inventory()
    if filter(lambda item: item['dest'] == src_path, inventory['dotfiles']):
        logging.critical("File already exists in inventory.")
        exit(4)

    if filter(lambda item: item['src'] == actual_repo_path, inventory['dotfiles']):
        pass
        # prompt for override

    if os.path.dirname(actual_repo_path) != '':
        os.makedirs(os.path.dirname(actual_repo_path))
    os.rename(src_path, actual_repo_path)
    os.symlink(actual_repo_path, src_path)

    # make new directory if required
    # move files to new location
    # symlink file
    # add entry to inventory




    # check if src path is a file or directory
    # construct repo_path... if src is a file and dest ends in a /, add filename to source path
    # if src is a file and dest does not end with a /, use the given filename
    # if src is a directory, just use the path
    # check for existing entry at src_path -> fail if found
    # check for existing entry at repo_path -> prompt for overwrite
    # make new directory if required
    # move files to new location
    # symlink file
    # add entry to inventory


@task
def remove_dotfile(ctx, path, return_file=True):
    pass


# dotfile-add () {
#         FILE_REL_PATH=${$(realpath $1)#$HOME/} 
#         REPO_REL_PATH=${$(realpath $2)#$HOME/} 
#         FILE_IN_REPO=$3 
#         MODE=$(stat -c "%a" ~/$FILE_REL_PATH) 
#         mkdir -p $(dirname ~/$REPO_REL_PATH/$FILE_IN_REPO)
#         mv -i ~/$FILE_REL_PATH ~/$REPO_REL_PATH/$FILE_IN_REPO
#         echo "Moved ~/$FILE_REL_PATH to ~/$REPO_REL_PATH/$FILE_IN_REPO"
#         echo ""
#         ln -s ~/$REPO_REL_PATH/$FILE_IN_REPO ~/$FILE_REL_PATH
#         echo "Moved ~/$FILE_REL_PATH to ~/$REPO_REL_PATH/$FILE_IN_REPO"
#         echo ""
#         echo "Ansible variable string:"
#         echo "  - src: \"$FILE_IN_REPO\""
#         echo "    dest: \"~/$FILE_REL_PATH\""
#         echo "    mode: \"0$MODE\""
# }

def read_current_inventory():
    try:
        with open("inventory.yml", 'r') as inventory_file:
            try:
                return yaml.load(inventory_file)
            except yaml.YAMLError as exc:
                logging.critical("Inventory is not valid yaml.")
                exit(3)
    except EnvironmentError:
        return []
    


def write_current_inventory():
    pass

def get_repo_path():
    return print os.path.realpath(__file__)

def _check_virtual_env():
    if not os.getenv("PYENV_VIRTUAL_ENV"):
        logging.error("Not running inside a virtualenv. Exiting...")
        exit(1)


ns = Collection()
ns.add_task(sync_roles)
ns.add_task(install)
ns.add_task(add_dotfile)