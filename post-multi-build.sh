#!/bin/sh
MODS=$(find . -name "*.geode" -type f -exec basename {} \; | sort -u)

if [ -n "$MODS" ] && [ ! -d "./build-all" ]; then
    mkdir build-all
fi

for mod in $MODS; do
    geode package new -o "./build-all/$mod" .

    PACKAGE_ARGS="./build-all/$mod"
    if [ -f "./build/$mod" ]; then
        PACKAGE_ARGS="$PACKAGE_ARGS ./build/$mod"
    fi
    if [ -f "./build-ios/$mod" ]; then
        PACKAGE_ARGS="$PACKAGE_ARGS ./build-ios/$mod"
    fi
    if [ -f "./build-android64/$mod" ]; then
        PACKAGE_ARGS="$PACKAGE_ARGS ./build-android64/$mod"
    fi
    if [ -f "./build-android32/$mod" ]; then
        PACKAGE_ARGS="$PACKAGE_ARGS ./build-android32/$mod"
    fi
    if [ -f "./build-win/$mod" ]; then
        PACKAGE_ARGS="$PACKAGE_ARGS ./build-win/$mod"
    fi

    geode package merge $PACKAGE_ARGS
done
