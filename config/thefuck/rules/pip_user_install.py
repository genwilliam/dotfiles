def match(command):
    # Suggest --user installation when permission denied.
    return ('pip install' in command.script and
            'Permission denied' in command.stderr)


def get_new_command(command):
    if '--user' in command.script:
        return None
    return command.script + ' --user'


def priority():
    return 10
