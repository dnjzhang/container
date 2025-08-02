# Dockerfile to build a container based on Oracle Linux 8 (or CentOS 8 as a fallback)
#
# This image installs a full GUI environment, VNC server, netcat, git,
# the OpenSSH server, and sudo.  It creates a user called ``john``
# who can use ``sudo`` without a password and sets up an SSH public
# key for that user.  The SSH daemon listens on port 22 and runs in
# the foreground by default.  To build against a different base (for
# example CentOS 8), override the ``BASE_IMAGE`` build argument:
#
#   docker build --build-arg BASE_IMAGE=centos:8 .

ARG BASE_IMAGE=container-registry.oracle.com/os/oraclelinux:8
FROM ${BASE_IMAGE}

# The slim flavour of the Oracle Linux 8 image uses ``microdnf`` instead
# of the full ``dnf`` package manager.  The official documentation
# recommends installing ``dnf`` via ``microdnf install dnf`` when
# needed【346317560604891†L284-L294】.  This conditional ensures ``dnf``
# is available regardless of which variant is used.
RUN if ! command -v dnf > /dev/null 2>&1; then microdnf install -y dnf; fi

# Install GUI components, VNC server, netcat, git, OpenSSH server and sudo.
#
# - ``dnf groupinstall "Server with GUI"`` installs the full GUI stack
#   including GNOME and X.org; this is the recommended way to get a
#   graphical desktop on Oracle Linux【532063205527449†L67-L89】.
# - ``tigervnc-server`` provides a VNC server to connect to the GUI.
# - ``nmap‑ncat`` (part of the nmap package) supplies the ``ncat`` utility
#   often used as netcat【318870285724096†L60-L68】.
# - ``git`` installs the Git client.
# - ``openssh-server`` brings in ``sshd``; it will be configured to listen
#   on port 22【263185084534169†L66-L73】.
# - ``sudo`` allows the ``john`` user to execute commands as root.
RUN dnf -y groupinstall "Server with GUI" && \
    dnf -y install tigervnc-server nmap-ncat git openssh-server sudo && \
    dnf clean all

# Create a user ``john`` with a home directory and bash shell.  The
# ``NOPASSWD`` directive in the sudoers file allows john to run any
# command via sudo without entering a password【645292233494138†L143-L156】.
RUN useradd -m -s /bin/bash john && \
    echo 'john ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/john && \
    chmod 0440 /etc/sudoers.d/john

# Copy the previously generated public key into the build context.  The
# ``john_id_rsa.pub`` file must exist alongside this Dockerfile when
# building.  Only the public key is copied; keep the private key on
# the host.
COPY john_id_rsa.pub /tmp/john_id_rsa.pub

# Configure SSH for the john user: set up the authorized_keys file,
# correct permissions and ownership, remove the temporary key, and
# generate server host keys.  Using ``ssh-keygen -A`` ensures the
# necessary host keys are created if they do not already exist.
RUN mkdir -p /home/john/.ssh && \
    cat /tmp/john_id_rsa.pub > /home/john/.ssh/authorized_keys && \
    chmod 700 /home/john/.ssh && \
    chmod 600 /home/john/.ssh/authorized_keys && \
    chown -R john:john /home/john/.ssh && \
    rm -f /tmp/john_id_rsa.pub && \
    ssh-keygen -A

# Expose SSH (port 22) and a typical VNC port (5901).
EXPOSE 22 5901

# Start the SSH daemon in the foreground when the container launches.
CMD ["/usr/sbin/sshd", "-D"]