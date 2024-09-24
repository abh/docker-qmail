#!/bin/bash

set -e

QMAIL_HOME="/var/qmail"
QMAIL_LOG_DIR="/var/log/qmail"

#QMAIL_DOWNLOAD="http://www.qmail.org/netqmail-1.06.tar.gz"
#EZMLM_DOWNLOAD="https://github.com/bruceg/ezmlm-idx/archive/7.2.2.tar.gz"

## QMAIL INSTALL BASED ON LWQ ##
cd /usr/src
#wget $QMAIL_DOWNLOAD -O netqmail-1.06.tar.gz
#tar -zxf netqmail-1.06.tar.gz
echo "Installing QMAIL"
tar -zxf /app/setup/netqmail-1.06.tar.gz

cd netqmail-1.06

groupadd -g 161 nofiles
useradd -u 161 -g nofiles -d ${QMAIL_HOME}/alias alias
useradd -u 162 -g nofiles -d ${QMAIL_HOME} qmaild
useradd -u 163 -g nofiles -d ${QMAIL_HOME} qmaill
useradd -u 164 -g nofiles -d ${QMAIL_HOME} qmailp
groupadd -g 162 qmail
useradd -u 165 -g qmail -d ${QMAIL_HOME} qmailq
useradd -u 166 -g qmail -d ${QMAIL_HOME} qmailr
useradd -u 167 -g qmail -d ${QMAIL_HOME} qmails

make setup check

mkdir -p ${QMAIL_HOME}/supervise/qmail-send
mkdir -p ${QMAIL_HOME}/supervise/qmail-smtpd

cat > ${QMAIL_HOME}/supervise/qmail-send/run <<EOF
#!/bin/sh
exec ${QMAIL_HOME}/rc
EOF
chmod 755 ${QMAIL_HOME}/supervise/qmail-send/run

cat > ${QMAIL_HOME}/rc <<EOF
#!/bin/sh

# Using stdout for logging
# Using control/defaultdelivery from qmail-local to deliver messages by default

exec env - PATH="${QMAIL_HOME}/bin:\$PATH" \
qmail-start "\`cat ${QMAIL_HOME}/control/defaultdelivery\`"
EOF
chmod 755 ${QMAIL_HOME}/rc

cat > ${QMAIL_HOME}/supervise/qmail-smtpd/run <<EOF
#!/bin/sh

QMAILDUID=\`id -u qmaild\`
NOFILESGID=\`id -g qmaild\`
MAXSMTPD=\`cat ${QMAIL_HOME}/control/concurrencyincoming\`
LOCAL=\`head -1 ${QMAIL_HOME}/control/me\`

if [ -z "\$QMAILDUID" -o -z "\$NOFILESGID" -o -z "\$MAXSMTPD" -o -z "\$LOCAL" ]; then
    echo QMAILDUID, NOFILESGID, MAXSMTPD, or LOCAL is unset in
    echo ${QMAIL_HOME}/supervise/qmail-smtpd/run
    exit 1
fi

if [ ! -f ${QMAIL_HOME}/control/rcpthosts ]; then
    echo "No ${QMAIL_HOME}/control/rcpthosts!"
    echo "Refusing to start SMTP listener because it'll create an open relay"
    exit 1
fi
exec /usr/bin/tcpserver -v -R -l "\$LOCAL" -x /etc/tcp.smtp.cdb -c "\$MAXSMTPD" \
        -u "\$QMAILDUID" -g "\$NOFILESGID" 0 smtp ${QMAIL_HOME}/bin/qmail-smtpd 2>&1
EOF
chmod 755 ${QMAIL_HOME}/supervise/qmail-smtpd/run

# configure supervisord to start qmail
cat > /etc/supervisor/conf.d/qmail-send.conf <<EOF
[program:qmail-send]
directory=${QMAIL_HOME}
environment=HOME=${QMAIL_HOME}
command=${QMAIL_HOME}/supervise/qmail-send/run
user=root
autostart=true
autorestart=true
stdout_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
stderr_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
EOF

cat > /etc/supervisor/conf.d/qmail-smtpd.conf <<EOF
[program:qmail-smtpd]
directory=${QMAIL_HOME}
environment=HOME=${QMAIL_HOME}
command=${QMAIL_HOME}/supervise/qmail-smtpd/run
user=root
autostart=true
autorestart=true
stdout_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
stderr_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
EOF

cat > /etc/tcp.smtp <<EOF
127.:allow,RELAYCLIENT=""
172.17.:allow,RELAYCLIENT=""
EOF
tcprules /etc/tcp.smtp.cdb /etc/tcp.smtp.tmp < /etc/tcp.smtp
chmod 644 /etc/tcp.smtp.cdb

mkdir ${QMAIL_LOG_DIR}

## EZMLM
cd /usr/src
echo "installing ezmlm"
#git clone https://github.com/bruceg/ezmlm-idx.git
#wget ${EZMLM_DOWNLOAD} -O ezmlm-idx-7.2.2.tar.gz
#tar -zxvf ezmlm-idx-7.2.2.tar.gz
tar -zxvf /app/setup/ezmlm-idx-7.2.2.tar.gz
#cd ezmlm-idx
cd ezmlm-idx-7.2.2
echo /usr/bin > conf-bin
bash ./tools/makemake
make clean
make
#make man
#make mysql
make install
