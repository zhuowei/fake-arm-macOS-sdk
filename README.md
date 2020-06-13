Tool to create a fake macOS Arm SDK by Frankensteining a macOS and an iOS SDK together.

Usage:

```
bash makesdk.sh
clang -target arm64-apple-macosx10.15.0 -isysroot macOSArm.sdk hello.c
swiftc -target arm64-apple-macosx10.15.0 -sdk macOSArm.sdk -v hello.swift
```

Thanks to @stroughtonsmith for discovering how to do this:

https://twitter.com/stroughtonsmith/status/807664599260688384
https://twitter.com/stroughtonsmith/status/1232104689069674496
https://twitter.com/stroughtonsmith/status/1270902332373585922
