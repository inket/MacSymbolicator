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
