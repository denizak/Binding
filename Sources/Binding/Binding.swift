//
//  Binding.swift
//  Binding
//
//  Created by Sugeng Wibowo on 09/06/20.
//  Copyright © 2020 KmkLabs. All rights reserved.
//

import Foundation
import RxRelay
import RxCocoa

/// A property wrapper that provides one-way data binding.
///
/// `Bindable` wraps a value and exposes it as a `Driver` through its projected value,
/// allowing UI components to observe changes reactively. The wrapped value can be
/// modified directly, and changes are automatically propagated to observers.
///
/// - Note: While the underlying `BehaviorRelay` is thread-safe, concurrent access
///   to `wrappedValue` should be handled with care in multithreaded contexts.
///
/// Example:
/// ```swift
/// final class ViewModel {
///     @Bindable private(set) var username: String = ""
///     @Bindable private(set) var isLoading: Bool = false
/// }
///
/// // In a view:
/// viewModel.$username.drive(usernameLabel.rx.text)
/// ```
@propertyWrapper
public struct Bindable<Value>: @unchecked Sendable {
    public var wrappedValue: Value {
        get { observableValue.value }
        set { observableValue.accept(newValue) }
    }
    
    public let projectedValue: Driver<Value>
    
    private let observableValue: BehaviorRelay<Value>
    public init(wrappedValue: Value) {
        observableValue = BehaviorRelay(value: wrappedValue)
        projectedValue = observableValue.asDriver()
    }
}

/// A property wrapper that provides two-way data binding.
///
/// `Mutable` wraps a value and exposes it as a `BehaviorRelay` through its projected value,
/// enabling bidirectional communication between view models and UI components.
/// Both the wrapped value and the relay can be used to update the underlying value.
///
/// - Note: While the underlying `BehaviorRelay` is thread-safe, concurrent access
///   to `wrappedValue` should be handled with care in multithreaded contexts.
///
/// Example:
/// ```swift
/// final class ViewModel {
///     @Mutable var searchText: String = ""
///     @Mutable var selectedIndex: Int = 0
/// }
///
/// // In a view (bidirectional binding):
/// viewModel.$searchText.bind(to: searchField.rx.text)
/// searchField.rx.text.bind(to: viewModel.$searchText)
/// ```
@propertyWrapper
public struct Mutable<Value>: @unchecked Sendable {
    public var wrappedValue: Value {
        get { projectedValue.value }
        set { projectedValue.accept(newValue) }
    }
    
    public let projectedValue: BehaviorRelay<Value>
    
    public init(wrappedValue: Value) {
        projectedValue = BehaviorRelay(value: wrappedValue)
    }
}

/// A property wrapper that provides observable action binding with a parameter.
///
/// `ViewAction` wraps a function that accepts a single parameter and returns void,
/// exposing it as a `Signal` through its projected value. This is useful for
/// triggering view actions from view models (e.g., showing alerts, navigation).
///
/// Example:
/// ```swift
/// final class ViewModel {
///     @ViewAction var showAlert: (String) -> Void
///     @ViewAction var navigateToDetail: (Item) -> Void
///
///     func handleError(_ error: Error) {
///         showAlert(error.localizedDescription)
///     }
/// }
///
/// // In a view:
/// viewModel.$showAlert.emit(onNext: { [weak self] message in
///     self?.presentAlert(message)
/// })
/// ```
@propertyWrapper
public struct ViewAction<Value>: @unchecked Sendable {
    private let publisher = PublishRelay<Value>()
    public let projectedValue: Signal<Value>
    
    public let wrappedValue: (Value) -> Void
    
    public init() {
        let publisher = self.publisher
        projectedValue = publisher.asSignal()
        wrappedValue = { publisher.accept($0) }
    }
}

extension ViewAction {
    /// A type alias for `ViewAction` without parameters.
    ///
    /// Use this when you need to trigger actions that don't require any arguments.
    ///
    /// Example:
    /// ```swift
    /// final class ViewModel {
    ///     @ViewAction.NoParam var dismiss: () -> Void
    ///     @ViewAction.NoParam var refresh: () -> Void
    /// }
    ///
    /// // In a view:
    /// viewModel.$dismiss.emit(onNext: { [weak self] in
    ///     self?.navigationController?.popViewController(animated: true)
    /// })
    /// ```
    public typealias NoParam = NoParamViewAction
}

/// A property wrapper for observable actions without parameters.
///
/// This is the underlying implementation of `ViewAction.NoParam`.
/// Prefer using the typealias `ViewAction.NoParam` in your code for better API clarity.
///
/// - Note: The initializer is internal to encourage using this type through the
///   `ViewAction.NoParam` typealias, maintaining a cleaner public API surface.
@propertyWrapper
public struct NoParamViewAction: @unchecked Sendable {
    private let publisher = PublishRelay<Void>()
    public let projectedValue: Signal<Void>
    
    public let wrappedValue: () -> Void
    
    public init() {
        let publisher = self.publisher
        projectedValue = publisher.asSignal()
        wrappedValue = { publisher.accept(()) }
    }
}
