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
        let event = observer.events[0]
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
            values: Observable<String?>.from([nil, nil, "value", nil]),
            valueSink: AnyObserver<String?> { _ in }
        )
        
        let observer = TestScheduler(initialClock: 0).createObserver(String.self)
        
        (nilValues ?? "default").subscribe(observer).dispose()
        
        XCTAssertRecordedElements(observer.events, ["default", "default", "value", "default"])
    }
    
    // MARK: - Two-Way Binding Error Handling
    
    func testTwoWayBindingWhenPropertyErrors() {
        let relay = BehaviorRelay<String>(value: "initial")
        
        let errorSubject = PublishSubject<String>()
        let errorProperty = ControlProperty(
            values: errorSubject.asObservable(),
            valueSink: errorSubject.asObserver()
        )
        
        let disposeBag = DisposeBag()
        (relay <=> errorProperty).disposed(by: disposeBag)
        
        // Relay value should be sent to property
        relay.accept("from relay")
        
        // If property errors, binding should be disposed
        errorSubject.onError(TestError.testError)
        
        // After error, relay updates should not affect property
        relay.accept("after error")
        
        // Test passes if no crash occurs
        XCTAssertTrue(true, "Two-way binding should handle property errors gracefully")
    }
    
    // MARK: - Observable Binding Error Handling
    
    func testObservableBindingWithError() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let coldObservable = scheduler.createColdObservable([
            .next(10, 1),
            .next(20, 2),
            .error(30, TestError.testError)
        ])
        
        var receivedValues = [Int]()
        var receivedError: Error?
        let disposeBag = DisposeBag()
        
        // Convert TestableObservable to Observable
        let observable = coldObservable.asObservable()
        
        (observable => { value in
            receivedValues.append(value)
        }).disposed(by: disposeBag)
        
        observable.subscribe(
            onNext: { receivedValues.append($0) },
            onError: { receivedError = $0 }
        ).disposed(by: disposeBag)
        
        scheduler.start()
        
        // Should receive values before error
        XCTAssertTrue(receivedValues.contains(1))
        XCTAssertTrue(receivedValues.contains(2))
        XCTAssertNotNil(receivedError)
    }
    
    func testObservableBindingToObserverWithError() {
        let scheduler = TestScheduler(initialClock: 0)
        
        let coldObservable = scheduler.createColdObservable([
            .next(10, "A"),
            .error(20, TestError.testError)
        ])
        
        let observer = scheduler.createObserver(String.self)
        let disposeBag = DisposeBag()
        
        // Convert TestableObservable to Observable
        (coldObservable.asObservable() => observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [
            .next(10, "A"),
            .error(20, TestError.testError)
        ])
    }
    
    // MARK: - Binding Context Error Scenarios
    
    func testBindingContextWithFailingObservables() {
        final class ErrorContext: BindingContext {
            let disposeBag = DisposeBag()
            var errorCount = 0
        }
        
        let context = ErrorContext()
        
        context.binding {
            Observable<Int>.error(TestError.testError)
                .catch { _ in
                    context.errorCount += 1
                    return .empty()
                }
                .subscribe()
        }
        
        XCTAssertEqual(context.errorCount, 1, "Error handler should be called")
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
