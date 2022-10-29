//
//  main.m
//  CrashingInAnotherTargetTest
//

@import Foundation;

#import "AnotherTarget/AnotherTarget-Swift.h"

@interface MyClass: NSObject
@end

@implementation MyClass

- (void)start {
    // Crash; pick up the crash report @ ~/Library/Logs/DiagnosticReports
    NSLog(@"crashing in AnotherTarget… get crash report @ ~/Library/Logs/DiagnosticReports");
    [self crashingInDifferentTargetMethod];
}

- (void)crashingInDifferentTargetMethod {
    [CrashingClass crash];
}

@end

void uncaughtException(NSException *exception) {}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSSetUncaughtExceptionHandler(&uncaughtException);
        [[[MyClass alloc] init] start];
    }
    return 0;
}
