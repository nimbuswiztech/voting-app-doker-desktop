FROM jenkins/jenkins:lts-jdk21
USER root
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git jq python3 unzip \
    && rm -rf /var/lib/apt/lists/*
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && . /etc/os-release \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*
RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in amd64) KARCH=amd64 ;; arm64) KARCH=arm64 ;; *) echo "Unsupported architecture: $ARCH"; exit 1 ;; esac \
    && curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/v1.36.1/bin/linux/${KARCH}/kubectl" \
    && chmod +x /usr/local/bin/kubectl
ARG SONAR_SCANNER_VERSION=7.2.0.5079
RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in amd64) SARCH=linux-x64 ;; arm64) SARCH=linux-aarch64 ;; *) echo "Unsupported architecture: $ARCH"; exit 1 ;; esac \
    && curl -fsSLo /tmp/sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-${SARCH}.zip" \
    && unzip /tmp/sonar-scanner.zip -d /opt \
    && ln -s "/opt/sonar-scanner-${SONAR_SCANNER_VERSION}-${SARCH}/bin/sonar-scanner" /usr/local/bin/sonar-scanner \
    && rm -f /tmp/sonar-scanner.zip
USER jenkins
