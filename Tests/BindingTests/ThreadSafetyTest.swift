//
//  ThreadSafetyTest.swift
//  BindingTests
//
//  Created by GitHub Copilot on 24/12/25.
//

import XCTest
import RxSwift
import RxCocoa

@testable import Binding

class ThreadSafetyTest: XCTestCase {
    
    func testBindableConcurrentReads() {
        struct Model {
            @Bindable var counter: Int
        }
        
        let model = Model(counter: 0)
        let iterations = 1000
        let expectation = self.expectation(description: "All reads complete")
        expectation.expectedFulfillmentCount = iterations
        
        // Perform concurrent reads
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            _ = model.counter // Read the value
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        // If no crash occurs, the test passes
    }
    
    func testBindableConcurrentWrites() {
        struct Model {
            @Bindable var counter: Int
        }
        
        var model = Model(counter: 0)
        let iterations = 1000
        let writeExpectation = self.expectation(description: "All writes complete")
        writeExpectation.expectedFulfillmentCount = iterations
        
        let observationExpectation = self.expectation(description: "Observed final state")
        let disposeBag = DisposeBag()
        
        var observedValues = [Int]()
        model.$counter.drive(onNext: { value in
            observedValues.append(value)
            if observedValues.count >= iterations {
                observationExpectation.fulfill()
            }
        }).disposed(by: disposeBag)
        
        // Perform concurrent writes
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            model.counter = index
            writeExpectation.fulfill()
        }
        
        wait(for: [writeExpectation, observationExpectation], timeout: 5.0)
        
        // Verify we received all emissions (BehaviorRelay guarantees thread-safe emission)
        XCTAssertGreaterThanOrEqual(observedValues.count, iterations,
                                   "Should observe at least \(iterations) values")
    }
    
    func testMutableConcurrentAccess() {
        struct Model {
            @Mutable var value: String
        }
        
        let model = Model(value: "initial")
        let iterations = 500
        let expectation = self.expectation(description: "Concurrent access complete")
        expectation.expectedFulfillmentCount = iterations * 2
        
        // Mix reads and writes
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            if index % 2 == 0 {
                _ = model.value // Read
            } else {
                model.$value.accept("value-\(index)") // Write through relay
            }
            expectation.fulfill()
        }
        
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            if index % 2 == 0 {
                model.$value.accept("direct-\(index)")
            } else {
                _ = model.$value.value
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        // Test passes if no crash occurs
    }
    
    func testViewActionConcurrentTriggers() {
        struct Model {
            @ViewAction var action: (Int) -> Void
        }
        
        let model = Model()
        let iterations = 1000
        let expectation = self.expectation(description: "All triggers received")
        
        var receivedCount = 0
        let queue = DispatchQueue(label: "test.queue")
        
        let disposeBag = DisposeBag()
        model.$action.emit(onNext: { _ in
            queue.sync {
                receivedCount += 1
                if receivedCount == iterations {
                    expectation.fulfill()
                }
            }
        }).disposed(by: disposeBag)
        
        // Trigger action concurrently
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            model.action(index)
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedCount, iterations, "Should receive all \(iterations) action triggers")
    }
    
    func testBindingContextConcurrentSubscriptions() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
            @Bindable var value: Int = 0
        }
        
        let context = Context()
        let iterations = 100
        let expectation = self.expectation(description: "All subscriptions added")
        expectation.expectedFulfillmentCount = iterations
        
        // Add subscriptions concurrently
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            context.binding {
                context.$value.drive(onNext: { _ in })
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        // Test passes if no crash occurs and all subscriptions are added
    }
    
    func testTwoWayBindingUnderConcurrentLoad() {
        @Mutable var value: String = "initial"
        let relay = BehaviorRelay<String>(value: "relay")
        
        let iterations = 500
        let expectation = self.expectation(description: "Concurrent binding operations complete")
        expectation.expectedFulfillmentCount = iterations
        
        let disposeBag = DisposeBag()
        
        // Simulate two-way binding behavior
        $value.bind(to: relay).disposed(by: disposeBag)
        relay.bind(to: $value).disposed(by: disposeBag)
        
        // Perform concurrent updates
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            if index % 2 == 0 {
                value = "mutable-\(index)"
            } else {
                relay.accept("relay-\(index)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify final state consistency
        XCTAssertEqual(value, relay.value, "Both values should be synchronized")
    }
}
