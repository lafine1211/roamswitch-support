# Disposable, isolated test container for RoamSwitch Linux security validation.
# Runs inside an isolated --privileged net/mount namespace so destructive tests
# (Air-Gap egress severed, firewall table clobbering, mount hardening) never touch the host.
#
# Usage:
#   docker build -t roamswitch-test .
#   docker run --rm --privileged roamswitch-test             # Runs full penetration & defense test suite (pentest.sh)
#   docker run --rm --privileged roamswitch-test selftest   # Runs core daemon destructive tests (selftest.sh)

FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

# Install test dependencies and runtime libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
        nftables iproute2 procps libnotify-bin ca-certificates curl \
        python3 python3-minimal libgtk-3-0 libayatana-appindicator3-1 \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add official RoamSwitch APT repository and unpack the official distribution package
RUN curl -fsSL https://lafine.net/apt/roamswitch-archive-keyring.asc \
      | gpg --dearmor -o /usr/share/keyrings/roamswitch-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/roamswitch-archive-keyring.gpg] https://lafine.net/apt stable main" \
      | tee /etc/apt/sources.list.d/roamswitch.list \
    && apt-get update \
    && apt-get download roamswitch \
    && dpkg-deb -x roamswitch_*.deb / \
    && rm -f roamswitch_*.deb \
    && rm -rf /var/lib/apt/lists/*

# Prepare test user and directory structure
RUN useradd -m -s /bin/bash tester && \
    mkdir -p /home/tester/Downloads /home/tester/Desktop /home/tester/Documents /home/tester/Pictures && \
    chown -R tester:tester /home/tester

# Install test suites
COPY selftest.sh /usr/local/bin/selftest
COPY pentest.sh /usr/local/bin/pentest
RUN chmod +x /usr/local/bin/selftest /usr/local/bin/pentest

# Default to running the full penetration & defense verification suite
ENTRYPOINT ["/usr/local/bin/pentest"]
