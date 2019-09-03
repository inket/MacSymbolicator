//
//  main.m
//  CrashingAndHangingTest
//

@import Foundation;
#import <stdlib.h>

@interface MyClass: NSObject
@end

@implementation MyClass

- (void)start {
    int r = arc4random_uniform(3);
    if (r == 1) {
        // Hang on one thread, this should generate a short format sample when sampled via Activity Monitor where lines
        // will start with spaces
        NSLog(@"hanging…");
        [self hangingMethod];
    } else if (r == 2) {
        // Hang in 2 threads, this should generate a multithreaded format sample when sampled via Activity Monitor
        // where lines will start with "+"
        NSLog(@"background hanging…");
        [self backgroundHangingMethod];
    } else {
        // Crash; pick up the crash report @ ~/Library/Logs/DiagnosticReports
        NSLog(@"crashing…");
        [self crashingMethod];
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

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[[MyClass alloc] init] start];
    }
    return 0;
}
