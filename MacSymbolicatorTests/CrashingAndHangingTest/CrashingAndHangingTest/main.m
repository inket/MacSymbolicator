//
//  main.m
//  CrashingAndHangingTest
//

@import Foundation;
#import <stdlib.h>

#import "AnotherTarget/AnotherTarget-Swift.h"

@interface MyClass: NSObject
@end

@implementation MyClass

- (void)start {
    NSInteger r = 0;

    if (NSProcessInfo.processInfo.arguments.count > 1) {
        r = NSProcessInfo.processInfo.arguments[1].integerValue;
    } else {
        printf("%s\n", [@"usage:" cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("%s\n", [@"    `crashingAndHangingTest 0`: crashes in the main target" cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("%s\n", [@"    `crashingAndHangingTest 1`: crashes in a separate target (framework)" cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("%s\n", [@"    `crashingAndHangingTest 2`: hangs one thread (for generating samples via Activity Monitor)" cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("%s\n", [@"    `crashingAndHangingTest 3`: hangs 2 threads (for generating samples via Activity Monitor)" cStringUsingEncoding:NSUTF8StringEncoding]);
    }

    switch (r) {
        case 1:
            // Crash; pick up the crash report @ ~/Library/Logs/DiagnosticReports
            NSLog(@"crashing in AnotherTarget… get crash report @ ~/Library/Logs/DiagnosticReports");
            [self crashingInDifferentTargetMethod];
            break;

        case 2:
            // Hang on one thread, this should generate a short format sample when sampled via Activity Monitor where lines
            // will start with spaces
            NSLog(@"hanging…");
            [self hangingMethod];
            break;
        case 3:
            // Hang in 2 threads, this should generate a multithreaded format sample when sampled via Activity Monitor
            // where lines will start with "+"
            NSLog(@"background hanging…");
            [self backgroundHangingMethod];
            break;
        default:
            // Crash; pick up the crash report @ ~/Library/Logs/DiagnosticReports
            NSLog(@"crashing in main target… get crash report @ ~/Library/Logs/DiagnosticReports");
            [self crashingMethod];
            break;
    }
}

- (void)backgroundHangingMethod {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        sleep(3600);
    });

    [self hangingMethod]; // to stop it from exiting
}

- (void)hangingMethod {
    NSLock *lock = [[NSLock alloc] init];
    [lock lock];
    [lock lock];
}

- (void)crashingMethod {
    int* p = (int*)1;
    *p = 0;
}

- (void)crashingInDifferentTargetMethod {
    [CrashingClass crash];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[[MyClass alloc] init] start];
    }
    return 0;
}
