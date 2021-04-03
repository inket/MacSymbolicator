//
//  main.m
//  SingleThreadHangingTest
//

@import Foundation;

@interface MyClass: NSObject
@end

@implementation MyClass

- (void)start {
    // Hang on one thread, this should generate a short format sample when sampled via Activity Monitor where lines
    // will start with spaces
    NSLog(@"hanging… sample this process via Activity Monitor");
    [self hangingMethod];
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
