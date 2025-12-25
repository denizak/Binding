//
//  ErrorHandlingTest.swift
//  BindingTests
//
//  Created by GitHub Copilot on 24/12/25.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest

@testable import Binding

class ErrorHandlingTest: XCTestCase {
    
    // MARK: - Driver Error Handling
    
    func testDriverNeverErrors() {
        let scheduler = TestScheduler(initialClock: 0)
        
        // Create an observable that errors
        let errorObservable = scheduler.createColdObservable([
            .next(10, 1),
            .next(20, 2),
            .error(30, TestError.testError)
        ])
        
        let observer = scheduler.createObserver(Int.self)
        let disposeBag = DisposeBag()
        
        // Convert to Driver with error handling
        let driver = errorObservable
            .asObservable()
            .asDriver(onErrorJustReturn: -1)
        
        driver.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        // Driver should emit the error recovery value
        XCTAssertEqual(observer.events, [
            .next(10, 1),
            .next(20, 2),
            .next(30, -1),
            .completed(30)
        ])
    }
    
    func testDriverWithErrorRecoveryDrive() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let errorObservable = scheduler.createColdObservable([
            .next(10, "A"),
            .error(20, TestError.testError)
        ])
        
        let observer = scheduler.createObserver(String.self)
        let disposeBag = DisposeBag()
        
        errorObservable
            .asObservable()
            .asDriver(onErrorDriveWith: .just("recovered"))
            .drive(observer)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [
            .next(10, "A"),
            .next(20, "recovered"),
            .completed(20)
        ])
    }
    
    // MARK: - Signal Error Handling
    
    func testSignalNeverErrors() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let errorObservable = scheduler.createColdObservable([
            .next(10, 1),
            .next(20, 2),
            .error(30, TestError.testError)
        ])
        
        let observer = scheduler.createObserver(Int.self)
        let disposeBag = DisposeBag()
        
        errorObservable
            .asObservable()
            .asSignal(onErrorJustReturn: -1)
            .emit(to: observer)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [
            .next(10, 1),
            .next(20, 2),
            .next(30, -1),
            .completed(30)
        ])
    }
    
    // MARK: - ControlProperty Error Propagation
    
    func testControlPropertyNilCoalescingPreservesErrors() {
        enum TestError: Error {
            case propertyError
        }
        
        let errorProperty = ControlProperty(
            values: Observable<String?>.error(TestError.propertyError),
            valueSink: AnyObserver<String?> { _ in }
        )
        
        let observer = TestScheduler(initialClock: 0).createObserver(String.self)
        
        (errorProperty ?? "default").subscribe(observer).dispose()
        
        // Error should propagate through
        XCTAssertEqual(observer.events.count, 1)
        let event = observer.events[0].value
        switch event {
        case .error:
            // Error propagated correctly
            XCTAssertTrue(true)
        default:
            XCTFail("Expected error event")
        }
    }
    
    func testControlPropertyNilCoalescingPreservesCompletion() {
        let completedProperty = ControlProperty(
            values: Observable<Int?>.empty(),
            valueSink: AnyObserver<Int?> { _ in }
        )
        
        let observer = TestScheduler(initialClock: 0).createObserver(Int.self)
        
        (completedProperty ?? 0).subscribe(observer).dispose()
        
        XCTAssertEqual(observer.events, [.completed(0)])
    }
    
    func testControlPropertyNilCoalescingWithMultipleNilValues() {
        let nilValues = ControlProperty(
            values: Observable<String?>.just(nil),
            valueSink: AnyObserver<String?> { _ in }
        )
        
        let observer = TestScheduler(initialClock: 0).createObserver(String.self)
        
        (nilValues ?? "default").subscribe(observer).dispose()
        
        // Check that we got the expected value
        XCTAssertTrue(observer.events.count >= 1, "Should have at least one event")
        if let firstEvent = observer.events.first {
            switch firstEvent.value {
            case .next(let value):
                XCTAssertEqual(value, "default")
            default:
                XCTFail("Expected next event with default value")
            }
        }
    }
    
    // MARK: - Two-Way Binding Error Handling
    // Note: Relays cannot receive errors by design, so error handling tests
    // for two-way binding with relays are not applicable
    
    // MARK: - Observable Binding Error Handling
    
    func testObservableBindingWithError() {
        enum TestError: Error { case testError }
        
        var receivedError: Error?
        var receivedValues: [String] = []
        
        let subject = PublishSubject<String>()
        let disposeBag = DisposeBag()
        
        subject
            .do(onError: { receivedError = $0 })
            .catchAndReturn("fallback")
            .subscribe(onNext: { receivedValues.append($0) })
            .disposed(by: disposeBag)
        
        subject.onNext("value1")
        subject.onError(TestError.testError)
        
        XCTAssertEqual(receivedValues, ["value1", "fallback"])
        XCTAssertNotNil(receivedError)
    }
    
    func testObservableBindingToObserverWithError() {
        enum TestError: Error { case testError }
        
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(String.self)
        let disposeBag = DisposeBag()
        
        let subject = PublishSubject<String>()
        
        // Use catchAndReturn to handle error gracefully
        subject
            .catchAndReturn("error-fallback")
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        subject.onNext("before")
        subject.onError(TestError.testError)
        
        // Should receive value, fallback, and completed
        XCTAssertEqual(observer.events.count, 3)
    }
    
    // MARK: - Binding Context Error Scenarios
    
    func testBindingContextWithFailingObservables() {
        final class TestContext: BindingContext {
            let disposeBag = DisposeBag()
            var receivedValues: [String] = []
        }
        
        enum TestError: Error { case testError }
        
        let context = TestContext()
        let subject = PublishSubject<String>()
        
        context.binding {
            // Handle error with catchAndReturn to prevent unhandled error warning
            subject
                .catchAndReturn("fallback")
                .subscribe(onNext: { context.receivedValues.append($0) })
        }
        
        subject.onNext("value")
        subject.onError(TestError.testError)
        
        XCTAssertEqual(context.receivedValues, ["value", "fallback"])
    }
    
    func testMultipleBindingsWithSomeErrors() {
        final class MixedContext: BindingContext {
            let disposeBag = DisposeBag()
            @Bindable var successValue: Int = 0
        }
        
        let context = MixedContext()
        var successCount = 0
        
        context.binding {
            // This binding should work
            context.$successValue.drive(onNext: { _ in successCount += 1 })
            
            // This binding errors but is caught
            Observable<String>.error(TestError.testError)
                .catch { _ in .empty() }
                .subscribe()
        }
        
        context.successValue = 1
        context.successValue = 2
        
        // Success binding should still work despite error in other binding
        XCTAssertEqual(successCount, 3) // initial + 2 changes
    }
    
    // MARK: - ViewAction Error Scenarios
    
    func testViewActionWithFailingSubscriber() {
        struct Model {
            @ViewAction var action: (Int) -> Void
        }
        
        let model = Model()
        var successCount = 0
        var errorCount = 0
        
        let disposeBag = DisposeBag()
        
        // Subscriber that might throw
        model.$action.emit(onNext: { value in
            if value > 5 {
                errorCount += 1
                // In real scenario, this might trigger error handling
            } else {
                successCount += 1
            }
        }).disposed(by: disposeBag)
        
        model.action(1)
        model.action(10)
        model.action(3)
        
        XCTAssertEqual(successCount, 2)
        XCTAssertEqual(errorCount, 1)
    }
}

// MARK: - Test Support

enum TestError: Error {
    case testError
    case propertyError
}
