//
//  CompilationTest.swift
//  BindingTests
//
//  Created by GitHub Copilot on 24/12/25.
//

import XCTest
import RxSwift
import RxCocoa
@testable import Binding

/// This test ensures the API compiles correctly
class CompilationTest: XCTestCase {
    
    func testAllPropertyWrappersCompile() {
        struct TestModel {
            @Bindable var bindableValue: String = "test"
            @Mutable var mutableValue: Int = 42
            @ViewAction var action: (String) -> Void
            @ViewAction.NoParam var noParamAction: () -> Void
        }
        
        let model = TestModel()
        
        // Verify all types are accessible
        XCTAssertEqual(model.bindableValue, "test")
        XCTAssertEqual(model.mutableValue, 42)
        
        // Verify projected values are correct types
        _ = model.$bindableValue as Driver<String>
        _ = model.$mutableValue as BehaviorRelay<Int>
        _ = model.$action as Signal<String>
        _ = model.$noParamAction as Signal<Void>
    }
    
    func testSendableConformance() {
        // If this compiles, Sendable conformance is working
        @Bindable var value1: Int = 0
        @Mutable var value2: String = ""
        @ViewAction var action1: (Int) -> Void
        @ViewAction.NoParam var action2: () -> Void
        
        // Access to silence warnings
        _ = value1
        _ = value2
        _ = action1
        _ = action2
    }
}
