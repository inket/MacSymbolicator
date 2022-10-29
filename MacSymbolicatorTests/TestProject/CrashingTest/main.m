//
//  main.m
//  CrashingTest
//

@import Foundation;

@interface MyClass: NSObject
@end

@implementation MyClass

- (void)start {
    // Crash; pick up the crash report @ ~/Library/Logs/DiagnosticReports
    NSLog(@"crashing in main target… get crash report @ ~/Library/Logs/DiagnosticReports");
    [self crashingMethod];
}

- (void)crashingMethod {
    [[[NSException alloc] initWithName:@"Crash" reason:nil userInfo:nil] raise];
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
