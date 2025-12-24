//
//  EdgeCaseTest.swift
//  BindingTests
//
//  Created by GitHub Copilot on 24/12/25.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest

@testable import Binding

class EdgeCaseTest: XCTestCase {
    
    // MARK: - Optional Value Tests
    
    func testBindableWithOptionalValue() {
        struct Model {
            @Bindable var optionalText: String?
        }
        
        var model = Model(optionalText: nil)
        
        let observer = TestScheduler(initialClock: 0).createObserver(String?.self)
        let disposeBag = DisposeBag()
        model.$optionalText.drive(observer).disposed(by: disposeBag)
        
        model.optionalText = "Hello"
        model.optionalText = nil
        model.optionalText = "World"
        
        XCTAssertRecordedElements(observer.events, [nil, "Hello", nil, "World"])
    }
    
    func testMutableWithOptionalValue() {
        struct Model {
            @Mutable var optionalValue: Int?
        }
        
        let model = Model(optionalValue: nil)
        
        let observer = TestScheduler(initialClock: 0).createObserver(Int?.self)
        let disposeBag = DisposeBag()
        model.$optionalValue.bind(to: observer).disposed(by: disposeBag)
        
        model.$optionalValue.accept(42)
        model.$optionalValue.accept(nil)
        model.$optionalValue.accept(99)
        
        XCTAssertRecordedElements(observer.events, [nil, 42, nil, 99])
    }
    
    // MARK: - Complex Type Tests
    
    func testMutableWithStructType() {
        struct User {
            let name: String
            let age: Int
        }
        
        struct Model {
            @Mutable var user: User
        }
        
        let initialUser = User(name: "Alice", age: 25)
        let model = Model(user: initialUser)
        
        var capturedUsers = [User]()
        let disposeBag = DisposeBag()
        model.$user.subscribe(onNext: { capturedUsers.append($0) }).disposed(by: disposeBag)
        
        let newUser = User(name: "Bob", age: 30)
        model.$user.accept(newUser)
        
        XCTAssertEqual(capturedUsers.count, 2)
        XCTAssertEqual(capturedUsers[0].name, "Alice")
        XCTAssertEqual(capturedUsers[1].name, "Bob")
    }
    
    func testMutableWithArrayType() {
        struct Model {
            @Mutable var items: [String]
        }
        
        let model = Model(items: ["A"])
        
        var capturedArrays = [[String]]()
        let disposeBag = DisposeBag()
        model.$items.subscribe(onNext: { capturedArrays.append($0) }).disposed(by: disposeBag)
        
        model.$items.accept(["A", "B"])
        model.$items.accept([])
        model.$items.accept(["X", "Y", "Z"])
        
        XCTAssertEqual(capturedArrays.count, 4)
        XCTAssertEqual(capturedArrays[0], ["A"])
        XCTAssertEqual(capturedArrays[1], ["A", "B"])
        XCTAssertEqual(capturedArrays[2], [])
        XCTAssertEqual(capturedArrays[3], ["X", "Y", "Z"])
    }
    
    func testMutableWithDictionaryType() {
        struct Model {
            @Mutable var settings: [String: Bool]
        }
        
        let model = Model(settings: ["darkMode": false])
        
        var capturedDicts = [[String: Bool]]()
        let disposeBag = DisposeBag()
        model.$settings.subscribe(onNext: { capturedDicts.append($0) }).disposed(by: disposeBag)
        
        model.$settings.accept(["darkMode": true, "notifications": true])
        
        XCTAssertEqual(capturedDicts.count, 2)
        XCTAssertEqual(capturedDicts[0], ["darkMode": false])
        XCTAssertEqual(capturedDicts[1], ["darkMode": true, "notifications": true])
    }
    
    // MARK: - Multiple Subscriber Tests
    
    func testMultipleSubscribersToSameBindable() {
        struct Model {
            @Bindable var value: Int
        }
        
        var model = Model(value: 0)
        
        let observer1 = TestScheduler(initialClock: 0).createObserver(Int.self)
        let observer2 = TestScheduler(initialClock: 0).createObserver(Int.self)
        let observer3 = TestScheduler(initialClock: 0).createObserver(Int.self)
        
        let disposeBag = DisposeBag()
        model.$value.drive(observer1).disposed(by: disposeBag)
        model.$value.drive(observer2).disposed(by: disposeBag)
        model.$value.drive(observer3).disposed(by: disposeBag)
        
        model.value = 10
        model.value = 20
        model.value = 30
        
        // All observers should receive all values
        XCTAssertRecordedElements(observer1.events, [0, 10, 20, 30])
        XCTAssertRecordedElements(observer2.events, [0, 10, 20, 30])
        XCTAssertRecordedElements(observer3.events, [0, 10, 20, 30])
    }
    
    func testMultipleSubscribersToSameMutable() {
        struct Model {
            @Mutable var value: String
        }
        
        let model = Model(value: "initial")
        
        var values1 = [String]()
        var values2 = [String]()
        var values3 = [String]()
        
        let disposeBag = DisposeBag()
        model.$value.subscribe(onNext: { values1.append($0) }).disposed(by: disposeBag)
        model.$value.subscribe(onNext: { values2.append($0) }).disposed(by: disposeBag)
        model.$value.subscribe(onNext: { values3.append($0) }).disposed(by: disposeBag)
        
        model.$value.accept("first")
        model.$value.accept("second")
        
        XCTAssertEqual(values1, ["initial", "first", "second"])
        XCTAssertEqual(values2, ["initial", "first", "second"])
        XCTAssertEqual(values3, ["initial", "first", "second"])
    }
    
    // MARK: - ViewAction Edge Cases
    
    func testViewActionCalledBeforeSubscription() {
        struct Model {
            @ViewAction var action: (String) -> Void
        }
        
        let model = Model()
        
        // Trigger action before any subscription
        model.action("before")
        
        var capturedValues = [String]()
        let disposeBag = DisposeBag()
        model.$action.emit(onNext: { capturedValues.append($0) }).disposed(by: disposeBag)
        
        // Trigger after subscription
        model.action("after1")
        model.action("after2")
        
        // Should only capture values after subscription (Signal doesn't buffer)
        XCTAssertEqual(capturedValues, ["after1", "after2"])
    }
    
    func testViewActionMultipleSubscribers() {
        struct Model {
            @ViewAction var action: (Int) -> Void
        }
        
        let model = Model()
        
        var values1 = [Int]()
        var values2 = [Int]()
        
        let disposeBag = DisposeBag()
        model.$action.emit(onNext: { values1.append($0) }).disposed(by: disposeBag)
        model.$action.emit(onNext: { values2.append($0) }).disposed(by: disposeBag)
        
        model.action(1)
        model.action(2)
        model.action(3)
        
        // Both subscribers should receive all values
        XCTAssertEqual(values1, [1, 2, 3])
        XCTAssertEqual(values2, [1, 2, 3])
    }
    
    // MARK: - BindingContext Edge Cases
    
    func testBindingContextMultipleCalls() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
            @Bindable var value: Int = 0
        }
        
        let context = Context()
        var count1 = 0
        var count2 = 0
        var count3 = 0
        
        // Multiple binding {} calls
        context.binding {
            context.$value.drive(onNext: { _ in count1 += 1 })
        }
        
        context.binding {
            context.$value.drive(onNext: { _ in count2 += 1 })
        }
        
        context.binding {
            context.$value.drive(onNext: { _ in count3 += 1 })
        }
        
        context.value = 10
        context.value = 20
        
        // Each binding should receive updates independently
        XCTAssertEqual(count1, 3) // initial + 2 changes
        XCTAssertEqual(count2, 3)
        XCTAssertEqual(count3, 3)
    }
    
    func testEmptyBindingBlock() {
        final class Context: BindingContext {
            let disposeBag = DisposeBag()
        }
        
        let context = Context()
        
        // Should not crash with empty block
        context.binding {
            // Empty
        }
        
        XCTAssertTrue(true, "Empty binding block should not crash")
    }
    
    // MARK: - Transformation Tests
    
    func testBindingWithTransformations() {
        struct Model {
            @Bindable var count: Int
        }
        
        var model = Model(count: 0)
        
        let observer = TestScheduler(initialClock: 0).createObserver(String.self)
        let disposeBag = DisposeBag()
        
        model.$count
            .map { "\($0) items" }
            .filter { !$0.contains("2") }
            .drive(observer)
            .disposed(by: disposeBag)
        
        model.count = 1
        model.count = 2  // Filtered out
        model.count = 3
        
        XCTAssertRecordedElements(observer.events, ["0 items", "1 items", "3 items"])
    }
    
    func testNilCoalescingWithChainedOperators() {
        let nilProperty = ControlProperty(
            values: Observable<String?>.just(nil),
            valueSink: AnyObserver<String?> { _ in }
        )
        
        var capturedValue: String?
        let disposeBag = DisposeBag()
        
        (nilProperty ?? "default")
            .subscribe(onNext: { capturedValue = $0 })
            .disposed(by: disposeBag)
        
        XCTAssertEqual(capturedValue, "default")
    }
    
    // MARK: - Two-Way Binding Edge Cases
    
    func testTwoWayBindingWithInitialValueSync() {
        @Mutable var value1: String = "initial1"
        @Mutable var value2: String = "initial2"
        
        let disposeBag = DisposeBag()
        
        // After binding, value2 should sync to value1's value
        ($value1 <=> $value2).disposed(by: disposeBag)
        
        // Small delay for binding to take effect
        Thread.sleep(forTimeInterval: 0.01)
        
        // Both should have the same value (implementation dependent)
        // The actual behavior depends on which binding fires first
        XCTAssertTrue(value1 == value2 || value2 == value1)
    }
    
    func testTwoWayBindingDoesNotCauseInfiniteLoop() {
        @Mutable var value1: Int = 0
        @Mutable var value2: Int = 0
        
        let disposeBag = DisposeBag()
        ($value1 <=> $value2).disposed(by: disposeBag)
        
        // This should not cause infinite loop or stack overflow
        value1 = 10
        Thread.sleep(forTimeInterval: 0.01)
        
        value2 = 20
        Thread.sleep(forTimeInterval: 0.01)
        
        // Test passes if we don't crash
        XCTAssertTrue(true, "Two-way binding should not cause infinite loop")
    }
    
    // MARK: - Observable Operator Tests
    
    func testObservableBindingOperator() {
        let observable = Observable.of(1, 2, 3, 4, 5)
        
        var capturedValues = [Int]()
        let disposeBag = DisposeBag()
        
        (observable => { capturedValues.append($0) }).disposed(by: disposeBag)
        
        XCTAssertEqual(capturedValues, [1, 2, 3, 4, 5])
    }
    
    func testObservableBindingToObserver() {
        let scheduler = TestScheduler(initialClock: 0)
        let coldObservable = scheduler.createColdObservable([
            .next(10, "A"),
            .next(20, "B"),
            .next(30, "C"),
            .completed(40)
        ])
        
        let observer = scheduler.createObserver(String.self)
        let disposeBag = DisposeBag()        
        // Convert to Observable first
        (coldObservable.asObservable() => observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [
            .next(10, "A"),
            .next(20, "B"),
            .next(30, "C"),
            .completed(40)
        ])
    }
}
