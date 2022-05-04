#!/bin/bash


function video2mp3() {
  filename=$1
  ext="${filename##*.}"
  name="${filename%.*}"
  ffmpeg -i "${filename}" -acodec libmp3lame -aq 4 "${name}.mp3"
}



