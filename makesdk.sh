#!/bin/bash
set -e
indir="$(xcrun --show-sdk-path)"
indirios="$(xcrun --sdk iphoneos --show-sdk-path)"
outdir="$PWD/macOSArm.sdk"
# TODO(zhuowei): copy the .o and .a files from iOS
echo "Deleting and recopying $outdir"
rm -rf "$outdir" || true
cp -ac "$indir" "$outdir"
echo "Copying some iOS files over"
pathstocopy="
			usr/include/machine
			usr/include/architecture
			usr/include/arm
			usr/include/mach/arm
			usr/include/mach/machine
			usr/include/libkern
			"
for filepath in $pathstocopy
do
	cp -acv "$indirios/$filepath/" "$outdir/$filepath"
done
exit
sed -e "s/elif !defined(__sys_cdefs_arch_unknown__) && defined(__x86_64__)/elif !defined(__sys_cdefs_arch_unknown__) \&\& defined(__arm64__)/g" -i "" "$outdir/usr/include/sys/cdefs.h"
for tbdfile in $(find "$outdir" -name "*.tbd" -type f)
do
	# Yes I know this should be done with a real YAML parser
	sed -e "s/archs:           \\[ x86_64/archs:           \\[ arm64e/g" \
	-e "s/uuids:           \\[ 'x86_64/uuids:           \\[ 'arm64e/g" \
	-i "" "$tbdfile"
done
