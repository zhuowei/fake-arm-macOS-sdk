#!/bin/bash

# Creates a fake ARM macOS SDK for Xcode, by editing the x86_64 SDK.

set -e
indir="$(xcrun --show-sdk-path)"
indirios="$(xcrun --sdk iphoneos --show-sdk-path)"
outdir="$PWD/MacOSX.sdk"

# TODO(zhuowei): copy the .o and .a files from iOS

recopy=true

if $recopy
then

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
	cp -ac "$indirios/$filepath/" "$outdir/$filepath"
done

echo "Editing tbd files"

for tbdfile in $(find "$outdir" -name "*.tbd" -type f)
do
	# Yes I know this should be done with a real YAML parser
	sed -e "s/archs:           \\[ x86_64/archs:           \\[ arm64e/g" \
	-e "s/uuids:           \\[ 'x86_64/uuids:           \\[ 'arm64e/g" \
	-i "" "$tbdfile"
done

sed -e "s/x86_64/arm64e/g" -i "" "$outdir/SDKSettings.json"

fi # if $recopy

echo "Editing headers"

sed -e "s/elif !defined(__sys_cdefs_arch_unknown__) && defined(__x86_64__)/elif !defined(__sys_cdefs_arch_unknown__) \&\& defined(__arm64__)/g" -i "" "$outdir/usr/include/sys/cdefs.h"

sed -e "s/__x86_64__/__arm64__/g" -e "s@i386/@arm/@g" -i "" "$outdir/usr/include/machine/_limits.h"
# Remove the Dtrace header since that's not in the iOS sdk, only in the XNU source
# and I'm not cloning the entire source just for that
sed -e "s@header \".*/sdt.h\"@@g" \
	-e "s@header \"mach/machine/sdt_isa.h\"@@g" \
	-e "s@header \"libkern/i386/_OSByteOrder.h\"@header \"libkern/arm/OSByteOrder.h\"@g" \
	-e "s@header \"profile.h\"@@g" \
	-i "" "$outdir/usr/include/module.modulemap"
# OSByteOrder?!
rm -f "$outdir/usr/include/machine/profile.h" \
	"$outdir/usr/include/machine/fasttrap_isa.h" \
	"$outdir/usr/include/machine/vmparam.h"
touch "$outdir/usr/include/machine/profile.h" \
	"$outdir/usr/include/machine/fasttrap_isa.h" \
	"$outdir/usr/include/machine/vmparam.h"
# vcvt on ARM also saturates
sed -e "s/__ppc64__/__arm64__/" -i "" \
	"$outdir/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/FixMath.h"
# (Wrath of Khan voice) CARBON
sed -e "s/TARGET_CPU_PPC64/1/" \
	-i "" "$outdir/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MachineExceptions.h"
LC_ALL=C sed -e "s/if TARGET_CPU_PPC || TARGET_CPU_X86 || TARGET_CPU_PPC64 || TARGET_CPU_X86_64/if 1/" \
	-i "" \
	"$outdir/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/Headers/fp.h"

echo "Editing Swift modules"

# Edit Swift modules to specify arm64e.

for filepath in $(find "$outdir/usr/lib/swift" -name "x86_64.swiftinterface" -type f) \
$(find "$outdir/System/Library" -name "x86_64.swiftinterface" -type f)
do
	sed -e "s/-target x86_64-apple-macosx10.15/-target arm64e-apple-macosx10.15/" \
		-e "s/-target x86_64-apple-macos10.15/-target arm64e-apple-macos10.15/" \
		"$filepath" >"$(dirname "$filepath")/arm64e.swiftinterface"
done
python removeonefloat80.py "$outdir/usr/lib/swift/CoreGraphics.swiftmodule/arm64e.swiftinterface" \
	"$outdir/usr/lib/swift/CoreGraphics.swiftmodule/arm64e.swiftinterface" 3

# Replace some Swift modules with the iOS equivalents

for filepath in usr/lib/swift/Swift.swiftmodule \
	usr/lib/swift/SwiftOnoneSupport.swiftmodule \
	usr/lib/swift/Darwin.swiftmodule
do
	sed -e "s/-target arm64e-apple-ios13.0/-target arm64e-apple-macosx10.15/" \
		"$indirios/$filepath/arm64e.swiftinterface" >"$outdir/$filepath/arm64e.swiftinterface"
done