#!/bin/sh

echo -e "\e[96m
+--------------------------------------------------------------------+
|                                                                    |
|                 Unbound.conf generator by @rgnldo                  |
|                                                                    |
+--------------------------------------------------------------------+\033[0;39m"
sleep 2

logger -t gen_unbound.sh "Starting script generator unbound.conf $0"
echo "Removing unbound.conf files.."
[ -f /opt/var/lib/unbound/unbound.conf ] && rm -f /opt/var/lib/unbound/unbound.conf

# echo "Removing log's files..."
[ -f /opt/var/lib/unbound/unbound.log ] && rm -f /opt/var/lib/unbound/unbound.log

# Use this default unbound.conf unless a user mounts a custom one:
if [ ! -f /opt/var/lib/unbound/unbound.conf ]; then
    sed \
        -e "s/@THREADS@/1/" \
        -e "s/@MSG_CACHE_SIZE@/30m/" \
        -e "s/@RR_CACHE_SIZE@/30m/" \
        -e "s/@KEY_CACHE_SIZE@/64m/" \
        > /opt/var/lib/unbound/unbound.conf << EOT
server:
    # Interface and port answer
    interface: 127.0.0.1@53535 

    access-control: 0.0.0.0/0 allow
    outgoing-interface: 0.0.0.0

    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes

    # LOG'S
    verbosity: 1
    logfile: "unbound.log"
    #log-queries: yes
    #log-replies: yes
    #log-tag-queryreply: yes
    #log-local-actions: yes
    log-time-ascii: yes
    val-log-level: 1
    log-servfail: yes
    use-syslog: no

    # RFC1918 private IP address - Protects against DNS Rebinding
    private-address: 10.0.0.0/8
    private-address: 172.16.0.0/12
    private-address: 169.254.0.0/16
    private-address: 192.168.0.0/16
    
    module-config: "respip validator iterator"

    # Memory cache and responsive performance
    num-threads: @THREADS@
    key-cache-size: @KEY_CACHE_SIZE@
    msg-cache-size: @MSG_CACHE_SIZE@
    rrset-cache-size: @RR_CACHE_SIZE@
    msg-cache-slabs: 2
    rrset-cache-slabs: 2
    infra-cache-slabs: 2
    key-cache-slabs: 2
    prefetch: yes
    prefetch-key: yes
    serve-expired: yes

    # Privacy & security
    hide-version: yes
    hide-identity: yes
    do-not-query-localhost: no
    minimal-responses: yes
    rrset-roundrobin: yes
    harden-glue: yes

    # Self jail Unbound with user "nobody" to /var/lib/unbound
    username: "nobody"
    directory: "/opt/var/lib/unbound"
    chroot: "/opt/var/lib/unbound"

    # The pid file
    pidfile: "/opt/var/run/unbound.pid"

    # ROOT Server's
    root-hints: "root.hints"

    # DNSSEC & certificates
    auto-trust-anchor-file: "root.key"
    tls-cert-bundle: "/etc/ssl/cert.pem"

    remote-control:
    control-enable: yes
    control-use-cert: no
    control-interface: 127.0.0.1

    rpz:
    name: gen_adblock.rpz
    master: gen_adblock.zone
    zonefile: zones/gen_adblock.rpz
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name:"gen_adblock policy"

    auth-zone:
        name: "."
        url: "https://www.internic.net/domain/root.zone"
        fallback-enabled: yes
        for-downstream: no
        for-upstream: yes
        zonefile: root.zone

EOT
fi
echo "Restarting services..."
unbound-control reload
sleep 3s
echo "Checking unbound.conf..."
unbound-checkconf -f /opt/var/lib/unbound/unbound.conf
sleep 2s
if [ -n "$(pidof unbound)" ];then
  echo -n "No problems! Unbound server "
  echo -e  -n "[\033[01;32m  alive  \033[0;39m]"
  echo
  else
  echo -n "Problem! Unbound server "
  echo -e  -n "[\e[31;1m  dead  \033[0;39m]"
  echo
fi
