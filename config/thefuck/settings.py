# The Fuck settings file
#
# This file is loaded by `thefuck` when it starts.
# Customize it to match your workflow.
#
# See https://github.com/nvbn/thefuck#settings for full documentation.

# Enable the most common rules (all rules by default).
# You can restrict this list if you want to disable some rules.
rules = [
    'git_push',
    'git_pull',
    'sudo',
    'python_command',
    'cd_parent',
    'apt_get',
    'sudo_command',
    'rm_dir',
]

# Do not ask for confirmation before applying a fix.
require_confirmation = False

# Keep a reasonable history length.
history_limit = 200

# Automatically apply the fix if there is a single match.
instant_mode = True

# When using thefix more than once, enable repeat shorthand (``fuck``).
repeat = True

# Make sure the environment is predictable.
env = {'LC_ALL': 'C', 'LANG': 'C'}
