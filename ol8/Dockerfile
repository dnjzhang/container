ARG BASE_IMAGE=container-registry.oracle.com/os/oraclelinux:8

# Use the specified base image.  If you cannot pull Oracle Linux 8 from
# Docker Hub, build using `--build-arg BASE_IMAGE=centos:8` to switch to
# a compatible CentOS base.
FROM ${BASE_IMAGE}

# Oracle’s slim images ship with microdnf instead of the full dnf.  If the
# dnf command isn’t available, install it via microdnf【346317560604891†L284-L294】.
RUN if ! command -v dnf >/dev/null 2>&1; then \
        microdnf install -y dnf && microdnf clean all; \
    fi

# Install core utilities.  On RHEL/Oracle systems the netcat utility is
# provided by the nmap‑ncat package【318870285724096†L60-L68】, and the git client
# can be installed from the standard repository using dnf install git【746694873734672†L66-L72】.
# We also install OpenSSH server (sshd) to enable key‑based logins and sudo for
# granting john passwordless administrative access.  Dnf plugins core provides
# the config-manager command used when adding the Docker repository later.
RUN dnf install -y \
        nmap-ncat \
        git \
        openssh-server \
        sudo \
        dnf-plugins-core \
    && dnf clean all

# Add the official Docker CE repository and install the Docker CLI.  The Docker
# docs for RHEL demonstrate installing Docker by enabling the repository and
# running `dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin
# docker-compose-plugin`【44029453316653†L907-L920】.  Here we install only the
# client and its dependencies.  The `--nobest` option is used to avoid pulling
# a release newer than the base OS supports.
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo \
    && dnf install -y --nobest \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
    && dnf clean all

# Create a non‑root user called "john" with a home directory and shell.  Grant
# passwordless sudo by writing a sudoers drop‑in file【645292233494138†L143-L156】.
ARG UID=501
RUN useradd -u ${UID} --create-home --shell /bin/bash john \
    && echo 'john ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/john \
    && chmod 0440 /etc/sudoers.d/john

RUN echo "User and Group"
RUN cat /etc/passwd | grep john
RUN cat /etc/group | grep john

# Copy the public key into the image and install it as john’s authorized_keys.
# This key is generated outside of the build; see the accompanying ol8_id_rsa
# file for the private key.  Proper permissions on ~/.ssh and the
# authorized_keys file are essential for OpenSSH to accept key‑based logins【158876596143386†L246-L253】.
###
# Copy john’s Ed25519 public key into the image and install it as
# john’s authorized_keys.  macOS defaults to the Ed25519 algorithm for new
# SSH keys, so generating this key ensures out‑of‑the‑box compatibility.
# The matching private key is provided alongside this Dockerfile.
COPY ol8_id_ed25519.pub /tmp/ol8_id.pub
RUN mkdir -p /home/john/.ssh \
    && cat /tmp/ol8_id.pub > /home/john/.ssh/authorized_keys \
    && chown -R john:john /home/john/.ssh \
    && chmod 700 /home/john/.ssh \
    && chmod 600 /home/john/.ssh/authorized_keys \
    && rm -f /tmp/ol8_id.pub

# Generate host SSH keys.  Without this step sshd refuses to start.  Then
# create a docker group and add john to it so he can use the docker CLI.  The
# DOCKER_HOST variable points the docker client at the host’s Docker socket,
# which must be mounted at runtime (e.g. `-v /var/run/docker.sock:/var/run/docker.sock`).
RUN ssh-keygen -A \
    && groupadd -g 999 docker || true \
    && usermod -aG docker john

ENV DOCKER_HOST=unix:///var/run/docker.sock

# Expose the SSH port.  When running the container you can map this port to
# your host to enable SSH access (e.g. `-p 2222:22`).
EXPOSE 2222

# Run sshd in the foreground.  Using the -e flag logs to standard error so
# container logs capture sshd’s output.
CMD ["/usr/bin/sudo", "/usr/sbin/sshd", "-D", "-e"]