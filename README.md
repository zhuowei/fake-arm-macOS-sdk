Tool to create a fake macOS Arm SDK by Frankensteining a macOS and an iOS SDK together.

Usage:

```
bash makesdk.sh
clang -target arm64e-apple-macosx10.15.0 -isysroot macOSArm.sdk hello.c
```
