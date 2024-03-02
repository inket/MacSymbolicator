//
//  StackFrameTests.swift
//  MacSymbolicatorTests
//

import Foundation
import XCTest
@testable import MacSymbolicator

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable line_length force_unwrapping

class StackFrameTests: XCTestCase {
    func testScanningStackFramesOfCrashReport() {
        // Mix and match many different ways to represent the fields of a stack frame then test parsing them
        let rawStackFrames = """
        Application Specific Backtrace 0:
        0   CoreFoundation                      0x00007ff813cb27b3 __exceptionPreprocess + 242
        1   libobjc.A.dylib                     0x00007ff813a12bc3 objc_exception_throw + 48
        2   CoreFoundation                      0x00007ff813cdb066 -[NSException raise] + 9
        3   CrashingTest                        0x000000010bbb1de3 CrashingTest + 15800
        4   iOSCrashingTest                     0x00000001028264bc 0x102820000 + 25788
        5   CrashingTest                        0x10bbb1e30 CrashingTest + 15900
        6   dyld                                0x000000011478451e start + 462

        Thread 0 Crashed:
        0  libswiftCore.dylib                       0x194444d7c _assertionFailure(_:_:file:line:flags:) + 312
        1  libswiftCore.dylib                       0x194444d7c _assertionFailure(_:_:file:line:flags:) + 312
        2  iOSCrashingTest                          0x00000001028264bd 0x102820000 + 25788
        3  iOSCrashingTest                          0x1028261ec 0x102820000 + 0x5d83
        4  CrashingTest                             0x000000010bbb1de3 CrashingTest + 0x2ab6
        5  CrashingTest                             0x000000010bbb1e30 CrashingTest + 15920
        6  CrashingTest                             0x10bbb1de3 0x10bbae000 + 15843
        7  CrashingTest                             0x10bbb1e30 0x10bbae000 + 15920
        8  iOSCrashingTest                          0x1028261ec iOSCrashingTest + 25070
        9  dyld                                     0x1b8cb4960 start + 2528
        """

        let crashingTestBinaryImage = BinaryImage(parsingLine: "0x10bbae000 -        0x10bbb1fff CrashingTest (*) <c6c06e5a-ed30-3361-a2c3-62ebe4a785dd> /Users/USER/Desktop/*/CrashingTest")!
        let iOSCrashingTestBinaryImage = BinaryImage(parsingLine: "0x102820000 -        0x102827fff iOSCrashingTest arm64  <216d68a5dfde3bbbab86d483d8410d37> /private/var/containers/Bundle/Application/8A7CD407-D4EF-47FB-AC0A-54ACC254AB58/iOSCrashingTest.app/iOSCrashingTest")!

        let binaryImageMap = BinaryImageMap(binaryImages: [crashingTestBinaryImage, iOSCrashingTestBinaryImage])
        let stackFrames = StackFrame.find(in: rawStackFrames, binaryImageMap: binaryImageMap)

        // 10 stack frames need symbolicating
        XCTAssertEqual(stackFrames.count, 10)

        XCTAssertEqual(
            stackFrames[0].line,
            "3   CrashingTest                        0x000000010bbb1de3 CrashingTest + 15800"
        )
        XCTAssertEqual(stackFrames[0].address, "0x000000010bbb1de3")
        XCTAssertEqual(stackFrames[0].byteOffset, "15800")
        XCTAssertEqual(stackFrames[0].readableByteOffset, "15800")
        XCTAssertEqual(stackFrames[0].binaryImage, crashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[1].line,
            "4   iOSCrashingTest                     0x00000001028264bc 0x102820000 + 25788"
        )
        XCTAssertEqual(stackFrames[1].address, "0x00000001028264bc")
        XCTAssertEqual(stackFrames[1].byteOffset, "25788")
        XCTAssertEqual(stackFrames[1].readableByteOffset, "25788")
        XCTAssertEqual(stackFrames[1].binaryImage, iOSCrashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[2].line,
            "5   CrashingTest                        0x10bbb1e30 CrashingTest + 15900"
        )
        XCTAssertEqual(stackFrames[2].address, "0x10bbb1e30")
        XCTAssertEqual(stackFrames[2].byteOffset, "15900")
        XCTAssertEqual(stackFrames[2].readableByteOffset, "15900")
        XCTAssertEqual(stackFrames[2].binaryImage, crashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[3].line,
            "2  iOSCrashingTest                          0x00000001028264bd 0x102820000 + 25788"
        )
        XCTAssertEqual(stackFrames[3].address, "0x00000001028264bd")
        XCTAssertEqual(stackFrames[3].byteOffset, "25788")
        XCTAssertEqual(stackFrames[3].readableByteOffset, "25788")
        XCTAssertEqual(stackFrames[3].binaryImage, iOSCrashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[4].line,
            "3  iOSCrashingTest                          0x1028261ec 0x102820000 + 0x5d83"
        )
        XCTAssertEqual(stackFrames[4].address, "0x1028261ec")
        XCTAssertEqual(stackFrames[4].byteOffset, "0x5d83")
        XCTAssertEqual(stackFrames[4].readableByteOffset, "23939")
        XCTAssertEqual(stackFrames[4].binaryImage, iOSCrashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[5].line,
            "4  CrashingTest                             0x000000010bbb1de3 CrashingTest + 0x2ab6"
        )
        XCTAssertEqual(stackFrames[5].address, "0x000000010bbb1de3")
        XCTAssertEqual(stackFrames[5].byteOffset, "0x2ab6")
        XCTAssertEqual(stackFrames[5].readableByteOffset, "10934")
        XCTAssertEqual(stackFrames[5].binaryImage, crashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[6].line,
            "5  CrashingTest                             0x000000010bbb1e30 CrashingTest + 15920"
        )
        XCTAssertEqual(stackFrames[6].address, "0x000000010bbb1e30")
        XCTAssertEqual(stackFrames[6].byteOffset, "15920")
        XCTAssertEqual(stackFrames[6].readableByteOffset, "15920")
        XCTAssertEqual(stackFrames[6].binaryImage, crashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[7].line,
            "6  CrashingTest                             0x10bbb1de3 0x10bbae000 + 15843"
        )
        XCTAssertEqual(stackFrames[7].address, "0x10bbb1de3")
        XCTAssertEqual(stackFrames[7].byteOffset, "15843")
        XCTAssertEqual(stackFrames[7].readableByteOffset, "15843")
        XCTAssertEqual(stackFrames[7].binaryImage, crashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[8].line,
            "7  CrashingTest                             0x10bbb1e30 0x10bbae000 + 15920"
        )
        XCTAssertEqual(stackFrames[8].address, "0x10bbb1e30")
        XCTAssertEqual(stackFrames[8].byteOffset, "15920")
        XCTAssertEqual(stackFrames[8].readableByteOffset, "15920")
        XCTAssertEqual(stackFrames[8].binaryImage, crashingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[9].line,
            "8  iOSCrashingTest                          0x1028261ec iOSCrashingTest + 25070"
        )
        XCTAssertEqual(stackFrames[9].address, "0x1028261ec")
        XCTAssertEqual(stackFrames[9].byteOffset, "25070")
        XCTAssertEqual(stackFrames[9].readableByteOffset, "25070")
        XCTAssertEqual(stackFrames[9].binaryImage, iOSCrashingTestBinaryImage)
    }

    func testReplacingStackFrameOfCrashReport() {
        let crashingTestBinaryImage = BinaryImage(parsingLine: "0x10bbae000 -        0x10bbb1fff CrashingTest (*) <c6c06e5a-ed30-3361-a2c3-62ebe4a785dd> /Users/USER/Desktop/*/CrashingTest")!
        let binaryImageMap = BinaryImageMap(binaryImages: [crashingTestBinaryImage])

        var stackFrame = StackFrame(
            parsingLine: "3   CrashingTest                        0x000000010bbb1de3 CrashingTest + 15800",
            binaryImageMap: binaryImageMap
        )!
        stackFrame.replace(withResult: "-[MyClass crashingMethod] (in CrashingTest) (main.m:20)")
        XCTAssertEqual(
            stackFrame.symbolicatedLine,
            "3   CrashingTest                        0x000000010bbb1de3 -[MyClass crashingMethod] (in CrashingTest) (main.m:20) + 15800"
        )

        stackFrame = StackFrame(
            parsingLine: "6  CrashingTest                             0x10bbb1de3 0x10bbae000 + 15843",
            binaryImageMap: binaryImageMap
        )!
        stackFrame.replace(withResult: "main (in CrashingTest) (main.m:30)")
        XCTAssertEqual(
            stackFrame.symbolicatedLine,
            "6  CrashingTest                             0x10bbb1de3 main (in CrashingTest) (main.m:30) + 15843"
        )
    }

    func testScanningStackFramesOfSampleReport() {
        let rawStackFrames = """
        7847 Thread_12789423   DispatchQueue_1: com.apple.main-thread  (serial)
        + 7847 start  (in dyld) + 462  [0x10ec9251e]
        +   7847 ???  (in MultiTargetHangingTest)  load address 0x106637000 + 0x3e80  [0x10663ae80]
        +     7847 ???  (in MultiTargetHangingTest)  load address 0x106637000 + 23029  [0x10663ae3f]
        +       7847 _pthread_mutex_firstfit_lock_slow  (in libsystem_pthread.dylib) + 205  [0x7ff813b6bcbb]
        +         7847 _pthread_mutex_firstfit_lock_wait  (in libsystem_pthread.dylib) + 76  [0x7ff813b6de7e]
        +           7847 __psynch_mutexwait  (in libsystem_kernel.dylib) + 10  [0x7ff813b35bd2]
        7847 Thread_12789435   DispatchQueue_13: com.apple.root.default-qos  (concurrent)
          7847 start_wqthread  (in libsystem_pthread.dylib) + 15  [0x7ff813b6bf57]
            7847 _pthread_wqthread  (in libsystem_pthread.dylib) + 256  [0x7ff813b6cf8a]
              7847 _dispatch_worker_thread2  (in libdispatch.dylib) + 160  [0x7ff8139c925c]
                7847 _dispatch_root_queue_drain  (in libdispatch.dylib) + 343  [0x7ff8139c8ac2]
                  7847 _dispatch_queue_override_invoke  (in libdispatch.dylib) + 787  [0x7ff8139bb9fc]
                    7847 _dispatch_client_callout  (in libdispatch.dylib) + 8  [0x7ff8139b9317]
                      7847 _dispatch_call_block_and_release  (in libdispatch.dylib) + 12  [0x7ff8139b80cc]
                        7847 ???  (in AnotherTarget)  load address 0x106775000 + 0x3589  [0x106778589]
                          7847 sleep  (in libsystem_c.dylib) + 41  [0x7ff813a556e8]
                            7847 nanosleep  (in libsystem_c.dylib) + 196  [0x7ff813a4a863]
                              7847 __semwait_signal  (in libsystem_kernel.dylib) + 10  [0x7ff813b362be]
        """

        let multiTargetHangingTestBinaryImage = BinaryImage(parsingLine: "0x106637000 -        0x10663afff +MultiTargetHangingTest (0) <1959A738-AA4F-31D4-9D7F-F79EF1A6B762> /Users/*/Desktop/*/MultiTargetHangingTest")!
        let anotherTargetBinaryImage = BinaryImage(parsingLine: "0x106775000 -        0x106778fff +jp.mahdi.AnotherTarget (1.0 - 1) <96657B6A-9D77-3CD0-B468-54D881F66AC5> /Users/*/Desktop/*/AnotherTarget.framework/Versions/A/AnotherTarget")!

        let binaryImageMap = BinaryImageMap(binaryImages: [
            multiTargetHangingTestBinaryImage,
            anotherTargetBinaryImage
        ])
        let stackFrames = StackFrame.find(in: rawStackFrames, binaryImageMap: binaryImageMap)

        // 3 stack frames need symbolicating
        XCTAssertEqual(stackFrames.count, 3)

        XCTAssertEqual(
            stackFrames[0].line,
            "???  (in MultiTargetHangingTest)  load address 0x106637000 + 0x3e80  [0x10663ae80]"
        )
        XCTAssertEqual(stackFrames[0].address, "0x10663ae80")
        XCTAssertEqual(stackFrames[0].byteOffset, "0x3e80")
        XCTAssertEqual(stackFrames[0].readableByteOffset, "16000")
        XCTAssertEqual(stackFrames[0].binaryImage, multiTargetHangingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[1].line,
            "???  (in MultiTargetHangingTest)  load address 0x106637000 + 23029  [0x10663ae3f]"
        )
        XCTAssertEqual(stackFrames[1].address, "0x10663ae3f")
        XCTAssertEqual(stackFrames[1].byteOffset, "23029")
        XCTAssertEqual(stackFrames[1].readableByteOffset, "23029")
        XCTAssertEqual(stackFrames[1].binaryImage, multiTargetHangingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[2].line,
            "???  (in AnotherTarget)  load address 0x106775000 + 0x3589  [0x106778589]"
        )
        XCTAssertEqual(stackFrames[2].address, "0x106778589")
        XCTAssertEqual(stackFrames[2].byteOffset, "0x3589")
        XCTAssertEqual(stackFrames[2].readableByteOffset, "13705")
        XCTAssertEqual(stackFrames[2].binaryImage, anotherTargetBinaryImage)
    }

    func testReplacingStackFrameOfSampleReport() {
        let multiTargetHangingTestBinaryImage = BinaryImage(parsingLine: "0x106637000 -        0x10663afff +MultiTargetHangingTest (0) <1959A738-AA4F-31D4-9D7F-F79EF1A6B762> /Users/*/Desktop/*/MultiTargetHangingTest")!
        let anotherTargetBinaryImage = BinaryImage(parsingLine: "0x106775000 -        0x106778fff +jp.mahdi.AnotherTarget (1.0 - 1) <96657B6A-9D77-3CD0-B468-54D881F66AC5> /Users/*/Desktop/*/AnotherTarget.framework/Versions/A/AnotherTarget")!

        let binaryImageMap = BinaryImageMap(binaryImages: [
            multiTargetHangingTestBinaryImage,
            anotherTargetBinaryImage
        ])

        var stackFrame = StackFrame(
            parsingLine: "???  (in MultiTargetHangingTest)  load address 0x106637000 + 0x3e3f  [0x10663ae3f]",
            binaryImageMap: binaryImageMap
        )!
        stackFrame.replace(withResult: "-[MyClass hangingMethod] (in MultiTargetHangingTest) (main.m:24)")
        XCTAssertEqual(
            stackFrame.symbolicatedLine,
            "-[MyClass hangingMethod] (in MultiTargetHangingTest) (main.m:24) + 15935  [0x10663ae3f]"
        )

        stackFrame = StackFrame(
            parsingLine: "???  (in AnotherTarget)  load address 0x106775000 + 0x3589  [0x106778589]",
            binaryImageMap: binaryImageMap
        )!
        stackFrame.replace(withResult: "thunk for @escaping @callee_guaranteed () -> () (in AnotherTarget) (<compiler-generated>:0)")
        XCTAssertEqual(
            stackFrame.symbolicatedLine,
            "thunk for @escaping @callee_guaranteed () -> () (in AnotherTarget) (<compiler-generated>:0) + 13705  [0x106778589]"
        )
    }

    func testScanningStackFramesOfSpindumpReport() {
        let rawStackFrames = """
        Thread 0xc326af    DispatchQueue "com.apple.main-thread"(1)    1000 samples (1-1000)    priority 31 (base 31)
        1000  start + 462 (dyld + 21790) [0x10ec9251e]
          1000  ??? (MultiTargetHangingTest + 16000) [0x10663ae80]
            1000  ??? (MultiTargetHangingTest + 15935) [0x10663ae3f]
              1000  _pthread_mutex_firstfit_lock_slow + 205 (libsystem_pthread.dylib + 7355) [0x7ff813b6bcbb]
                1000  __psynch_mutexwait + 10 (libsystem_kernel.dylib + 15314) [0x7ff813b35bd2]
                 *1000  psynch_mtxcontinue + 0 (pthread + 11285) [0xffffff8003753c15] (blocked by turnstile waiting for this thread)

        Thread 0xc326bb    DispatchQueue "com.apple.root.default-qos"(13)    1000 samples (1-1000)    priority 31 (base 31)
        1000  start_wqthread + 15 (libsystem_pthread.dylib + 8023) [0x7ff813b6bf57]
          1000  _pthread_wqthread + 256 (libsystem_pthread.dylib + 12170) [0x7ff813b6cf8a]
            1000  _dispatch_worker_thread2 + 160 (libdispatch.dylib + 78428) [0x7ff8139c925c]
              1000  _dispatch_root_queue_drain + 343 (libdispatch.dylib + 76482) [0x7ff8139c8ac2]
                1000  _dispatch_queue_override_invoke + 787 (libdispatch.dylib + 23036) [0x7ff8139bb9fc]
                  1000  _dispatch_client_callout + 8 (libdispatch.dylib + 13079) [0x7ff8139b9317]
                    1000  _dispatch_call_block_and_release + 12 (libdispatch.dylib + 8396) [0x7ff8139b80cc]
                      1000  ??? (AnotherTarget + 13705) [0x106778589]
                        1000  sleep + 41 (libsystem_c.dylib + 112360) [0x7ff813a556e8]
                          1000  __semwait_signal + 10 (libsystem_kernel.dylib + 17086) [0x7ff813b362be]
                           *1000  ??? (kernel + 696640) [0xffffff80002ba140]
        """

        let multiTargetHangingTestBinaryImage = BinaryImage(parsingLine: "0x106637000 -        0x106642fff  MultiTargetHangingTest (0)           <1959A738-AA4F-31D4-9D7F-F79EF1A6B762>  /Users/inket/Desktop/Payload/MultiTargetHangingTest")!
        let anotherTargetBinaryImage = BinaryImage(parsingLine: "0x106775000 -        0x106780fff  jp.mahdi.AnotherTarget 1.0 (1)       <96657B6A-9D77-3CD0-B468-54D881F66AC5>  /Users/inket/Desktop/Payload/AnotherTarget.framework/Versions/A/AnotherTarget")!
        let kernelBinaryImage = BinaryImage(parsingLine: "*0xffffff8000210000 - 0xffffff8000c0ffff  kernel (8020.121.3)                  <3C587984-4004-3C76-8ADF-997822977184>  /System/Library/Kernels/kernel")!

        let binaryImageMap = BinaryImageMap(binaryImages: [
            multiTargetHangingTestBinaryImage,
            anotherTargetBinaryImage,
            kernelBinaryImage
        ])
        let stackFrames = StackFrame.find(in: rawStackFrames, binaryImageMap: binaryImageMap)

        // 4 stack frames need symbolicating
        XCTAssertEqual(stackFrames.count, 4)

        XCTAssertEqual(
            stackFrames[0].line,
            "  1000  ??? (MultiTargetHangingTest + 16000) [0x10663ae80]"
        )
        XCTAssertEqual(stackFrames[0].address, "0x10663ae80")
        XCTAssertEqual(stackFrames[0].byteOffset, "16000")
        XCTAssertEqual(stackFrames[0].readableByteOffset, "16000")
        XCTAssertEqual(stackFrames[0].binaryImage, multiTargetHangingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[1].line,
            "    1000  ??? (MultiTargetHangingTest + 15935) [0x10663ae3f]"
        )
        XCTAssertEqual(stackFrames[1].address, "0x10663ae3f")
        XCTAssertEqual(stackFrames[1].byteOffset, "15935")
        XCTAssertEqual(stackFrames[1].readableByteOffset, "15935")
        XCTAssertEqual(stackFrames[1].binaryImage, multiTargetHangingTestBinaryImage)

        XCTAssertEqual(
            stackFrames[2].line,
            "              1000  ??? (AnotherTarget + 13705) [0x106778589]"
        )
        XCTAssertEqual(stackFrames[2].address, "0x106778589")
        XCTAssertEqual(stackFrames[2].byteOffset, "13705")
        XCTAssertEqual(stackFrames[2].readableByteOffset, "13705")
        XCTAssertEqual(stackFrames[2].binaryImage, anotherTargetBinaryImage)

        XCTAssertEqual(
            stackFrames[3].line,
            "                   *1000  ??? (kernel + 696640) [0xffffff80002ba140]"
        )
        XCTAssertEqual(stackFrames[3].address, "0xffffff80002ba140")
        XCTAssertEqual(stackFrames[3].byteOffset, "696640")
        XCTAssertEqual(stackFrames[3].readableByteOffset, "696640")
        XCTAssertEqual(stackFrames[3].binaryImage, kernelBinaryImage)
    }

    func testReplacingStackFrameOfSpindumpReport() {
        let multiTargetHangingTestBinaryImage = BinaryImage(parsingLine: "0x106637000 -        0x106642fff  MultiTargetHangingTest (0)           <1959A738-AA4F-31D4-9D7F-F79EF1A6B762>  /Users/inket/Desktop/Payload/MultiTargetHangingTest")!
        let anotherTargetBinaryImage = BinaryImage(parsingLine: "0x106775000 -        0x106780fff  jp.mahdi.AnotherTarget 1.0 (1)       <96657B6A-9D77-3CD0-B468-54D881F66AC5>  /Users/inket/Desktop/Payload/AnotherTarget.framework/Versions/A/AnotherTarget")!

        let binaryImageMap = BinaryImageMap(binaryImages: [
            multiTargetHangingTestBinaryImage,
            anotherTargetBinaryImage
        ])

        var stackFrame = StackFrame(
            parsingLine: "    1000  ??? (MultiTargetHangingTest + 15935) [0x10663ae3f]",
            binaryImageMap: binaryImageMap
        )!
        stackFrame.replace(withResult: "-[MyClass hangingMethod] (in MultiTargetHangingTest) (main.m:24)")
        XCTAssertEqual(
            stackFrame.symbolicatedLine,
            "    1000  -[MyClass hangingMethod] (in MultiTargetHangingTest) (main.m:24) + 15935  [0x10663ae3f]"
        )

        stackFrame = StackFrame(
            parsingLine: "              1000  ??? (AnotherTarget + 13705) [0x106778589]",
            binaryImageMap: binaryImageMap
        )!
        stackFrame.replace(withResult: "thunk for @escaping @callee_guaranteed () -> () (in AnotherTarget) (<compiler-generated>:0)")
        XCTAssertEqual(
            stackFrame.symbolicatedLine,
            "              1000  thunk for @escaping @callee_guaranteed () -> () (in AnotherTarget) (<compiler-generated>:0) + 13705  [0x106778589]"
        )
    }

}
