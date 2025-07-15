# rockylinux8-python

Dockerfile for running Python 3.13, poetry, and micromamba within a Rocky Linux 8 container. This is useful for running Pyinstaller to generate executables that use older versions of GLIBC. E.g. see [this discussion](https://github.com/pyinstaller/pyinstaller/discussions/5669). Rocky Linux 8 includes GLIBC 2.28 (dated 2018), and so this is the minimum version of GLIBC that Pyinstaller-built executables will run on. Rocky Linux 8 will be supported until May 2029.

**Example GitHub action that uses this container with PyInstaller**

In principle setting the `container` key on a job should work:

```yaml
name: build-executables
on:
  workflow_dispatch:
jobs:
  build-executable-CentOS:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/hpcflow/rockylinux8-python:latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: poetry install

      - name: Run PyInstaller
        run: poetry run pyinstaller hpcflow/cli.py --name=hpcflow --onefile
```

However, with our previous old-GLIBC Docker images, we found this stopped working at some point, and instead we do:

```yaml
name: build-executables
on:
  workflow_dispatch:
jobs:
  build-executable-RockyLinux8:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build executable (file) within Docker
        uses: addnab/docker-run-action@v3
        with:
          image: ghcr.io/hpcflow/rockylinux8-python:latest
          options: -v ${{ github.workspace }}:/home --env GH_TOKEN=${{ secrets.GITHUB_TOKEN }}
          run: |
            # install dependencies
            poetry install

            # run Pyinstaller
            poetry run pyinstaller hpcflow/cli.py --name=hpcflow --onefile
```


# Build steps for hosting in the GitHub container registry (GHCR)

The version tag is specified after the `:`, and should include the python, poetry, and micromamba versions, like this:
```
docker build -t ghcr.io/hpcflow/rockylinux8-python:py3.13.5-poetry2.1.3-micromamba2.3.0-1 .
docker push ghcr.io/hpcflow/rockylinux8-python:py3.13.5-poetry2.1.3-micromamba2.3.0-1
```

When updating the latest image use the tag `latest`:
```
docker build -t ghcr.io/hpcflow/rockylinux8-python-poetry:latest .
docker push ghcr.io/hpcflow/rockylinux8-python-poetry:latest
```
<ins>**Make sure to push the image twice**</ins>! Once with the version tag and another with the latest tag.

> **Note:** you may have to login to ghcr before pushing.
> For that, first create a personal access token
> (Settings / Developer settings / New token (classic))
> with permissions for write and delete packages.
> Copy the access token!
> 
> Then use your github username and the copied access token to login with
> ```
> docker login ghcr.io
> ```
> You should now be ready to push.
