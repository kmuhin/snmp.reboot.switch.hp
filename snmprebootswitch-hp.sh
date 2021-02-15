#!/bin/bash

# Copyright (C) Konstantin Mukhin Al.

# If switch is available script does nothing. Script ends.
# If switch fail, sript does ping OOBM 3 times (Checking savepower state).
# If OOBM is not available script does nothing. Script ends.
# If OOBM is available script checks state of fans through SNMP 1.3.6.1.4.1.11.2.14.11.1.2.6.1.4.1
# If state of fans not equal 4(ok), script resets switch through SNMP 1.3.6.1.4.1.11.2.14.11.1.4.1.0

# Если доступен, выходит и ничего не делает.
# Если не получилось, пингует 3 раза интерфейс OOBM.
# Если не доступен, выходит и ничего не делает.
# Если доступен, проверяет состояние вентиляторов через SNMP 1.3.6.1.4.1.11.2.14.11.1.2.6.1.4.1
# Если ответ получен и состояние не 4(ok), то делает перезагрузку свитча через SNMP 1.3.6.1.4.1.11.2.14.11.1.4.1.0
# Установкой значения в 2 - normal reset

#msk-zoneC-sw1
SW_IP_MANAGER="172.16.131.55"
SW_IP="172.16.255.2"


FANSTATUS=([1]="unknown" [2]="bad" [3]="warning" [4]="good" [5]="notPresent")


    snmpSysDescr=$(snmpwalk -v2c -OvQ -cpublic ${SW_IP_MANAGER} sysDescr | head -n1)
    snmpEngineTime=$(snmpwalk -OUvq -v2c -cpublic ${SW_IP_MANAGER} sysUpTime 2>/dev/null)
    snmSysName=$(snmpwalk -r1 -t1 -v2c -OvQ -cpublic ${SW_IP_MANAGER} sysName 2>/dev/null)
    echo "
${snmSysName}
${snmpEngineTime}
${snmpSysDescr}
"


if ret=$(ping -c3 ${SW_IP}); then
    echo "${SW_IP} is available. exiting."
    exit 0
fi

echo "${SW_IP} did not answer. Check oobm interface ${SW_IP_MANAGER}."
if ret=$(ping -c3 ${SW_IP_MANAGER}); then
    echo "${SW_IP_MANAGER} oobm is available. Check fans."
    swfanstatus=$(snmpget -v2c -c public -Oveq ${SW_IP_MANAGER} 1.3.6.1.4.1.11.2.14.11.1.2.6.1.4.1)
    if [[ ${swfanstatus} -eq 4 ]]; then
	echo "Fans: ${FANSTATUS[${swfanstatus}]}(${swfanstatus})"
	echo "Exiting."
    elif [[  ${swfanstatus} ]]; then
	echo "Fans: ${FANSTATUS[${swfanstatus}]}(${swfanstatus})"
	echo "Try reboot."
	snmpset -cpublic -v2c ${SW_IP_MANAGER} 1.3.6.1.4.1.11.2.14.11.1.4.1.0 i 2
    else
	echo "Fans state is not available. Exiting."
    fi
else
    echo "oobm ${SW_IP_MANAGER} did not answer. Do nothing."
fi

