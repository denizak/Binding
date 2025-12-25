//
//  MemoryLeakTest.swift
//  BindingTests
//
//  Created by GitHub Copilot on 24/12/25.
//

import XCTest
import RxSwift
import RxCocoa

@testable import Binding

class MemoryLeakTest: XCTestCase {
    
    func testBindableContainerDeallocates() {
        weak var weakContainer: BindableContainer?
        
        autoreleasepool {
            var container: BindableContainer? = BindableContainer()
            weakContainer = container
            
            // Use the bindable
            let disposeBag = DisposeBag()
            container?.$value.drive().disposed(by: disposeBag)
            
            container?.value = 10
            container = nil
        }
        
        XCTAssertNil(weakContainer, "Container holding @Bindable should be deallocated")
    }
    
    func testMutableContainerDeallocates() {
        weak var weakContainer: MutableContainer?
        
        autoreleasepool {
            var container: MutableContainer? = MutableContainer()
            weakContainer = container
            
            let disposeBag = DisposeBag()
            container?.$text.subscribe().disposed(by: disposeBag)
            
            container = nil
        }
        
        XCTAssertNil(weakContainer, "Container holding @Mutable should be deallocated")
    }
    
    func testViewActionContainerDeallocates() {
        weak var weakContainer: ViewActionContainer?
        
        autoreleasepool {
            var container: ViewActionContainer? = ViewActionContainer()
            weakContainer = container
            
            let disposeBag = DisposeBag()
            container?.$action.emit(onNext: { _ in }).disposed(by: disposeBag)
            
            container?.action("test")
            container = nil
        }
        
        XCTAssertNil(weakContainer, "Container holding @ViewAction should be deallocated")
    }
    
    func testNoParamViewActionContainerDeallocates() {
        weak var weakContainer: NoParamActionContainer?
        
        autoreleasepool {
            var container: NoParamActionContainer? = NoParamActionContainer()
            weakContainer = container
            
            let disposeBag = DisposeBag()
            container?.$action.emit(onNext: { }).disposed(by: disposeBag)
            
            container?.action()
            container = nil
        }
        
        XCTAssertNil(weakContainer, "Container holding @ViewAction.NoParam should be deallocated")
    }
    
    func testBindingContextDisposesAllSubscriptions() {
        var disposedCount = 0
        
        autoreleasepool {
            let context = TestBindingContext()
            
            context.binding {
                Observable<Void>.never().do(onDispose: { disposedCount += 1 }).subscribe()
                Observable<Void>.never().do(onDispose: { disposedCount += 1 }).subscribe()
                Observable<Void>.never().do(onDispose: { disposedCount += 1 }).subscribe()
            }
            
            XCTAssertEqual(disposedCount, 0, "Subscriptions should not be disposed while context exists")
        }
        
        XCTAssertEqual(disposedCount, 3, "All subscriptions should be disposed after context is deallocated")
    }
    
    func testStrongSelfCaptureInBindingCausesRetainCycle() {
        weak var weakViewController: StrongCaptureViewController?
        
        autoreleasepool {
            var viewController: StrongCaptureViewController? = StrongCaptureViewController()
            weakViewController = viewController
            
            viewController?.setupBindingsWithStrongCapture()
            
            viewController = nil
        }
        
        XCTAssertNotNil(weakViewController, "ViewController with strong self capture should leak")
        
        // Clean up the leaked object
        weakViewController?.disposeBag = DisposeBag()
    }
    
    func testWeakSelfInBindingPreventsRetainCycle() {
        weak var weakViewController: WeakCaptureViewController?
        
        autoreleasepool {
            var viewController: WeakCaptureViewController? = WeakCaptureViewController()
            weakViewController = viewController
            
            viewController?.setupBindingsWithWeakCapture()
            
            viewController = nil
        }
        
        XCTAssertNil(weakViewController, "ViewController with weak self capture should be deallocated")
    }
    
    func testBindingClosureDoesNotRetainContext() {
        weak var weakContext: ClosureCaptureContext?
        
        autoreleasepool {
            var context: ClosureCaptureContext? = ClosureCaptureContext()
            weakContext = context
            
            context?.setupBindings()
            
            context = nil
        }
        
        XCTAssertNil(weakContext, "Context should be deallocated when binding closure doesn't capture it")
    }
    
    func testMultipleBindingBlocksDoNotCauseLeaks() {
        weak var weakContext: MultipleBindingsContext?
        
        autoreleasepool { () -> Void in
            let context = MultipleBindingsContext()
            weakContext = context
            
            // Create multiple binding blocks
            for _ in 0..<10 {
                context.binding {
                    context.$counter.drive(onNext: { _ in })
                }
            }
        }
        
        XCTAssertNil(weakContext, "Context with multiple bindings should still deallocate")
    }
}

// MARK: - Test Support Classes

private final class BindableContainer {
    @Bindable var value: Int = 0
}

private final class MutableContainer {
    @Mutable var text: String = ""
}

private final class ViewActionContainer {
    @ViewAction var action: (String) -> Void
}

private final class NoParamActionContainer {
    @ViewAction.NoParam var action: () -> Void
}

private final class TestBindingContext: BindingContext {
    let disposeBag = DisposeBag()
}

private final class StrongCaptureViewController: BindingContext {
    var disposeBag = DisposeBag()
    @Bindable var message: String = "Hello"
    
    func setupBindingsWithStrongCapture() {
        binding {
            // Strong capture - causes retain cycle
            $message.drive(onNext: { value in
                _ = self.message  // Strong self
            })
        }
    }
}

private final class WeakCaptureViewController: BindingContext {
    let disposeBag = DisposeBag()
    @Bindable var message: String = "Hello"
    
    func setupBindingsWithWeakCapture() {
        binding {
            // Weak capture - prevents retain cycle
            $message.drive(onNext: { [weak self] value in
                _ = self?.message
            })
        }
    }
}

private final class ClosureCaptureContext: BindingContext {
    let disposeBag = DisposeBag()
    @Bindable var data: String = "data"
    
    func setupBindings() {
        binding {
            // No capture of self - just logs
            $data.drive(onNext: { value in
                print("Data updated: \(value)")
            })
        }
    }
}

private final class MultipleBindingsContext: BindingContext {
    let disposeBag = DisposeBag()
    @Bindable var counter: Int = 0
}
