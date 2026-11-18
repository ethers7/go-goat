# Security

Security rules for this repository. Marked blocks are maintained by Harness remediation. Text outside those blocks is left as written.


<!-- harness-remediation:sec-docker-non-root -->
### sec-docker-non-root — Run containers as a non-root user

Every runtime stage in the Dockerfile creates a dedicated system user and ends with USER set to it, with files copied via --chown. Avoid /root as WORKDIR so the process never needs root.
<!-- /harness-remediation -->
