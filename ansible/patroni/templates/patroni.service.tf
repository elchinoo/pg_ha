# It's not recommended to modify this file in-place, because it will be
# overwritten during package upgrades.  If you want to customize, the
# best way is to create a file "/etc/systemd/system/patroni.service",
# containing
#	.include /lib/systemd/system/patroni.service
#	Environment=PATRONI_CONFIG_LOCATION=...
# For more info about custom unit files, see
# http://fedoraproject.org/wiki/Systemd#How_do_I_customize_a_unit_file.2F_add_a_custom_unit_file.3F

[Unit]
Description=PostgreSQL high-availability manager
After=syslog.target network.target

[Service]
Type=simple

User={{ pg_user }}
Group={{ pg_user }}

# Read in configuration file if it exists, otherwise proceed
EnvironmentFile=-{{ config_dir }}/patroni_env.conf

# The default is the user's home directory, and if you want to change it, you must provide an absolute path.
# WorkingDirectory=/home/sameuser

# Where to send early-startup messages from the server
# This is normally controlled by the global default set by systemd
#StandardOutput=syslog
# Location of Patroni configuration
Environment=PATRONI_CONFIG_LOCATION={{ config_dir }}/patroni.yaml

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000

# Pre-commands to start watchdog device
# Uncomment if watchdog is part of your patroni setup
#ExecStartPre=-/usr/bin/sudo /sbin/modprobe softdog
#ExecStartPre=-/usr/bin/sudo /bin/chown postgres /dev/watchdog

# Start the patroni process
ExecStart=/usr/bin/patroni ${PATRONI_CONFIG_LOCATION}

# Send HUP to reload from patroni.yml
ExecReload=/bin/kill -s HUP $MAINPID

# Only kill the patroni process, not it's children, so it will gracefully stop postgres
KillMode=process

# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=30

# Restart the service if it crashed
Restart=on-failure

[Install]
WantedBy=multi-user.target
