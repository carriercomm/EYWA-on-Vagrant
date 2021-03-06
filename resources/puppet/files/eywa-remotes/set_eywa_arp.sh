#!/bin/bash

DB_HOST="192.168.33.10"
DB_NAME="eywa"
DB_USER="eywa"
DB_PASS="1234"
MYSQL_EYWA="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST $DB_NAME -s -N"
T64=$1
XPATH="/var/tmp/one/hooks/eywa/xpath.rb -b $T64"

ONE_VM_ID=`$XPATH /VM/ID`
ONE_UID=`$XPATH /VM/TEMPLATE/CONTEXT/ONE_UID`
ONE_GID=`$XPATH /VM/GID`
ONE_HID=`$XPATH /VM/HISTORY_RECORDS/HISTORY/HID`
ONE_ETH0_IP=`$XPATH /VM/TEMPLATE/NIC/IP`
ONE_IS_EYWA=`$XPATH /VM/TEMPLATE/CONTEXT/IS_EYWA`
ONE_IS_VR=`$XPATH /VM/TEMPLATE/CONTEXT/IS_VR`
if [ "$ONE_IS_VR" == "yes" ]; then
	DB_IS_VR="1"
else
	DB_IS_VR="0"
fi
#NETDEV_0=`sudo virsh dumpxml one-$ONE_VM_ID | xmlstarlet sel -t -v '/domain/devices/interface[alias/@name="net0"]/target/@dev'`
NETDEV_1=`sudo virsh dumpxml one-$ONE_VM_ID | xmlstarlet sel -t -v '/domain/devices/interface[alias/@name="net1"]/target/@dev'`

ONE_PASSWD=`$XPATH /VM/TEMPLATE/CONTEXT/PASSWD`
ONE_SSH_PUBLIC_KEY=`$XPATH /VM/TEMPLATE/CONTEXT/SSH_PUBLIC_KEY`

VR_PRI_IP="10.0.0.1"

QUERY_MC_ADDRESS=`$MYSQL_EYWA -e "select num,address from mc_address where uid='$ONE_UID'"`
VXLAN_G_N=`echo $QUERY_MC_ADDRESS | awk '{print $1}'` # VXLAN Group Number
VXLAN_G_A=`echo $QUERY_MC_ADDRESS | awk '{print $2}'` # VXLAN Group Address

## ================== (임시!!!) ================================================
## 동일 HOST에 동일 계정의 VR이 중복되는 것을 방지... 원칙적으로는 ONE의 스케쥴러에 의해, VR이 배치될 HOST조건을 수립하는 것!!!!
## (계정당,노드당 VR은 한개만 존재해야 하므로, 스케쥴링 HOST에 이미 동일 계정의 VR이 존재하면 작업 대상 신규 VM을 Terminate하고 종료.)
SSH_oneadmin="ssh -l oneadmin 192.168.33.10 -i /var/lib/one/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5"
if [ "$ONE_IS_VR" == "yes" ]; then
	QUERY_EXIST_EYWA_VRs=`$MYSQL_EYWA -e "select count(*) from vm_info where is_vr='1' and vid!='$ONE_VM_ID' and uid='$ONE_UID' and hid='$ONE_HID' and deleted='0'"`
	EXIST_EYWA_VRs=`echo $QUERY_EXIST_EYWA_VRs | awk '{print $1}'`
	if [ "$ONE_IS_EYWA" == "yes" ]; then
		if [ $EXIST_EYWA_VRs -ne 0 ]; then
			sudo arptables -I FORWARD -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1 -j DROP ## 다음 라인의 "onevm delete"에서 수행된 될 Hook가 지울 temp성 정책 하나 추가(일시적으로 중복...)
			$SSH_oneadmin "onevm delete $ONE_VM_ID"
			exit 128
		fi
	fi
fi
##  또한, 계정의 VM에 사용할 비번, SSH가 계정의 Attibute에 각각 PASSWD="", SSH_PUBLIC_KEY=""로 지정되어 있지 않으면 VM생성이 취소 되어야 하는데, 아직....
## =============================================================================

## ==VR인지 아닌지에 따라 분기==
##   arptables 정책이 오작동에 의해 여러번 중복됨을 방지하고자
##   count검사가 필수라 while구문을 사용하였으나,
##   Prototype에서는 단순 추가/삭제로만 처리.. 추후 반영 필요...
##   (while구문의 count 검사 형태는 일단 주석 처리...)

if [ "$ONE_IS_EYWA" == "yes" ]; then
	if [ "$ONE_IS_VR" == "yes" ]; then
		## 추가 대상이 VR 일경우, 2가지 arptables 정책 모두 설정 (non-orphan)
		QUERY_EXIST_EYWA_VMs=`$MYSQL_EYWA -e "select count(*) from vm_info where is_vr='0' and uid='$ONE_UID' and hid='$ONE_HID' and vid!='$ONE_VM_ID' and deleted='0'"`
		EXIST_EYWA_VMs=`echo $QUERY_EXIST_EYWA_VMs | awk '{print $1}'`
		if [ $EXIST_EYWA_VMs -eq 0 ]; then
			## 대상 HOST에 동일 계정의 EYWA VM이 하나도 없으면, arptables 정책 모두 추가
			## (현재 VR이 추가되는 상황이므로 VR조사는 불필요. 본 스크립트 앞 단계에서 가능 여부는 이미 결정된 것으로 가정)
			sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -s $VR_PRI_IP -d $VR_PRI_IP --opcode 2 -j DROP
			sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1 -j DROP
			sudo arptables -A FORWARD -i vxlan$VXLAN_G_N -o vnet+ -s $VR_PRI_IP --opcode 1 -j DROP
		else
			## 대상 HOST에 동일 EYWA VM이 하나 이상 남아 있을 때,
			## (VR만 추가 되는 상황이므로, 나머지 EYWA VM이 로컬 VR을 이용토록 처리)
			sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -s $VR_PRI_IP -d $VR_PRI_IP --opcode 2 -j DROP
			sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1 -j DROP
		fi
	else
		## 추가 대상이 VR이 아닌, 하위 EYWA VM일 경우, 2가지 arptables 정책만 추가 (orphan)
		## (정책 count검사를 위한 while 구문이 있었으나, 삭제 했음..)
		QUERY_EXIST_EYWA_VRs=`$MYSQL_EYWA -e "select count(*) from vm_info where is_vr='1' and uid='$ONE_UID' and hid='$ONE_HID' and deleted='0'"`
		EXIST_EYWA_VRs=`echo $QUERY_EXIST_EYWA_VRs | awk '{print $1}'`
		QUERY_EXIST_EYWA_VMs=`$MYSQL_EYWA -e "select count(*) from vm_info where is_vr='0' and uid='$ONE_UID' and hid='$ONE_HID' and vid!='$ONE_VM_ID' and deleted='0'"`
		EXIST_EYWA_VMs=`echo $QUERY_EXIST_EYWA_VMs | awk '{print $1}'`
		if [ $EXIST_EYWA_VRs -eq 0 ]; then
			## 대상 HOST에 동일 계정의 VR이 존재치 않을 경우,
			if [ $EXIST_EYWA_VMs -eq 0 ]; then
				## 대상 HOST에 동일 계정의 VM이 존재치 않을 경우,
				sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -s $VR_PRI_IP -d $VR_PRI_IP --opcode 2 -j DROP
				sudo arptables -A FORWARD -i vxlan$VXLAN_G_N -o vnet+ -s $VR_PRI_IP --opcode 1 -j DROP
			else
				## 대상 HOST에 동일 계정의 VM이 존재할 경우,
				#sudo arptables -A FORWARD -i vnet+ -o vxlan$VXLAN_G_N -d $VR_PRI_IP --opcode 1 -j DROP
				echo "Pass...."
			fi
		else
			## 대상 HOST에 동일 계정의 VR이 존재할 경우, 
			if [ $EXIST_EYWA_VMs -eq 0 ]; then
				## 대상 HOST에 동일 계정의 VM이 존재치 않을 경우,
				## (VM이 전혀 없이 VR혼자만 노드에 있는 특수한 경우... 일단 무작업으로 Case는 유지..)
				echo "Pass...."
			else
				## 대상 HOST에 동일 계정의 VM이 존재할 경우,
				## (역시, 기존의 arptables 정책이나, BR설정을 변경할 요소가 없음. VM만 단순 추가 처리...)
				echo "Pass...."
			fi
		fi
	fi
fi

exit 0
