FROM rockylinux:8

# Install development tools and dependencies
RUN dnf -y update && \
    dnf -y groupinstall "Development Tools" && \
    dnf -y install wget gcc openssl-devel bzip2-devel libffi-devel xz-devel tk-devel git && \
    dnf clean all && rm -rf /var/cache/dnf

# Set Python version
ARG PYTHON_VERSION=3.13.5

# Download Python source
RUN cd /tmp/ && \
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar xzf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION}

# Configure and build Python:
RUN cd /tmp/Python-${PYTHON_VERSION} &&\
    ./configure \
    --prefix=/opt/python/${PYTHON_VERSION}/ \
    --enable-optimizations \
    --with-lto \
    --with-computed-gotos \
    --with-system-ffi \
    --enable-shared \
    --with-openssl=/usr && \
    make -j "$(grep -c ^processor /proc/cpuinfo)" && \
    make altinstall && \
    rm -rf /tmp/Python-${PYTHON_VERSION} /tmp/Python-${PYTHON_VERSION}.tgz

# Ensure shared libs are found
ENV LD_LIBRARY_PATH=/opt/python/${PYTHON_VERSION}/lib/
ENV PATH=/opt/python/${PYTHON_VERSION}/bin/:$PATH

# Add Python aliases
RUN ln -s /opt/python/3.13.5/bin/python3.13 /opt/python/3.13.5/bin/python3 && \
    ln -s /opt/python/3.13.5/bin/python3.13 /opt/python/3.13.5/bin/python

# Check Python version
RUN python --version

# Set Poetry and version
ARG POETRY_VERSION=2.1.3

# Install poetry
RUN python -m pip install --no-cache-dir poetry==${POETRY_VERSION}

# Set Micromamba version
ARG MICROMAMBA_VERSION=2.3.0-1

# Install micromamba
RUN /bin/bash -l <<InstallMicroMamba
    export VERSION=${MICROMAMBA_VERSION}
    "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
    . /root/.bashrc
    micromamba shell init --shell bash --root-prefix=~/micromamba
InstallMicroMamba

CMD ["/bin/bash", "-l"]
