# Use linton/docker-snort as the base image
FROM linton/docker-snort

# The base image already has Snort 2.9.8.0 and DAQ 2.0.6 installed.
# Snort configuration is typically expected at /etc/snort/etc/snort.conf
# Rules are typically in /etc/snort/rules/

# Ensure standard log directory exists (though likely present in base)
RUN mkdir -p /var/log/snort && chmod 777 /var/log/snort

# Ensure custom rules directory exists for mounting (though likely present in base)
RUN mkdir -p /etc/snort/rules

# Ensure the directory for snort.conf exists (though likely present in base)
RUN mkdir -p /etc/snort/etc

# Set a working directory (optional, but can be good practice)
WORKDIR /etc/snort

# The default command can be overridden in docker-compose.yml
# The base image might have its own CMD or ENTRYPOINT.
# For flexibility, we'll control the command via docker-compose.