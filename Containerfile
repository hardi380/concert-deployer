FROM registry.redhat.io/ubi9/ubi-minimal:latest

LABEL name="ibm-concert-deployer" \
      vendor="IBM" \
      summary="Automated Ansible-based installer for IBM Concert on OpenShift" \
      description="Deploys IBM Concert Protect, Workflows, and DataApps on Red Hat OpenShift"

RUN microdnf update -y && \
    microdnf install -y git python3 python3-pip tar gzip jq shadow-utils && \
    microdnf clean all

# Install Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

# Install Ansible collections
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml && \
    rm -f /tmp/requirements.yml

# Create non-root runner user
RUN useradd -u 1001 -r -g 0 -m -d /opt/app-root -s /sbin/nologin -c "Concert Deployer User" runner && \
    chown -R 1001:0 /opt/app-root

WORKDIR /opt/app-root
COPY --chown=1001:0 . /opt/app-root/

USER 1001

ENTRYPOINT ["ansible-playbook", "-i", "inventory/localhost.yml"]
CMD ["playbooks/install_concert.yml"]
