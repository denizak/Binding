//
//  BindingOperator.swift
//  Binding
//
//  Created by Sugeng Wibowo on 09/06/20.
//  Copyright © 2020 KmkLabs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// Custom precedence group for binding operators.
///
/// This precedence group ensures that binding operators have the correct
/// precedence relative to other Swift operators, making binding expressions
/// more readable and predictable.
precedencegroup BindingOperator {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: NilCoalescingPrecedence
}

/// One-way binding operator for `Driver` and `Signal` to observers.
infix operator => : BindingOperator

/// Two-way binding operator for `BehaviorRelay` and `ControlProperty`.
infix operator <=> : BindingOperator

// MARK: - Driver Binding Operators

/// Binds a `Driver` to an observer with non-optional elements.
///
/// This operator provides one-way binding from a `Driver` to any `ObserverType`.
/// The driver will emit values to the observer until disposed.
///
/// - Parameters:
///   - driver: The source `Driver` emitting values.
///   - observer: The observer that will receive the values.
/// - Returns: A `Disposable` representing the binding subscription.
///
/// Example:
/// ```swift
/// viewModel.$username.drive(usernameLabel.rx.text)
/// // Or with the => operator:
/// viewModel.$username => usernameLabel.rx.text
/// ```
public func => <Value, Observer: ObserverType> (driver: Driver<Value>, observer: Observer)
    -> Disposable where Observer.Element == Value {
        return driver.drive(observer)
}

/// Binds a `Driver` to an observer with optional elements.
///
/// This operator provides one-way binding from a `Driver` to an observer that
/// accepts optional values, automatically wrapping emitted values.
///
/// - Parameters:
///   - driver: The source `Driver` emitting values.
///   - observer: The observer that will receive optional values.
/// - Returns: A `Disposable` representing the binding subscription.
public func => <Value, Observer: ObserverType> (driver: Driver<Value>, observer: Observer)
    -> Disposable where Observer.Element == Value? {
        return driver.drive(observer)
}

/// Binds a `Driver` to a closure that handles each emitted value.
///
/// This operator allows you to react to driver emissions with custom logic
/// by providing a closure that will be called for each value.
///
/// - Parameters:
///   - driver: The source `Driver` emitting values.
///   - block: A closure that receives each emitted value.
/// - Returns: A `Disposable` representing the binding subscription.
///
/// Example:
/// ```swift
/// viewModel.$errorMessage => { [weak self] message in
///     self?.showAlert(message)
/// }
/// ```
public func => <Value> (driver: Driver<Value>, block: @escaping (Value) -> Void) -> Disposable {
    return driver.drive(onNext: block)
}

// MARK: - Signal Binding Operators

/// Binds a `Signal` to an observer with non-optional elements.
///
/// This operator provides one-way binding from a `Signal` to any `ObserverType`.
/// Unlike `Driver`, `Signal` doesn't replay the latest value to new subscribers.
///
/// - Parameters:
///   - signal: The source `Signal` emitting values.
///   - observer: The observer that will receive the values.
/// - Returns: A `Disposable` representing the binding subscription.
///
/// Example:
/// ```swift
/// viewModel.$buttonTapped => { print("Button tapped") }
/// ```
public func => <Value, Observer: ObserverType> (signal: Signal<Value>, observer: Observer)
    -> Disposable where Observer.Element == Value {
        return signal.emit(to: observer)
}

/// Binds a `Signal` to an observer with optional elements.
///
/// This operator provides one-way binding from a `Signal` to an observer that
/// accepts optional values, automatically wrapping emitted values.
///
/// - Parameters:
///   - signal: The source `Signal` emitting values.
///   - observer: The observer that will receive optional values.
/// - Returns: A `Disposable` representing the binding subscription.
public func => <Value, Observer: ObserverType> (signal: Signal<Value>, observer: Observer)
    -> Disposable where Observer.Element == Value? {
        return signal.emit(to: observer)
}

/// Binds a `Signal` to a closure that handles each emitted value.
///
/// This operator allows you to react to signal emissions with custom logic.
/// Useful for handling UI actions like button taps or gesture recognitions.
///
/// - Parameters:
///   - signal: The source `Signal` emitting values.
///   - block: A closure that receives each emitted value.
/// - Returns: A `Disposable` representing the binding subscription.
public func => <Value> (signal: Signal<Value>, block: @escaping (Value) -> Void) -> Disposable {
    return signal.emit(onNext: block)
}

// MARK: - Observable Binding Operators

/// Binds an `Observable` to an observer with non-optional elements.
///
/// - Warning: Unlike `Driver`, `Observable` does not guarantee main thread delivery.
///   For UI bindings, prefer converting to `Driver` first using `asDriver(onErrorDriveWith:)`
///   or ensure thread safety manually with `observeOn(MainScheduler.instance)`.
///
/// - Parameters:
///   - observable: The source `Observable` emitting values.
///   - observer: The observer that will receive the values.
/// - Returns: A `Disposable` representing the binding subscription.
///
/// Example:
/// ```swift
/// // Safe for UI - explicitly observe on main thread
/// someObservable
///     .observeOn(MainScheduler.instance)
///     => usernameLabel.rx.text
/// ```
public func => <Value, Observer: ObserverType> (observable: Observable<Value>, observer: Observer)
    -> Disposable where Observer.Element == Value {
        return observable.bind(to: observer)
}

/// Binds an `Observable` to an observer with optional elements.
///
/// - Warning: Unlike `Driver`, `Observable` does not guarantee main thread delivery.
///   For UI bindings, use `asDriver(onErrorDriveWith:)` or `observeOn(MainScheduler.instance)`.
///
/// - Parameters:
///   - observable: The source `Observable` emitting values.
///   - observer: The observer that will receive optional values.
/// - Returns: A `Disposable` representing the binding subscription.
public func => <Value, Observer: ObserverType> (observable: Observable<Value>, observer: Observer)
    -> Disposable where Observer.Element == Value? {
        return observable.bind(to: observer)
}

/// Binds an `Observable` to a closure that handles each emitted value.
///
/// - Warning: Unlike `Driver`, `Observable` does not guarantee main thread delivery.
///   The closure may be called on any thread. For UI updates, dispatch to main thread manually.
///
/// - Parameters:
///   - observable: The source `Observable` emitting values.
///   - block: A closure that receives each emitted value.
/// - Returns: A `Disposable` representing the binding subscription.
///
/// Example:
/// ```swift
/// dataObservable => { [weak self] data in
///     DispatchQueue.main.async {
///         self?.updateUI(with: data)
///     }
/// }
/// ```
public func => <Value> (observable: Observable<Value>, block: @escaping (Value) -> Void) -> Disposable {
    return observable.subscribe(onNext: block)
}

// MARK: - Control Event Binding

/// Binds a `ControlEvent` to a closure that handles each emitted value.
///
/// This operator allows you to observe UI control events (like button taps,
/// text field editing, etc.) and react to them with custom logic.
///
/// - Parameters:
///   - controlEvent: The source `ControlEvent` emitting values.
///   - block: A closure that receives each emitted value.
/// - Returns: A `Disposable` representing the binding subscription.
///
/// Example:
/// ```swift
/// button.rx.tap => { [weak self] in
///     self?.handleButtonTap()
/// }
/// ```
public func => <Value> (controlEvent: ControlEvent<Value>, block: @escaping (Value) -> Void) -> Disposable {
    return controlEvent.subscribe(onNext: block)
}

// MARK: - Two-Way Binding

/// Creates a two-way binding between two `BehaviorRelay` instances.
///
/// This operator establishes bidirectional synchronization between two relays.
/// Changes to either relay will be reflected in the other. Uses `distinctUntilChanged()`
/// on both sides to prevent infinite update loops.
///
/// - Parameters:
///   - lhs: The first `BehaviorRelay` to bind.
///   - rhs: The second `BehaviorRelay` to bind.
/// - Returns: A composite `Disposable` managing both binding directions.
///
/// Example:
/// ```swift
/// // Sync two view models
/// viewModel1.$sharedState <=> viewModel2.$sharedState
/// 
/// // Keep local and global state in sync
/// localSettings.$theme <=> globalSettings.$theme
/// ```
///
/// - Note: Requires `Value: Equatable` to use `distinctUntilChanged()`.
public func <=> <Value: Equatable> (
    lhs: BehaviorRelay<Value>, rhs: BehaviorRelay<Value>
) -> Disposable {
    return CompositeDisposable(
        lhs.distinctUntilChanged().observe(on: MainScheduler.asyncInstance).bind(to: rhs),
        rhs.distinctUntilChanged().skip(1).observe(on: MainScheduler.asyncInstance).bind(to: lhs)
    )
}

/// Creates a two-way binding between a `BehaviorRelay` and a `ControlProperty`.
///
/// This operator establishes bidirectional data flow: changes to the relay
/// update the control property, and user interactions with the control
/// update the relay. Uses async scheduling to prevent reentrancy issues.
///
/// - Parameters:
///   - relay: The `BehaviorRelay` to bind.
///   - property: The control property to bind (e.g., `UITextField.rx.text`).
/// - Returns: A composite `Disposable` managing both binding directions.
///
/// Example:
/// ```swift
/// viewModel.$searchText <=> searchField.rx.text ?? ""
/// ```
///
/// - Warning: Ensure the control property's element type matches the relay's value type.
///   For optional properties, use the `??` operator to provide a default value.
public func <=> <Value, PropertyType: ControlPropertyType> (
    relay: BehaviorRelay<Value>, property: PropertyType
) -> Disposable where PropertyType.Element == Value {
    return CompositeDisposable(
        relay.observe(on: MainScheduler.asyncInstance).bind(to: property),
        property.skip(1).observe(on: MainScheduler.asyncInstance).bind(to: relay)
    )
}

// MARK: - Nil-Coalescing Operator

/// Provides a default value for optional `ControlProperty` values.
///
/// This operator adapts an optional `ControlProperty` (like `UITextField.rx.text`)
/// to a non-optional one by providing a default value for `nil` cases.
/// This is particularly useful for two-way binding where the relay expects
/// a non-optional type.
///
/// The default value is evaluated lazily using `@autoclosure`, so expensive
/// computations are only performed when needed (when the property emits `nil`).
///
/// - Parameters:
///   - property: The optional `ControlProperty`.
///   - defaultValue: An autoclosure providing the default value when the property emits `nil`.
/// - Returns: A non-optional `ControlProperty` using the default for `nil` values.
///
/// Example:
/// ```swift
/// // TextField's text is String?, but viewModel expects String
/// viewModel.$searchText <=> textField.rx.text ?? ""
/// viewModel.$age <=> ageField.rx.text ?? "0"
/// 
/// // Expensive default is only computed when needed
/// textField.rx.text ?? computeDefaultValue()
/// ```
public func ?? <Value> (property: ControlProperty<Value?>, defaultValue: @autoclosure @escaping () -> Value)
    -> ControlProperty<Value> {
        let observer = AnyObserver<Value> { event in
            switch event {
            case .next(let value): property.onNext(value)
            case .error(let error): property.onError(error)
            case .completed: property.onCompleted()
            }
        }
        return ControlProperty(
            values: property.compactMap { $0 ?? defaultValue() }, valueSink: observer
        )
}
