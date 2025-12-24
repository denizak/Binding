//
//  BindingContext.swift
//  Binding
//
//  Created by Sugeng Wibowo on 09/06/20.
//  Copyright © 2020 KmkLabs. All rights reserved.
//

import Foundation
import RxSwift

/// A protocol for objects that provide a binding context with automatic disposal.
///
/// Conforming types must provide a `DisposeBag` that will be used to manage
/// the lifecycle of all bindings created within the context. When the object
/// is deallocated, all subscriptions will be automatically disposed.
///
/// - Note: This protocol requires reference semantics (`AnyObject` conformance)
///   to ensure proper `DisposeBag` lifecycle management.
///
/// Example:
/// ```swift
/// final class ViewController: UIViewController, BindingContext {
///     let disposeBag = DisposeBag()
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         binding {
///             viewModel.$username.drive(usernameLabel.rx.text)
///             viewModel.$isLoading.drive(activityIndicator.rx.isAnimating)
///         }
///     }
/// }
/// ```
public protocol BindingContext: AnyObject {
    var disposeBag: DisposeBag { get }
}

extension BindingContext {
    /// Creates bindings within a declarative scope using a result builder.
    ///
    /// All disposables returned within the closure will be automatically
    /// added to the context's `disposeBag` and disposed when the context
    /// is deallocated.
    ///
    /// The result builder supports:
    /// - Multiple binding statements
    /// - Conditional bindings with `if` and `if-else`
    /// - Loops with `for-in`
    ///
    /// - Parameter disposables: A closure that returns disposables using the
    ///   `@BindingDisposables` result builder.
    public func binding(@BindingDisposables disposables: () -> Disposable) {
        disposables().disposed(by: disposeBag)
    }
}

#if swift(>=5.4)
@resultBuilder
public struct BindingDisposables {
    public static func buildBlock(_ disposables: Disposable...) -> Disposable {
        return CompositeDisposable(disposables: disposables)
    }
    
    public static func buildExpression(_ expression: Disposable) -> Disposable {
        return expression
    }
    
    public static func buildOptional(_ component: Disposable?) -> Disposable {
        return component ?? Disposables.create()
    }
    
    public static func buildEither(first component: Disposable) -> Disposable {
        return component
    }
    
    public static func buildEither(second component: Disposable) -> Disposable {
        return component
    }
    
    public static func buildArray(_ components: [Disposable]) -> Disposable {
        return CompositeDisposable(disposables: components)
    }
}
#else
@_functionBuilder
public struct BindingDisposables {
    public static func buildBlock(_ disposables: Disposable...) -> Disposable {
        return CompositeDisposable(disposables: disposables)
    }
    
    public static func buildExpression(_ expression: Disposable) -> Disposable {
        return expression
    }
    
    public static func buildOptional(_ component: Disposable?) -> Disposable {
        return component ?? Disposables.create()
    }
    
    public static func buildEither(first component: Disposable) -> Disposable {
        return component
    }
    
    public static func buildEither(second component: Disposable) -> Disposable {
        return component
    }
    
    public static func buildArray(_ components: [Disposable]) -> Disposable {
        return CompositeDisposable(disposables: components)
    }
}
#endif
