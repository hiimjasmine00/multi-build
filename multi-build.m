#import <Cocoa/Cocoa.h>

@interface TerminalWindowCreator : NSObject
- (void)withRectangle:(NSRect)rect andScript:(NSString*)script;
@end

@implementation TerminalWindowCreator
- (void)withRectangle:(NSRect)rect andScript:(NSString*)script {
    NSString* scriptCommand = [NSString stringWithFormat:
        @"tell application \"Terminal\"\n"
        "activate\n"
        "do script \"%@\"\n"
        "set bounds of front window to {%f, %f, %f, %f}\n"
        "end tell", script, rect.origin.x, rect.origin.y, rect.size.width + rect.origin.x, rect.size.height + rect.origin.y];
    
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:scriptCommand];
    NSDictionary* error = nil;
    if (![appleScript executeAndReturnError:&error]) NSLog(@"Error executing AppleScript script: %@", error);
}
@end

int main(int argc, const char* argv[]) {
    bool reconfigure = false;
    const char* source = NULL;
    const char* architectures = NULL;
    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], "--configure") == 0 || strcmp(argv[i], "-c") == 0) reconfigure = true;
        else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            printf("Usage: multi-build [options]\n");
            printf("Options:\n");
            printf("  -a, --architectures <arch>  Specify the architectures to build for macOS (Defaults to default)\n");
            printf("  -c, --configure             Force reconfiguration of the project (Defaults to false)\n");
            printf("  -h, --help                  Show this help message\n");
            printf("  -s, --source <source>       Specify the source directory to use (Defaults to current directory)\n");
            return 0;
        }
        else if (strcmp(argv[i], "--source") == 0 || strcmp(argv[i], "-s") == 0) {
            if (i + 1 < argc) {
                source = argv[i + 1];
                i++;
            }
        }
        else if (strcmp(argv[i], "--architectures") == 0 || strcmp(argv[i], "-a") == 0) {
            if (i + 1 < argc) {
                architectures = argv[i + 1];
                i++;
            }
        }
    }

    @autoreleasepool {
        // get the directory this app was launched from
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSString* currentDirectory = [fileManager currentDirectoryPath];
        bool hasWindows = !reconfigure && [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/build-win", currentDirectory]];
        bool hasAndroid64 = !reconfigure && [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/build-android64", currentDirectory]];
        bool hasAndroid32 = !reconfigure && [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/build-android32", currentDirectory]];
        bool hasMacOS = !reconfigure && [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/build", currentDirectory]];
        bool hasIOS = !reconfigure && [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/build-ios", currentDirectory]];

        NSRect screenRect = [[NSScreen mainScreen] frame];
        NSRect windowRect = [[NSScreen mainScreen] visibleFrame];
        NSSize size = NSMakeSize(windowRect.size.width / 3.0, windowRect.size.height / 2.0);

        CGFloat x1 = 0.0;
        CGFloat x2 = windowRect.size.width / 2.0 - size.width / 2.0;
        CGFloat x3 = windowRect.size.width - size.width;
        CGFloat y1 = screenRect.size.height - windowRect.size.height - windowRect.origin.y;
        CGFloat y2 = screenRect.size.height - size.height - windowRect.origin.y;

        NSString* sourceArg = source ? [NSString stringWithFormat:@"-S %s ", source] : @"";

        NSString* windows = [NSString stringWithFormat:@"cmake "
            "-B ./build-win "
            "%@"
            "-G Ninja "
            "-DCMAKE_BUILD_TYPE=RelWithDebInfo "
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON "
            "-DCMAKE_C_COMPILER=$LLVM_PATH/clang-cl "
            "-DCMAKE_CXX_COMPILER=$LLVM_PATH/clang-cl "
            "-DCMAKE_TOOLCHAIN_FILE=$HOME/clang-msvc-sdk/clang-cl-msvc.cmake "
            "-DHOST_ARCH=x86_64 "
            "-DGEODE_DONT_INSTALL_MODS=ON",
            sourceArg];
        NSString* android64 = [NSString stringWithFormat:@"cmake "
            "-B ./build-android64 "
            "%@"
            "-G Ninja "
            "-DCMAKE_BUILD_TYPE=RelWithDebInfo "
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON "
            "-DCMAKE_C_COMPILER=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang "
            "-DCMAKE_CXX_COMPILER=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang++ "
            "-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake "
            "-DANDROID_PLATFORM=android-23 "
            "-DANDROID_ABI=arm64-v8a "
            "-DGEODE_DONT_INSTALL_MODS=ON",
            sourceArg];
        NSString* android32 = [NSString stringWithFormat:@"cmake "
            "-B ./build-android32 "
            "%@"
            "-G Ninja "
            "-DCMAKE_BUILD_TYPE=RelWithDebInfo "
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON "
            "-DCMAKE_C_COMPILER=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang "
            "-DCMAKE_CXX_COMPILER=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang++ "
            "-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake "
            "-DANDROID_PLATFORM=android-23 "
            "-DANDROID_ABI=armeabi-v7a "
            "-DGEODE_DONT_INSTALL_MODS=ON",
            sourceArg];
        NSString* macos = [NSString stringWithFormat:@"cmake "
            "-B ./build "
            "%@"
            "-G Ninja "
            "-DCMAKE_BUILD_TYPE=RelWithDebInfo "
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON "
            "-DCMAKE_C_COMPILER=/usr/bin/clang "
            "-DCMAKE_CXX_COMPILER=/usr/bin/clang++ "
            "%@"
            "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15",
            sourceArg,
            architectures ? [NSString stringWithFormat:@"'-DCMAKE_OSX_ARCHITECTURES=%s' ", architectures] : @""];
        NSString* ios = [NSString stringWithFormat:@"cmake "
            "-B ./build-ios "
            "%@"
            "-G Ninja "
            "-DCMAKE_BUILD_TYPE=RelWithDebInfo "
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON "
            "-DCMAKE_C_COMPILER=/usr/bin/clang "
            "-DCMAKE_CXX_COMPILER=/usr/bin/clang++ "
            "-DCMAKE_SYSTEM_NAME=iOS "
            "-DGEODE_DONT_INSTALL_MODS=ON",
            sourceArg];

        TerminalWindowCreator* creator = [[TerminalWindowCreator alloc] init];

        [creator withRectangle:NSMakeRect(x1, y1, size.width, size.height) andScript:hasWindows ?
            [NSString stringWithFormat:@"cd %@ && cmake --build ./build-win --config RelWithDebInfo", currentDirectory] :
            [NSString stringWithFormat:@"cd %@ && %@ && cmake --build ./build-win --config RelWithDebInfo", currentDirectory, windows]];

        [creator withRectangle:NSMakeRect(x2, y1, size.width, size.height) andScript:hasAndroid64 ?
            [NSString stringWithFormat:@"cd %@ && cmake --build ./build-android64 --config RelWithDebInfo", currentDirectory] :
            [NSString stringWithFormat:@"cd %@ && %@ && cmake --build ./build-android64 --config RelWithDebInfo", currentDirectory, android64]];

        [creator withRectangle:NSMakeRect(x3, y1, size.width, size.height) andScript:hasAndroid32 ?
            [NSString stringWithFormat:@"cd %@ && cmake --build ./build-android32 --config RelWithDebInfo", currentDirectory] :
            [NSString stringWithFormat:@"cd %@ && %@ && cmake --build ./build-android32 --config RelWithDebInfo", currentDirectory, android32]];

        [creator withRectangle:NSMakeRect(x1, y2, size.width, size.height) andScript:hasMacOS ?
            [NSString stringWithFormat:@"cd %@ && cmake --build ./build --config RelWithDebInfo", currentDirectory] :
            [NSString stringWithFormat:@"cd %@ && %@ && cmake --build ./build --config RelWithDebInfo", currentDirectory, macos]];

        [creator withRectangle:NSMakeRect(x2, y2, size.width, size.height) andScript:hasIOS ?
            [NSString stringWithFormat:@"cd %@ && cmake --build ./build-ios --config RelWithDebInfo", currentDirectory] :
            [NSString stringWithFormat:@"cd %@ && %@ && cmake --build ./build-ios --config RelWithDebInfo", currentDirectory, ios]];

        [creator withRectangle:NSMakeRect(x3, y2, size.width, size.height) andScript:[NSString stringWithFormat:@"cd %@", currentDirectory]];
    }

    return 0;
}
