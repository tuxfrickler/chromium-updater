# by mendress @ 10/08/2012  
#  

#!/bin/bash

 CLEAR(){ echo -en "\033c";}                            # Predefined functions
 CIVIS(){ echo -en "\033[?25l";}                        # (see description above)
 CNORM(){ echo -en "\033[?12l\033[?25h";}               #
 TPUT(){ echo -en "\033[${1};${2}H";}                  	#
 DRAW(){ echo -en "\033%@";echo -en "\033(0";}         	#
 WRITE(){ echo -en "\033(B";}                           #

 P0(){ echo -n  '/o-[|]-o\';}                           # function P0 (for progress)
 P1(){ echo -n  '/o-[/]-o\';}                           #          P1
 P2(){ echo -n  '/o-[-]-o\';}                           #          P2
 P3(){ echo -n  '/o-[\]-o\';}                           #          P3
 
function download()
{
  local url=$1
  local dest=$2
    
	touch /tmp/.locking                                  # create an empty control file
	trap "rm -rf /tmp/.locking;exit 2" 1 2 3 15          # catch interrupt keys (like ctrl+c)
    
  echo -n "   "
	wget --progress=dot --output-document="$dest" $url 2>&1  | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
  echo -ne "\b\b\b\b"
}

function makeDir(){
	mkdir -p $CPATH/tmp \
		$CPATH/archives/zip \
		$CPATH/lastBuild
}

function unzipChromium(){
	unzip -oqd $CPATH/tmp "${a[2]}"
	rm -rf $CPATH/lastBuild/*
	mv $CPATH/tmp/chrome-linux/* $CPATH/lastBuild
	mv $CPATH/lastBuild/chrome $CPATH/lastBuild/chromium-browser
	echo "$rev" > $CPATH/lastBuild/LAST_CHANGE
	rm -rf $CPATH/tmp
}

function getVersion(){
	rev=`curl --silent "$url/LAST_CHANGE"`
	a[1]="$url/$rev/chrome-linux.zip" 
	a[2]="$CPATH/archives/zip/chromium_rev_$rev.zip"
}

function checkVersion(){
	if [ -f  $CPATH/lastBuild/LAST_CHANGE ]; then
		var=`cat $CPATH/lastBuild/LAST_CHANGE`

		if [ "$rev" = "$var" ]; then
			update=0
		else
			update=1
		fi
	fi
}

function silentMode(){
	if [ "$update" -eq 1 ]; then
		wget --quiet --output-document="${a[2]}" "${a[1]}"
		unzipChromium
	fi
}

function drawOutput(){
	
	for tmp in {1..7}
	do
		trim=`echo $((2 + (${#msg[$tmp]}) ))`
		msg=`echo "$lineStr" | cut -c "$trim"-$((2 + ${#lineStr}))`
		msg[$tmp]=`echo "${msg[$tmp]}" "$msg"`
	done
	
	CLEAR
	CIVIS
	echo -e ""
	echo -e ""
	DRAW                                                # switch to drawing mode
	echo -e "  lqqqxCHROMIUM UPDATER ${shVersion}xqqqqqqqqqqqqqqqqqqqqk"        # draw box lines
	echo -e "$lineStr"
	echo -e "${msg[1]}"
	echo -e "${msg[2]}"
	echo -e "${msg[3]}"
	echo -e "${msg[4]}"
	echo -e "${msg[5]}"
	echo -e "${msg[6]}"
	echo -e "${msg[7]}"
	echo -e "$lineStr"
	echo -e "  mqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxBY MENDRESSxqqqj"        #
	WRITE                                               # switch back to normal text input mode
	
	echo -e ""
	TPUT 15 10
	echo ""
	CNORM
	
}

function graphMode(){
	touch /tmp/.locking                                	# create an empty control file
	trap "rm -rf /tmp/.locking;exit 2" 1 2 3 15         # catch interrupt keys like (ctrl + c)
	
	msg[1]='  x       .::LAST REVISION DOWNLOADER::.'
  msg[2]=$lineStr
	msg[3]=`echo '  x REV. SERVER' "[$rev]" -- REV. LOCAL "[$var]"` 
  msg[4]=$lineStr
	msg[5]='  x      DOWNLOAD IN PROGRES: '
  msg[6]=$lineStr
	msg[7]=$lineStr

	drawOutput
	
	i=0                                                 # set variable 'i'
	while [ -f /tmp/.locking ]                          # while file exist
	do                                                  # 
		i=$(($i+1))                                       # increase variable i by one each time
		TPUT 13 5 ;P$i                                    # put one of P1, P2, P3 or P4 to exact position

		if [ "$i" = "3" ]; then                           # make sure that variable 'i' will never
			unset i                                         # increase over 3
		fi                                                #
		
		TPUT 9 38;
		sleep 0.2                                         # 0.2 second sleep (200ms)
	done &                                              # fork a subprocess and execute it in background
	
	
	if [ "$update" -eq 1 ]; then
		download "${a[1]}" "${a[2]}"
		unzipChromium
	fi
	
	rm -rf /tmp/.locking                                # remove control file and stop execution
	
	TPUT 15 10
	echo ""
	CNORM
}

#ToDo --> file exists?!
function setPath(){
	msg[1]='  x          .::PROFILE.D INSTALLER::.'
	msg[2]=$lineStr
	
	if [[ $EUID -ne 0 ]]; then
		msg[3]='  x     ! THIS SCRIPT MUST BE RUN AS ROOT !'
		msg[4]=$lineStr
		msg[5]=$lineStr
		msg[6]=$lineStr
		msg[7]=$lineStr
	else
		msg[3]='  x     CREATE "/ETC/PROFILE.D/SCRIPT_NAME.SH"'
		msg[4]='  x        SET CHMOD A+X "/SCRIPT_NAME.SH"'
		msg[5]='  x                  DONE'
		echo "export PATH=/$HOME/$cpath/lastBuild:$PATH" >> /etc/profile.d/SCRIPT_NAME.sh
		chmod a+x /etc/profile.d/SCRIPT_NAME.sh
		source /etc/profile.d/*
	fi
	drawOutput
}

function version(){
	getVersion
	checkVersion
	msg[1]='  x            .::VERSION CHECK::.'
	msg[2]=$lineStr
	msg[3]=`echo '  x         REVISION ON SERVER:'  "$rev"`
	msg[4]=$lineStr
	msg[5]=`echo '  x          REVISION ON LOCAL:'  "$var"`
	msg[6]=$lineStr
	msg[7]=$lineStr
	
	drawOutput
}
###################################################################################
shVersion="0.3"

url="http://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64"
rev="000000"
var="000000"
update=1

CPATH=$HOME/chromium			# chromium path in $HOME

############################################################################
lineStr='  x                                             x '
msg[1]=$lineStr
msg[2]=$lineStr
msg[3]=$lineStr
msg[4]=$lineStr
msg[5]=$lineStr
msg[6]=$lineStr
msg[7]=$lineStr
#############################################################################

case "$1" in
  --silent|-s)
  makeDir
  getVersion
  checkVersion
  silentMode
  ;;
    
  --xmode|-x)
  makeDir
  getVersion
  checkVersion
  graphMode
  ;;
    
  --version|-v)
  version
  ;;
	
  --path|-p)
  setPath
  ;;
	
  --switch|-w)
  ;;
	
  --help-?)
  helpScript
  ;;
	
  *)
  makeDir
	getVersion
	checkVersion
  silentMode
  ;;
esac
