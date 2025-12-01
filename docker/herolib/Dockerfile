# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set the working directory
WORKDIR /root

# Copy local installation scripts into the container
COPY scripts/install_v.sh /tmp/install_v.sh
COPY scripts/install_herolib.vsh /tmp/install_herolib.vsh
COPY scripts/install_vscode.sh /tmp/install_vscode.sh
COPY scripts/ourinit.sh /usr/local/bin/

# Make the scripts executable
RUN chmod +x /tmp/install_v.sh /tmp/install_herolib.vsh

RUN apt-get update && apt-get install -y \
    curl bash sudo mc wget tmux htop openssh-server

RUN bash /tmp/install_v.sh

RUN yes y | bash /tmp/install_v.sh --analyzer

RUN bash /tmp/install_vscode.sh

#SSH
RUN mkdir -p /var/run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    chown -R root:root  /root/.ssh && \
    chmod -R 700 /root/.ssh/ && \
    touch /root/.ssh/authorized_keys \
    chmod 600 /root/.ssh/authorized_keys && \
    service ssh start    

RUN /tmp/install_herolib.vsh && \
    apt-get clean && \
    echo "PS1='HERO: \w \$ '" >>  ~/.bashrc \
    rm -rf /var/lib/apt/lists/*


ENTRYPOINT ["/bin/bash"]
CMD ["/bin/bash"]
