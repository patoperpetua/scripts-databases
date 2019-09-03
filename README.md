# SINGLETON SD - SCRIPTS - DATABASES

This project contains Linux bash scripts to use locally or in gitlab-ci templates to interact with liquibase database projects.

> The **main repository** is hosted in [gitlab.com/singletonsd/scripts/databases](https://gitlab.com/singletonsd/scripts/databases.git) but it is automaticaly mirrored to [github.com/singletonsd](https://github.com/singletonsd/scripts-databases.git), [github.com/patoperpetua](https://github.com/patoperpetua/scripts-databases.git) and to [gitlab.com/patoperpetua](https://gitlab.com/patoperpetua/scripts-databases.git). If you are in the Github page it may occur that is not updated to the last version.

## AVAILABLE SCRIPTS

<!-- TODO: -->
### GITLAB-CI LINT TEST

You can test your .gitlab-ci.yml files by executing the following:

```bash
curl -s https://singletonsd.gitlab.io/scripts/gitlab-ci/latest/gitlab-ci_lint_test_standalone.sh | bash /dev/stdin
```

That script contains the following options:

```bash
-h | --help: display help.
-o | --only: the name of the file or folder to test.
```

It can be downloaded by:

```bash
curl -o gitlab-ci_lint_test_standalone.sh -L https://singletonsd.gitlab.io/scripts/gitlab-ci/latest/gitlab-ci_lint_test_standalone.sh
```

## DOWNLOAD

All scripts are available also inside a zip file under [this url](https://singletonsd.gitlab.io/scripts/databases/latest/scripts.zip). Or you can execute the following to download:

```bash
mkdir -p binaries && \
curl -o binaries/scripts.zip -L https://singletonsd.gitlab.io/scripts/databases/latest/scripts.zip && \
cd binaries && unzip scripts.zip && mv src/* . && rm -r src && rm -r scripts.zip && cd ..
```

## GIT HOOK

You can setup gitlab lint tester to be run before a commit. To do that just execute the following script under your git repository:

```bash
curl -s https://singletonsd.gitlab.io/scripts/gitlab-ci/latest/gitlab-ci_lint_hook_installer.sh | bash /dev/stdin
```

## STRUCTURE

Master branch is setup as latest folder. To use an specific version, put the version name before the file name like:

```url
https://singletonsd.gitlab.io/scripts/databases/latest/gitlab-ci_lint_test_standalone.sh
https://singletonsd.gitlab.io/scripts/databases/develop/gitlab-ci_lint_test_standalone.sh
https://singletonsd.gitlab.io/scripts/databases/v0.0.2/gitlab-ci_lint_test_standalone.sh
```

## DOCUMENTATION

- [Shellcheck](https://github.com/koalaman/shellcheck)

## TODO

- [ ] Fix documentation.
- [X] Use gitlab-ci template.
- [ ] Create a git hook installer.
- [ ] Create reusable scripts.
- [ ] Verify scripts functions.

----------------------

© [Singleton SD](http://www.singletonsd.com), Italy, 2019.
