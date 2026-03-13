## Purpose of the `bin/` Directory

The `bin/` directory contains personal executable scripts (personal CLI utilities).
This directory is added to the user's `PATH`, allowing the scripts inside it to be executed like regular shell commands.

These scripts are typically used to automate common tasks and streamline daily development workflows.

Typical use cases include:

- Wrapping frequently used command combinations
- Automating development workflows
- Providing personal CLI utilities
- Extending tools such as Git or Docker
- Managing or maintaining the local development environment

Example structure:

```
bin/
  mkcd         # create a directory and enter it
  extract      # extract many archive formats automatically
  git-sync     # synchronize a git repository
  docker-clean # clean unused Docker resources
```

Common conventions:

- Each script should include a proper shebang, for example:

```
#!/usr/bin/env bash
```

- Each script should focus on doing one thing well.
- Scripts should have executable permissions:

```
chmod +x bin/*
```
