# run the play (perhaps even tap into ansible as an API rather than have a play?)
# add file to inventory
# remove file from inventory (place the file in the link location, unless -D flag is set)
# sync role

import os
import shutil
import stat
import logging
import yaml
import yaml.constructor
import pyaml
from collections import OrderedDict
from invoke import task, Collection


@task
def sync_roles(ctx):
    _check_virtual_env()

    command = "$PYENV_VIRTUAL_ENV/bin/ansible-galaxy install --force --role-file roles.yml"
    result = ctx.run(command, pty=True)


@task
def install(ctx):
    _check_virtual_env()

    command = "$PYENV_VIRTUAL_ENV/bin/ansible-playbook -i local play.yml -v"
    result = ctx.run(command, pty=True)


@task
def add_dotfile(ctx, src_path, repo_path, incl_mode=True, post_command=None):
    # check that the src path exists
    src_path_is_dir = os.path.isdir(src_path)
    if not os.path.exists(src_path):
        print("Error: Source path does not exist!")
        exit(2)
    if os.path.islink(src_path):
        print("Error: Source path already contains a symlink.")
        exit(3)
    if src_path_is_dir:
        repo_path = repo_path if not repo_path.endswith('/') else repo_path.rstrip('/')
    else:
        repo_path = repo_path if not repo_path.endswith('/') else repo_path + os.path.basename(src_path)

    mode = oct(os.stat(src_path)[stat.ST_MODE])[-4:] if incl_mode else None

    if get_matching_entries(dest=src_path):
        print("Error: File already exists in inventory.")
        exit(4)

    if get_matching_entries(src=repo_path):
        if ask_choice("Duplicate file found in inventory. Replace file for '{}'?".format(repo_path)):
            move_path_to_repo(src_path, repo_path)
        else:
            delete_path()
    else:
        move_path_to_repo(src_path, repo_path)

    add_to_inventory(repo_path, src_path, mode, post_command)


@task
def remove_dotfile(ctx, path, restore=True):
    # find matching entries
    matches = get_matching_entries(src=path)
    if not matches:
        matches = get_matching_entries(dest=path)
        if not matches:
            print("Error: no entry found for path '{}'".format(path))
            exit(1)
    print("Matches for path found: \n")
    print(dump_to_yaml(matches))
    if ask_choice("Do you want to remove these?"):
        for item in matches:
            remove_from_inventory(item)
            if restore:
                restore_path(item["src"], item["dest"])
            else:
                delete_path(item["src"])


def get_matching_entries(src=None, dest=None):
    inventory = read_current_inventory()
    if src:
        inventory = filter(lambda item: item['src'] == src, inventory)
    if dest:
        inventory = filter(lambda item: item['dest'] == dest, inventory)
    return inventory


def add_to_inventory(src, dest, mode, post_command=None):
    print("Adding entry to inventory...")
    inventory = read_current_inventory()
    item = OrderedDict()
    item["src"] = relative_home(src)
    item["dest"] = relative_home(dest)
    if mode:
        item["mode"] = mode
    if post_command:
        item["post_command"] = post_command
    inventory.append(item)
    write_updated_inventory(inventory)
    print("Entry added to inventory: \n\n{}".format(dump_to_yaml([item])))


def remove_from_inventory(item):
    print("Removing entry from inventory...")
    inventory = read_current_inventory()
    inventory.remove(item)
    write_updated_inventory(inventory)
    print("Entry removed from inventory: \n\n{}".format(dump_to_yaml([item])))


def read_current_inventory():
    try:
        with open("inventory.yml", 'r') as inventory_file:
            try:
                return yaml.load(inventory_file, OrderedDictYAMLLoader)
            except yaml.YAMLError as exc:
                print("Error: Inventory is not valid yaml.")
                exit(3)
    except EnvironmentError:
        return []


def write_updated_inventory(inventory):
    try:
        with open("inventory.yml", 'w') as inventory_file:
            dump = dump_to_yaml(inventory)
            inventory_file.write("# Automatically generated by invoke task\n")
            inventory_file.write(dump)
    except EnvironmentError:
        return []


def move_path_to_repo(src_path, repo_path):
    print("Moving and symlinking...")
    full_repo_path = create_full_repo_path(repo_path)
    if os.path.dirname(repo_path) != repo_path:
        try:
            os.makedirs(os.path.dirname(full_repo_path))
        except OSError:
            print("Warning: Parent directory already exists, not creating...")
    os.rename(src_path, full_repo_path)
    print("Move complete.")
    os.symlink(full_repo_path, src_path)
    print("Symlink successful.")


def restore_path(src, dest):
    src = full_home(src)
    dest = full_home(dest)
    full_repo_path = create_full_repo_path(src)
    delete_path(dest)
    os.rename(full_repo_path, dest)


def delete_path(path):
    if os.path.isdir(path) and not os.path.islink(path):
        shutil.rmtree(path)
    else:
        os.remove(path)


def ask_choice(question):
    print(question)
    choice = raw_input('[Y/n]> ')
    return choice in ['Y','y','']


def relative_home(path):
    home_path = os.getenv("HOME")
    return path.replace(home_path, '~', 1)


def full_home(path):
    home_path = os.getenv("HOME")
    return path.replace('~', home_path, 1)


def dump_to_yaml(data):
    return pyaml.dump(data, width=200, string_val_style='"')


def create_full_repo_path(repo_path):
    return "{0}/{1}".format(get_repo_location(),repo_path)


def get_repo_location():
    return os.path.dirname(os.path.realpath(__file__))


def _check_virtual_env():
    if not os.getenv("PYENV_VIRTUAL_ENV"):
        print("Error: Not running inside a virtualenv. Exiting...")
        exit(1)


class OrderedDictYAMLLoader(yaml.Loader):
    """
    A YAML loader that loads mappings into ordered dictionaries.
    """

    def __init__(self, *args, **kwargs):
        yaml.Loader.__init__(self, *args, **kwargs)

        self.add_constructor(u'tag:yaml.org,2002:map', type(self).construct_yaml_map)
        self.add_constructor(u'tag:yaml.org,2002:omap', type(self).construct_yaml_map)

    def construct_yaml_map(self, node):
        data = OrderedDict()
        yield data
        value = self.construct_mapping(node)
        data.update(value)

    def construct_mapping(self, node, deep=False):
        if isinstance(node, yaml.MappingNode):
            self.flatten_mapping(node)
        else:
            raise yaml.constructor.ConstructorError(None, None,
                'expected a mapping node, but found %s' % node.id, node.start_mark)

        mapping = OrderedDict()
        for key_node, value_node in node.value:
            key = self.construct_object(key_node, deep=deep)
            try:
                hash(key)
            except TypeError, exc:
                raise yaml.constructor.ConstructorError('while constructing a mapping',
                    node.start_mark, 'found unacceptable key (%s)' % exc, key_node.start_mark)
            value = self.construct_object(value_node, deep=deep)
            mapping[key] = value
        return mapping


ns = Collection()
ns.add_task(sync_roles)
ns.add_task(install)
ns.add_task(add_dotfile)
ns.add_task(remove_dotfile)
