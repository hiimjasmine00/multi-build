# Multi-Build
A tool for building a project for multiple platforms in parallel.\
It currently doesn't have customization, but it will be added in the future.

## About
I primarily created this tool to build [Geode](https://github.com/geode-sdk) mods for multiple platforms in parallel, so I wouldn't have to go on GitHub to play what the Geode developers call "CI golf".\
It currently only supports macOS, but Windows and Linux versions might be added with limited functionality, since I haven't found a way to cross-compile macOS and iOS projects on Windows or Linux.

## `post-multi-build.sh`
This is a script that can be run after the build process is complete, specifically for Geode mods.\
It takes Geode mod files and combines them into a single multi-platform mod file.

## Usage
```
$ multi-build --help
Usage: multi-build [options]
Options:
  -c, --configure        Force reconfiguration of the project (Defaults to false)
  -h, --help             Show this help message
  -s, --source <source>  Specify the source directory to use (Defaults to current directory)
```
