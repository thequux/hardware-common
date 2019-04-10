#!/bin/bash

set -euo pipefail

GERBER_OPTIONS=(
	--copy-outline all
	--name-style fixed
	--verbose
)
PNG_OPTIONS=(
	--only-visible
	--photo-mode
	--photo-plating gold
	--dpi 300
)

BOARDS=(
	logic_board
	switch_board
)

VERSION=v2

function notify() {
	echo "$(tput setf 10)$*$(tput op)"
}

function generate_gvp() {
	local board=$1
	cat <<EOF
(gerbv-file-version! "2.0A")
(define-layer! 10 (cons 'filename "${board}.top.gbr")(cons 'visible #t)(cons 'color #(54741 65021 13107)))
(define-layer! 9 (cons 'filename "${board}.outline.gbr")(cons 'visible #t)(cons 'color #(0 50115 50115)))
(define-layer! 8 (cons 'filename "${board}.bottomsilk.gbr")(cons 'visible #t)(cons 'color #(49601 0 57568)))
(define-layer! 7 (cons 'filename "${board}.bottommask.gbr")(cons 'visible #t)(cons 'color #(65535 32639 29555)))
(define-layer! 6 (cons 'filename "${board}.bottom.gbr")(cons 'visible #t)(cons 'color #(29555 29555 57054)))
(define-layer! 5 (cons 'filename "${board}.topsilk.gbr")(cons 'visible #t)(cons 'color #(47802 47802 47802)))
(define-layer! 4 (cons 'filename "${board}.toppaste.gbr")(cons 'visible #t)(cons 'color #(65535 50629 13107)))
(define-layer! 3 (cons 'filename "${board}.topmask.gbr")(cons 'visible #t)(cons 'color #(53713 6939 26728)))
(define-layer! 2 (cons 'filename "${board}.fab.gbr")(cons 'visible #t)(cons 'color #(30069 62194 26471)))
(define-layer! 1 (cons 'filename "${board}.unplated-drill.cnc")(cons 'visible #t)(cons 'color #(65021 53970 52942))(cons 'attribs (list (list 'autodetect 'Boolean 1) (list 'zero_supression 'Enum 0) (list 'units 'Enum 0) (list 'digits 'Integer 4))))
(define-layer! 0 (cons 'filename "${board}.plated-drill.cnc")(cons 'visible #t)(cons 'color #(54227 54227 65535))(cons 'attribs (list (list 'autodetect 'Boolean 1) (list 'zero_supression 'Enum 0) (list 'units 'Enum 0) (list 'digits 'Integer 4))))
;(define-layer! -1 (cons 'filename "/home/thequux/Projects/0x20/control-space/hardware/gerbers/logic_board/v1")(cons 'visible #f)(cons 'color #(0 0 0)))
(set-render-type! 3)

EOF
}

for board in "${BOARDS[@]}"; do
	export_path=gerbers/$board/$VERSION
	[[ -d $export_path ]] && rm -rf $export_path
	mkdir -p $export_path

	# Export gerbers
	notify "Exporting gerbers for $board"
	pcb -x gerber \
	    --gerberfile $export_path/$board \
	    "${GERBER_OPTIONS[@]}" \
	    $board.pcb
	(cd "$export_path" && zip "../../${board}-${VERSION}.zip" *.*.*)

	generate_gvp ${board} >$export_path/${board}.gvp

	for side in top bottom; do
	    typeset -a layers=()
	    for part in mask paste silk  ""; do
		layer="${export_path}/${board}.${side}${part}.gbr"
		[[ -f "$layer" ]] &&
		    layers=( "${layers[@]}" "$layer" )
	    done
	    gerbv -x pdf -o "${export_path}/${board}_${side}.pdf" \
		  "${export_path}/"*.cnc \
		  "${layers[@]}" 
	done
		  

	# Export pretty PNGs
	notify "Exporting PNGs for $board"
	pcb -x png \
	    "${PNG_OPTIONS[@]}" \
	    --outfile $export_path/${board}_front.png \
	    $board.pcb
	pcb -x png \
	    "${PNG_OPTIONS[@]}" \
	    --photo-flip-x \
	    --outfile $export_path/${board}_back.png \
	    $board.pcb

done
