#!/bin/bash


#notes

# see allparameters available
# mediainfo --Info-Parameters

# see all info for a file
# medianinfo [filepath]


# original search in terminal
# sudo find . -type f \( -iname  "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.m4v" -o -iname "*.mpg"  -o -iname "*.mts" \) -size +50M -exec mediainfo {} \; | grep -E "Complete name|Overall bit rate  |File size|Frame rate  |Pixel*.Frame|Width|Height" > outputVideoQuality.txt

help() {
	echo "example:"
	echo "maxFileSize /Volumes/SSD\ 2T/script\ testing/findBigVideos.sh --maxBpf 0.6 --maxFileSize 10 --maxFrameRate 31 --maxBitRate 30 --debugOutput 0 --minWidth 320 --searchDir /Volumes/SSD\ 2T/Sandisk\ SSD\ -\ photos/Album\ -\ most\ current/"
	echo
	echo
	echo -e "option = default value"
	echo -e "maxBpf = 0.6 \t\t find files over Bits Per Frame - ratio of compression to frame size - ideal param to check"
	echo -e "maxFileSize = 31 \t ignore smaller files"
	echo -e "maxFrameRate = 30 \t find files over this frame rate"
	echo -e "maxBitRate = 30 \t find files over this bitrate"
	echo -e "minWidth = 320 \t\t find files over this resolution width"
	echo -e "searchDir = . \t\t root folder to search within"
	echo -e "debugOutput = 0 \t output all files searched"
}

# help param
# ./findBigVideos.sh -h
while getopts ":h" option; do
   case $option in
      h) # display Help
         help
         exit;;
   esac
done

maxBpf=${maxBpf:-0.6}
maxFileSize=${maxFileSize:-31}
maxFrameRate=${maxFrameRate:-30}
maxBitRate=${maxBitRate:-30}
minWidth=${minWidth:-320}
searchDir=${searchDir:-.}
debugOutput=${debugOutput:-0}

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
				echo "argument $1=$2" # Optional to see the parameter:value result
   fi

  shift
done



sep=$'\t|'
search="-iname  \"*.mp4\" -o -iname \"*.avi\" -o -iname \"*.mov\" -o -iname \"*.m4v\" -o -iname \"*.mpg\"  -o -iname \"*.mts\""

#arrays
# arr_bpf=()
# arr_filePath=()
# arr_frameRate=()
# arr_fileSize=()
# arr_width=();
# arr_height=();
echo
echo "searching folder: $searchDir"
echo "debug output: $debugOutput"
echo "searching for videos that"
echo "fileSize>$maxFileSize(MB) && width>$minWidth && ( bpf>$maxBpf OR br>$maxBitRate OR fr>$maxFrameRate )"
echo
echo "Tips:"
echo "⌘+click filepath to open in finder: use iTerm settings>profiles>advanced>semantic history>Always run command 'open -R \1'"
echo "⌘+click-n-drag filepath to any app to open"
echo
echo


maxBitRate=$(( maxBitRate * 1000000 ))
maxFileSize=$(( maxFileSize * 1024*1024 )) #convert Mb to bytes


RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
matchedCount=0
matchedTotalFileSize=0
totalCount=0

while IFS=  read -r -d $'\0'; do

	totalCount=$(( totalCount+1 ))
	
	if [ $debugOutput -eq 1 ]; then
		echo -e ">\t\t\t\t\ $REPLY"
	fi

	[[ $((totalCount%2)) -eq 0 ]] && echoFace="¯\_(ツ)_/¯" || echoFace="___(ツ)___"
	echo -ne "             $echoFace\r"

	fileSize=`mediainfo "$REPLY" --Inform="General;%FileSize%"`


	if [ $fileSize -gt $maxFileSize ]; then

		width=`mediainfo "$REPLY" --Inform="Video;%Width%\n" | grep -E [0-9] -m 1`
		if [ $width -gt $minWidth ]; then

			fileSizeString=`mediainfo "$REPLY" --Inform="General;%FileSize/String%\n" | grep -E [0-9] -m 1`
			bpf=`mediainfo "$REPLY" --Inform="Video;%Bits-(Pixel*Frame)%\n" | grep -E [0-9] -m 1` # multiple values, match just the first value containing "."
			bitRate=`mediainfo "$REPLY" --Inform="Video;%BitRate%\n" | grep -E [0-9] -m 1`
			frameRate=`mediainfo "$REPLY" --Inform="Video;%FrameRate%\n" | grep -E [0-9] -m 1`

			matched=0
			matchedBpf=0
			matchedBr=0
			matchedFr=0
			if (( $(echo "$bpf > $maxBpf" | bc -l) )); then
				matched=1
				matchedBpf=1
			fi
			if (( $(echo "$bitRate > $maxBitRate" | bc -l) )); then
				matched=1
				matchedBr=1
			fi
			if (( $(echo "$frameRate > $maxFrameRate" | bc -l) )); then
				matched=1
				matchedFr=1
			fi

			#filter out files we want only
			if [ $matched -eq 1 ]; then
				echo -ne "\033[2K" #clear out the progress echo from above
				matchedCount=$(( matchedCount+1 ))
				matchedTotalFileSize=$(( matchedTotalFileSize+fileSize ))
				# get info from mediainfo for each file
				bitRateString=`mediainfo "$REPLY" --Inform="Video;%BitRate/String%\n" | grep -E [0-9] -m 1` # multiple values, match just the first value containing numbers
				height=`mediainfo "$REPLY" --Inform="Video;%Height%\n" | grep -E [0-9] -m 1`
				durationString=`mediainfo "$REPLY" --Inform="Video;%Duration/String4%\n" | grep -E [0-9] -m 1`

				# arr_bpf+=($bpf)
				# arr_filePath+=("$REPLY")
				# arr_frameRate+=("$frameRateString")
				# arr_fileSize+=("$fileSizeString")
				# arr_width+=($width)
				# arr_height+=($height)

				[[ $matchedBpf -eq 1 ]] && echoBPF="${RED}$bpf BPF${NC}" || echoBPF="$bpf BPF"
				[[ $matchedBr -eq 1 ]] && echoBR="${RED}$bitRateString${NC}" || echoBR="$bitRateString"
				[[ $matchedFr -eq 1 ]] && echoFr="${RED}$frameRate FPS${NC}" || echoFr="$frameRate FPS"
				echoFilePath="${BLUE}$REPLY${NC}"
				echo -e "$echoBPF $sep $fileSizeString $sep $echoBR $sep $width x $height $sep $durationString $sep $echoFr $sep $echoFilePath"
			fi
		fi
	fi
done < <(find "$searchDir" -type f \( -iname  "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.m4v" -o -iname "*.mpg"  -o -iname "*.mts" \) -print0)

matchedTotalFileSize=$(( matchedTotalFileSize/1024/1024 )) #convert Mb to bytes
echo "found $matchedCount ($matchedTotalFileSize Mb) inefficient videos out of $totalCount"
echo

# post processing
# print out each one that was found
# for ((i = 0; i < ${#arr_filePath[@]}; i++))
# do
# 	DIR="$(dirname "${arr_filePath[$i]}")"
# 	FILE="$(basename "${arr_filePath[$i]}")"
# 	echo "${arr_bpf[$i]} BPF $sep ${arr_fileSize[$i]} $sep ${arr_width[$i]} x ${arr_height[$i]} $sep ${arr_frameRate[$i]} $sep $DIR / $FILE"
# done
