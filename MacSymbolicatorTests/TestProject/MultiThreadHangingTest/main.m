//
//  main.m
//  MultiThreadHangingTest
//

@import Foundation;

@interface MyClass: NSObject
@end

@implementation MyClass

- (void)start {
    // Hang in 2 threads, this should generate a multithreaded format sample when sampled via Activity Monitor
    // where lines will start with "+"
    NSLog(@"background hanging… sample this process via Activity Monitor");
    [self backgroundHangingMethod];
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

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[[MyClass alloc] init] start];
    }
    return 0;
}
