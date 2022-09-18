//
//  main.m
//  MultiTargetHangingTest
//

@import Foundation;
#import "AnotherTarget/AnotherTarget-Swift.h"

@interface MyClass: NSObject
@end

@implementation MyClass

- (void)start {
    NSLog(@"Multi-target hanging… sample/spindump this process using Activity Monitor");
    [HangingClass hang];
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
