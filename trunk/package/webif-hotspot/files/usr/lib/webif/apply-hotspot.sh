#!/bin/sh
#
# Hotspot handler.

reload_hotspot() {
	echo '@TR<<Exporting>> @TR<<hotspot settings>> ...'
	[ -e /bin/save_hotspot ] && {
		/bin/save_hotspot >&- 2>&-
	}

	echo '@TR<<Reloading>> @TR<<hotspot settings>> ...'
	[ -e /etc/init.d/chilli ] && {
		/etc/init.d/chilli stop  >&- 2>&-
		/etc/init.d/chilli start >&- 2>&-
	}
}

[ -f /tmp/.uci/hotspot ] && {
	# save settings
	echo "@TR<<Committing>> $package ..."
	uci_commit "hotspot"
	reload_hotspot
	# and do not save it twice
	rm -f /tmp/.uci/hotspot 2>/dev/null
}
