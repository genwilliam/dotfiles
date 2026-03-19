def match(command):
    return command.script.startswith('gti ')


def get_new_command(command):
    # Fix 'gti' common typo to 'git'
    return command.script.replace('gti ', 'git ', 1)


def priority():
    return 50
