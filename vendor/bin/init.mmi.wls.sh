#!/vendor/bin/sh

PATH=/sbin:/vendor/sbin:/vendor/bin:/vendor/xbin
export PATH

while getopts d op;
do
	case $op in
		d)  dbg_on=1;;
	esac
done
shift $(($OPTIND-1))

scriptname=${0##*/}
wls_device_path=/sys/class/power_supply/wireless/device
firmware_path=/vendor/firmware
wls_firmware_prefix="wls"
wls_fw_success=2

debug()
{
	[ $dbg_on ] && echo "Debug: $*"
}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

validate_firmware_flash()
{
	local wls_fw_status;

	wls_fw_status=$(cat $wls_device_path/program_fw_stat);

	if ((wls_fw_status != wls_fw_success)) then
		notice "Error: Wireless firmware flashing failed!";
		exit 1;
	fi
}

flash_wireless_firmware()
{
	local firmware_name=$1;

	notice "Flashing wireless charger with $firmware_name";

	echo $firmware_name > $wls_device_path/fw_name;
	echo 1 > $wls_device_path/program_fw;

	validate_firmware_flash

	notice "Flashing wireless charger complete";
}

find_wireless_firmware()
{
	local wls_fwvers_vendor;
	local wls_fw_name;
	local wls_fw_version;
	local wls_fw_mask;
	local name;
	local __firmware_name=$1;
	local __firmware_version=$2;

	# Function looks for firmware with format wls-VENDOR-VERSION.bin

	wls_fwvers_vendor=$(cat $wls_device_path/vendor);
	wls_fw_mask=$wls_firmware_prefix-$wls_fwvers_vendor-*.bin

	for d in $firmware_path/*; do
		name=${d#"$firmware_path/"}
		if [[ $name == $wls_fw_mask ]]; then
			wls_fw_name=$name;
			wls_fw_version=${name#"$wls_firmware_prefix-$wls_fwvers_vendor-"};
			wls_fw_version=${wls_fw_version%".bin"};
		fi
	done

	debug "Found wls fw $wls_fw_name, version $wls_fw_version";

	if [ -z $wls_fw_name ] || [ -z $wls_fw_version ]; then
		notice "Error: No valid wireless charger firmware found";
		exit 1;
	fi

	eval $__firmware_name=$wls_fw_name;
	eval $__firmware_version=$wls_fw_version;
}

process_wireless_charger()
{
	local wls_hwid;
	local wls_hwid_prop;
	local wls_cur_fwvers;
	local wls_firmware_name;
	local wls_firmware_vers;

	# If not wls dir, bail
	[ -d $wls_device_path ] || return

	# Get the lastest fw file
	find_wireless_firmware wls_firmware_name wls_firmware_vers

	# Check wls hw id and fw vers
	wls_hwid=$(cat $wls_device_path/chip_id);
	wls_hwid_min=$(cat $wls_device_path/chip_id_min);
	wls_hwid_max=$(cat $wls_device_path/chip_id_max);
	wls_cur_fwvers=$(cat $wls_device_path/fw_ver);

	debug "Wireless charger id is $wls_hwid"
	debug "Wireless charger fw vers is $wls_cur_fwvers";

	# if hw is not valid, flash fw because
	# an unprogrammed chip will report an incorrect hw id
	if ((wls_hwid < wls_hwid_min || wls_hwid > wls_hwid_max)); then
		notice "Wireless charger id $wls_hwid is not valid";
		flash_wireless_firmware $wls_firmware_name;
	# else if newer fw, flash new fw
	elif [[ $wls_cur_fwvers != $wls_firmware_vers ]]; then
		notice "Wireless charger fw vers $wls_cur_fwvers is not current";
		flash_wireless_firmware $wls_firmware_name;
	fi
}

process_wireless_charger
