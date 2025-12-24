//
//  ResultBuilderTest.swift
//  BindingTests
//
//  Created by GitHub Copilot on 24/12/25.
//

import XCTest
import RxSwift

@testable import Binding

class ResultBuilderTest: XCTestCase {
    
    func testResultBuilderWithConditionalBinding() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        var executionCount = 0
        let shouldBind = true
        
        context.binding {
            Observable.just(1).subscribe(onNext: { _ in executionCount += 1 })
            
            if shouldBind {
                Observable.just(2).subscribe(onNext: { _ in executionCount += 1 })
            }
        }
        
        XCTAssertEqual(executionCount, 2, "Both subscriptions should execute with condition true")
    }
    
    func testResultBuilderWithConditionalBindingFalse() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        var executionCount = 0
        let shouldBind = false
        
        context.binding {
            Observable.just(1).subscribe(onNext: { _ in executionCount += 1 })
            
            if shouldBind {
                Observable.just(2).subscribe(onNext: { _ in executionCount += 1 })
            }
        }
        
        XCTAssertEqual(executionCount, 1, "Only first subscription should execute with condition false")
    }
    
    func testResultBuilderWithIfElse() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        var value = ""
        let useFirst = true
        
        context.binding {
            if useFirst {
                Observable.just("first").subscribe(onNext: { value = $0 })
            } else {
                Observable.just("second").subscribe(onNext: { value = $0 })
            }
        }
        
        XCTAssertEqual(value, "first", "First branch should execute")
    }
    
    func testResultBuilderWithIfElseSecondBranch() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        var value = ""
        let useFirst = false
        
        context.binding {
            if useFirst {
                Observable.just("first").subscribe(onNext: { value = $0 })
            } else {
                Observable.just("second").subscribe(onNext: { value = $0 })
            }
        }
        
        XCTAssertEqual(value, "second", "Second branch should execute")
    }
    
    func testResultBuilderWithLoop() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        var executionCount = 0
        let items = [1, 2, 3, 4, 5]
        
        context.binding {
            for item in items {
                Observable.just(item).subscribe(onNext: { _ in executionCount += 1 })
            }
        }
        
        XCTAssertEqual(executionCount, 5, "All loop iterations should create subscriptions")
    }
    
    func testResultBuilderWithEmptyLoop() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        var executionCount = 0
        let items: [Int] = []
        
        context.binding {
            for item in items {
                Observable.just(item).subscribe(onNext: { _ in executionCount += 1 })
            }
            
            Observable.just(1).subscribe(onNext: { _ in executionCount += 1 })
        }
        
        XCTAssertEqual(executionCount, 1, "Only the subscription after empty loop should execute")
    }
    
    func testResultBuilderWithComplexNesting() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        var results = [String]()
        let shouldIncludeOptional = true
        let items = ["A", "B"]
        
        context.binding {
            Observable.just("start").subscribe(onNext: { results.append($0) })
            
            if shouldIncludeOptional {
                for item in items {
                    Observable.just(item).subscribe(onNext: { results.append($0) })
                }
            }
            
            Observable.just("end").subscribe(onNext: { results.append($0) })
        }
        
        XCTAssertEqual(results, ["start", "A", "B", "end"], "Complex nesting should preserve order")
    }
}
