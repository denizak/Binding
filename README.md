# Binding

A lightweight, type-safe data binding framework for Swift using `@propertyWrapper` and `@resultBuilder`. Built on top of RxSwift, it provides an elegant API for implementing MVVM architecture with reactive bindings.

[![Swift Version](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)

## Features

- ✅ **One-way & Two-way Binding** - Support for both unidirectional and bidirectional data flow
- ✅ **Type-Safe Property Wrappers** - Leverage Swift's property wrapper syntax for clean, declarative code
- ✅ **Result Builder Support** - Use declarative syntax with `if`, `else`, and `for` loops in binding contexts
- ✅ **Custom Binding Operators** - Intuitive `=>` and `<=>` operators for streamlined binding
- ✅ **Memory Safe** - Automatic disposal via `DisposeBag` integration
- ✅ **Swift 6 Ready** - `Sendable` conformance for strict concurrency checking
- ✅ **Thread-Safe** - Built on RxSwift's thread-safe primitives

## Requirements

| Component | Version |
|-----------|---------|
| Swift | 5.5+ |
| iOS | 9.0+ |
| macOS | 10.10+ |
| tvOS | 9.0+ |
| watchOS | 3.0+ |
| RxSwift | 6.9.0+ |

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/denizak/Binding.git", from: "0.0.1")
]
```

Or in Xcode:
1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/denizak/Binding.git`
3. Select the version and add to your target

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'Binding', '~> 0.0.1'
```

Then run:
```bash
pod install
```

## Quick Start

```swift
import Binding
import RxSwift
import RxCocoa

// Define your view model
final class LoginViewModel {
    @Bindable private(set) var isLoading: Bool = false
    @Mutable var username: String = ""
    @Mutable var password: String = ""
    @ViewAction var showAlert: (String) -> Void
    @ViewAction.NoParam var dismissKeyboard: () -> Void
}

// Bind in your view controller
final class LoginViewController: UIViewController, BindingContext {
    let disposeBag = DisposeBag()
    let viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        binding {
            // One-way binding
            viewModel.$isLoading => activityIndicator.rx.isAnimating
            
            // Two-way binding
            viewModel.$username <=> usernameField.rx.text ?? ""
            viewModel.$password <=> passwordField.rx.text ?? ""
            
            // Action binding
            viewModel.$showAlert => { [weak self] message in
                self?.presentAlert(message)
            }
            
            loginButton.rx.tap => { [weak self] in
                self?.viewModel.login()
            }
        }
    }
}
```

## Usage
### Property
The property wrapper used for observable property in view model that can be binded to view property by using `RxCocoa`.
There are 3 types of wrapper (2 for observable value, and 1 for observable action).
#### Bindable
One-way binding type of property with `Driver` as its `projectedValue` [doc](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md#projections), and can use any type for its property type (`wrappedValue`).
```swift
final class ViewModel {
  @Bindable private(set) var name: String = ""
  @Bindable private(set) var description: String = ""
  
  func change() {
      name = "haha"
      description = "description"
  }
}
```
For the usage in `View` we could bind it by using the projected value
```swift
disposeBag.insert(
  vm.$name.drive(nameLabel.rx.text),
  vm.$description.drive(descLabel.rx.text)
)
```
#### Mutable
Two-way binding type of property with `BehaviorRelay` as its `projectedValue`, also same as `Bindable` it can use any type for its property type.
```swift
final class ViewModel {
  @Mutable var typedText: String = ""
  @Mutable var selectedTarget: Target = .vidioAdmin
}
```
For usage in `View` we cound bind it same as `Bindable` by using the projected value, but since its type is `BehaviorRelay`, it can also accept value from view.
```swift
disposeBag.insert(
  vm.$typedText.asDriver().drive(textInput.rx.text),
  textInput.rx.text.subscribe(onNext: { vm.$typedText.accept($0) /* or vm.typedText = $0 */ })
)
```
#### ViewAction
One parameter observable function, use to trigger view action from view model. Example of action would be show alert, open view controller, dismiss, etc. Note that the wrapped value type has to be a function with single parameter and `Void` return type and it will have `Signal` as the projected value.
```swift
final class ViewModel {
  @ViewAction var alert: (Message) -> Void
  
  func change() {
      alert(Message("Changed!"))
  }
}
```
To bind it in view,
```swift
disposeBag.insert(
  vm.$alert.emit(onNext: { [weak self] in self?.showAlert($0.textMessage) })
)
```
##### ViewAction without argument
Since `ViewAction` needs the wrapped value to be single argument function, it will be awkward to use Void as the parameter type. For this, we could use another type of `ViewAction`, `ViewAction.NoParam`. It's the same as `ViewAction`, with exception of wrapped value type has to be no argument function `() -> Void`.
```swift
final class ViewModel {
  @ViewAction.NoParam var dismiss:() -> Void
}
```
### BindingContext
When using RxSwift to bind view and property, the subscription needs to be dispose at some point, this usually be done after the view for the binding has been disposed. 
To implement this, usually we use `DisposeBag` and add the subscriptions to it to let it auto dispose all the subscription when the `DisposeBag` disposed by the view.
```swift
// example
let disposeBag = DisposeBag()
view.rx.text.subscribe(onNext: { /*...*/ }).disposed(by: disposeBag)
// or when there are multiple subscription we use
disposeBag.insert(
  textObservable.subscribe(),
  nameObservable.subscribe()
)
```
When using binding, a protocol called `BindingContext` is introduced to provide a context where the binding should be done.
When implementing this protocol, a property `disposeBag` need to be implemented for it will be used to dispose all subscriptions added inside the context when de-inited. 
`binding(@BindingDisposables disposables: () -> Disposable)` in `BindingContext` can be used as the scope for the subscriptions.
For any subscriptions done in this function builder, it will be inserted into the `disposeBag`.

*Note:* `@_functionBuilder` is used to implement this behavior [proposal doc](https://github.com/apple/swift-evolution/blob/9992cf3c11c2d5e0ea20bee98657d93902d5b174/proposals/XXXX-function-builders.md) [more learning](https://www.swiftbysundell.com/articles/the-swift-51-features-that-power-swiftuis-api/) (apparently, it's been changed to `@functionBuilder` in the newer version)
```swift
final class ViewController: BindingContext {
  ...
  let disposeBag = DisposeBag() 
  override func viewDidLoad() {
    super.viewDidLoad()
    ...
    binding {
      viewModel.$text.drive(textLabel.rx.text)  // notice we don't add comma here, since it is not needed when using function builder
      viewModel.$description.drive(descLabel.rx.text)
      viewModel.$alert.emit(onNext: { [weak self] in self?.alert($0) })
    }
  }
}
```
### Binding Operators
To simplify the binding, custom operators added to this library.
There are 2 binding operators that can be use to bind the view with view model.
#### One-way Binding Operator
To handle one-way binding, operator `=>` can be used with left-hand operand to be `Driver` or `Signal`(for `ViewAction` binding).

The right-hand operand for both `Driver` and `Signal` can be:
- `ObserverType` with value type both `optional` or not, and it can also be function with one argument.
- function with one argument `(ValueType) -> Void`.
```swift
binding {
  viewModel.$text => textLabel.rx.text // Driver with Binder as receiver
  viewModel.$description => { print("description: \($0)") } // Driver with function as receiver
  viewModel.$alert => { [weak self] in self?.alert($0) } // Signal with function as receiver
}
```
#### Two-way Binding Operator
To handle two-way binding, operator `<=>` can be used with left-hand operand to be `BehaviorRelay` and `ControlPropertyType` as the right-hand operand.
```swift
binding {
  // notice in this example text control property is not being used
  // instead it is using custom control property with non optional value
  // since, <=> cannot accept ControlPropertyType with element optional
  // for optional type a new operator will introduced
  viewModel.$inputText <=> textField.rx.nonNullText
}
```
#### Optional Operator
This operator is especially used for `ControlProperty` with default value.
It has to be done this way because of how `UIKit` was implemented in the past, and `RxCocoa` has to adapt to it (e.g. `text` property in text field has `String?` type).

The operator for this case is re-using the same operator for Nil-coalescing (`??`) in swift.
```swift
binding {
  viewModel.$inputText <=> textField.rx.text ?? "default value"
}
```

## Thread Safety

The Binding library is built on RxSwift's thread-safe primitives (`BehaviorRelay`, `PublishRelay`), which handle concurrent access internally. However, be mindful of the following:

- **Property Wrappers**: While the underlying RxSwift types are thread-safe, the property wrapper structs themselves don't provide synchronization for concurrent `wrappedValue` access
- **Best Practice**: Perform all UI bindings on the main thread using RxSwift's `observeOn(MainScheduler.instance)` or `Driver`/`Signal` which guarantee main thread delivery
- **View Model Updates**: When updating view model properties from background threads, consider using `BehaviorRelay.accept()` directly for guaranteed thread safety

Example:
```swift
// Safe: Update from background thread using relay
DispatchQueue.global().async {
    viewModel.$data.accept(newData) // Thread-safe
}

// Caution: Direct property access from multiple threads
DispatchQueue.global().async {
    viewModel.data = newData // Concurrent access not synchronized
}
```

## Practical Examples

### Example 1: User Profile Screen

A complete example showing form validation, data loading, and error handling:

```swift
import Binding
import RxSwift
import RxCocoa

// MARK: - View Model

final class ProfileViewModel {
    // Input - Two-way bindings
    @Mutable var name: String = ""
    @Mutable var email: String = ""
    @Mutable var bio: String = ""
    
    // Output - One-way bindings
    @Bindable private(set) var isLoading: Bool = false
    @Bindable private(set) var isSaveEnabled: Bool = false
    @Bindable private(set) var errorMessage: String = ""
    @Bindable private(set) var profileImageURL: URL?
    
    // Actions
    @ViewAction.NoParam var saveProfile: () -> Void
    @ViewAction.NoParam var uploadPhoto: () -> Void
    @ViewAction var showError: (String) -> Void
    @ViewAction.NoParam var dismiss: () -> Void
    
    private let service: ProfileService
    private let disposeBag = DisposeBag()
    
    init(service: ProfileService) {
        self.service = service
        setupBindings()
    }
    
    private func setupBindings() {
        // Validate form and enable save button
        Observable.combineLatest($name, $email, $bio)
            .map { name, email, bio in
                !name.isEmpty && email.contains("@") && !bio.isEmpty
            }
            .bind(to: $isSaveEnabled)
            .disposed(by: disposeBag)
        
        // Handle save action
        $saveProfile
            .flatMapLatest { [weak self] _ -> Observable<Result<Profile, Error>> in
                guard let self = self else { return .empty() }
                self.isLoading = true
                return self.service.saveProfile(
                    name: self.name,
                    email: self.email,
                    bio: self.bio
                )
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoading = false
                switch result {
                case .success:
                    self?.dismiss()
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - View Controller

final class ProfileViewController: UIViewController, BindingContext {
    let disposeBag = DisposeBag()
    let viewModel: ProfileViewModel
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var uploadButton: UIButton!
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    private func setupBindings() {
        binding {
            // Two-way bindings for form inputs
            viewModel.$name <=> nameTextField.rx.text ?? ""
            viewModel.$email <=> emailTextField.rx.text ?? ""
            viewModel.$bio <=> bioTextView.rx.text ?? ""
            
            // One-way bindings for UI state
            viewModel.$isLoading => activityIndicator.rx.isAnimating
            viewModel.$isLoading
                .map { !$0 }
                .drive(saveButton.rx.isEnabled)
            
            viewModel.$isSaveEnabled => saveButton.rx.isEnabled
            
            viewModel.$profileImageURL
                .compactMap { $0 }
                .flatMap { URLSession.shared.rx.data(request: URLRequest(url: $0)) }
                .map { UIImage(data: $0) }
                .drive(profileImageView.rx.image)
            
            // Action bindings
            saveButton.rx.tap => { [weak self] in
                self?.viewModel.saveProfile()
            }
            
            uploadButton.rx.tap => { [weak self] in
                self?.viewModel.uploadPhoto()
            }
            
            viewModel.$showError => { [weak self] message in
                self?.showAlert(title: "Error", message: message)
            }
            
            viewModel.$dismiss => { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

### Example 2: Search Screen with Debouncing

Implementing a search feature with real-time results:

```swift
final class SearchViewModel {
    @Mutable var searchQuery: String = ""
    @Bindable private(set) var results: [SearchResult] = []
    @Bindable private(set) var isSearching: Bool = false
    @Bindable private(set) var isEmpty: Bool = false
    
    @ViewAction var selectResult: (SearchResult) -> Void
    
    private let searchService: SearchService
    private let disposeBag = DisposeBag()
    
    init(searchService: SearchService) {
        self.searchService = searchService
        setupSearch()
    }
    
    private func setupSearch() {
        $searchQuery
            .debounce(.milliseconds(300))
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in self?.isSearching = true })
            .flatMapLatest { [weak self] query -> Observable<[SearchResult]> in
                guard let self = self, !query.isEmpty else {
                    return .just([])
                }
                return self.searchService.search(query: query)
                    .catch { _ in .just([]) }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] results in
                self?.isSearching = false
                self?.results = results
                self?.isEmpty = results.isEmpty
            })
            .disposed(by: disposeBag)
    }
}

final class SearchViewController: UIViewController, BindingContext {
    let disposeBag = DisposeBag()
    let viewModel: SearchViewModel
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    private func setupBindings() {
        binding {
            // Two-way binding for search input
            viewModel.$searchQuery <=> searchBar.rx.text ?? ""
            
            // Display results in table view
            viewModel.$results
                .drive(tableView.rx.items(cellIdentifier: "Cell")) { _, result, cell in
                    cell.textLabel?.text = result.title
                    cell.detailTextLabel?.text = result.subtitle
                }
            
            // Show/hide loading indicator
            viewModel.$isSearching => activityIndicator.rx.isAnimating
            
            // Show/hide empty state
            viewModel.$isEmpty => emptyStateLabel.rx.isHidden.map { !$0 }
            
            // Handle selection
            tableView.rx.modelSelected(SearchResult.self) => { [weak self] result in
                self?.viewModel.selectResult(result)
            }
            
            viewModel.$selectResult => { [weak self] result in
                self?.navigateToDetail(result)
            }
        }
    }
    
    private func navigateToDetail(_ result: SearchResult) {
        let detailVC = DetailViewController(result: result)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

### Example 3: Settings Screen with Toggle Controls

Managing multiple settings with two-way bindings:

```swift
final class SettingsViewModel {
    // All settings are mutable for two-way binding
    @Mutable var notificationsEnabled: Bool = true
    @Mutable var darkModeEnabled: Bool = false
    @Mutable var soundEnabled: Bool = true
    @Mutable var autoPlayEnabled: Bool = false
    @Mutable var downloadQuality: DownloadQuality = .high
    
    @Bindable private(set) var storageUsed: String = "0 MB"
    @ViewAction.NoParam var clearCache: () -> Void
    @ViewAction var showClearCacheConfirmation: () -> Void
    
    private let settingsService: SettingsService
    private let disposeBag = DisposeBag()
    
    init(settingsService: SettingsService) {
        self.settingsService = settingsService
        observeSettings()
    }
    
    private func observeSettings() {
        // Save settings whenever they change
        Observable.merge(
            $notificationsEnabled.map { ("notifications", $0) },
            $darkModeEnabled.map { ("darkMode", $0) },
            $soundEnabled.map { ("sound", $0) },
            $autoPlayEnabled.map { ("autoPlay", $0) }
        )
        .debounce(.milliseconds(500))
        .subscribe(onNext: { [weak self] key, value in
            self?.settingsService.save(key: key, value: value)
        })
        .disposed(by: disposeBag)
        
        // Handle cache clearing
        $clearCache
            .subscribe(onNext: { [weak self] in
                self?.showClearCacheConfirmation()
            })
            .disposed(by: disposeBag)
    }
}

final class SettingsViewController: UITableViewController, BindingContext {
    let disposeBag = DisposeBag()
    let viewModel: SettingsViewModel
    
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var soundSwitch: UISwitch!
    @IBOutlet weak var autoPlaySwitch: UISwitch!
    @IBOutlet weak var storageLabel: UILabel!
    @IBOutlet weak var clearCacheButton: UIButton!
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    private func setupBindings() {
        binding {
            // Two-way bindings for all switches
            viewModel.$notificationsEnabled <=> notificationsSwitch.rx.isOn
            viewModel.$darkModeEnabled <=> darkModeSwitch.rx.isOn
            viewModel.$soundEnabled <=> soundSwitch.rx.isOn
            viewModel.$autoPlayEnabled <=> autoPlaySwitch.rx.isOn
            
            // One-way binding for storage display
            viewModel.$storageUsed => storageLabel.rx.text
            
            // Action bindings
            clearCacheButton.rx.tap => { [weak self] in
                self?.viewModel.clearCache()
            }
            
            viewModel.$showClearCacheConfirmation => { [weak self] in
                self?.showClearCacheAlert()
            }
        }
    }
    
    private func showClearCacheAlert() {
        let alert = UIAlertController(
            title: "Clear Cache",
            message: "This will delete all cached data. Continue?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            // Perform cache clearing
        })
        present(alert, animated: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

### Example 4: Data Loading with Pull-to-Refresh

Loading and refreshing data from an API:

```swift
final class FeedViewModel {
    @Bindable private(set) var posts: [Post] = []
    @Bindable private(set) var isLoading: Bool = false
    @Bindable private(set) var isRefreshing: Bool = false
    @Bindable private(set) var hasError: Bool = false
    @Bindable private(set) var errorMessage: String = ""
    
    @ViewAction.NoParam var loadInitialData: () -> Void
    @ViewAction.NoParam var refresh: () -> Void
    @ViewAction.NoParam var loadMore: () -> Void
    @ViewAction var selectPost: (Post) -> Void
    
    private let feedService: FeedService
    private let disposeBag = DisposeBag()
    private var currentPage = 0
    
    init(feedService: FeedService) {
        self.feedService = feedService
        setupActions()
    }
    
    private func setupActions() {
        // Initial load
        $loadInitialData
            .do(onNext: { [weak self] in
                self?.isLoading = true
                self?.hasError = false
            })
            .flatMapLatest { [weak self] _ -> Observable<[Post]> in
                guard let self = self else { return .empty() }
                return self.feedService.fetchPosts(page: 0)
                    .catch { error in
                        self.errorMessage = error.localizedDescription
                        self.hasError = true
                        return .just([])
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] posts in
                self?.isLoading = false
                self?.posts = posts
                self?.currentPage = 0
            })
            .disposed(by: disposeBag)
        
        // Pull to refresh
        $refresh
            .do(onNext: { [weak self] in
                self?.isRefreshing = true
                self?.hasError = false
            })
            .flatMapLatest { [weak self] _ -> Observable<[Post]> in
                guard let self = self else { return .empty() }
                return self.feedService.fetchPosts(page: 0)
                    .catch { _ in .just([]) }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] posts in
                self?.isRefreshing = false
                self?.posts = posts
                self?.currentPage = 0
            })
            .disposed(by: disposeBag)
        
        // Load more
        $loadMore
            .flatMapLatest { [weak self] _ -> Observable<[Post]> in
                guard let self = self else { return .empty() }
                let nextPage = self.currentPage + 1
                return self.feedService.fetchPosts(page: nextPage)
                    .catch { _ in .just([]) }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] newPosts in
                guard let self = self else { return }
                self.posts.append(contentsOf: newPosts)
                self.currentPage += 1
            })
            .disposed(by: disposeBag)
    }
}

final class FeedViewController: UIViewController, BindingContext {
    let disposeBag = DisposeBag()
    let viewModel: FeedViewModel
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private lazy var refreshControl = UIRefreshControl()
    
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.refreshControl = refreshControl
        setupBindings()
        viewModel.loadInitialData()
    }
    
    private func setupBindings() {
        binding {
            // Display posts
            viewModel.$posts
                .drive(tableView.rx.items(cellIdentifier: "PostCell")) { _, post, cell in
                    cell.textLabel?.text = post.title
                    cell.detailTextLabel?.text = post.author
                }
            
            // Loading states
            viewModel.$isLoading => activityIndicator.rx.isAnimating
            viewModel.$isRefreshing => refreshControl.rx.isRefreshing
            
            // Error handling
            viewModel.$hasError => errorView.rx.isHidden.map { !$0 }
            viewModel.$errorMessage => errorLabel.rx.text
            
            // Actions
            refreshControl.rx.controlEvent(.valueChanged) => { [weak self] in
                self?.viewModel.refresh()
            }
            
            tableView.rx.modelSelected(Post.self) => { [weak self] post in
                self?.viewModel.selectPost(post)
            }
            
            viewModel.$selectPost => { [weak self] post in
                let detailVC = PostDetailViewController(post: post)
                self?.navigationController?.pushViewController(detailVC, animated: true)
            }
            
            // Load more when scrolling to bottom
            tableView.rx.contentOffset
                .filter { [weak self] offset in
                    guard let self = self else { return false }
                    let contentHeight = self.tableView.contentSize.height
                    let frameHeight = self.tableView.frame.height
                    return offset.y > contentHeight - frameHeight - 100
                }
                .throttle(.seconds(1), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.viewModel.loadMore()
                })
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

## Advanced Usage

### Conditional Bindings

The `@resultBuilder` supports Swift's control flow statements:

```swift
binding {
    viewModel.$username => usernameLabel.rx.text
    
    // Conditional binding
    if viewModel.showDebugInfo {
        viewModel.$debugMessage => debugLabel.rx.text
    }
    
    // If-else
    if viewModel.isAuthenticated {
        viewModel.$profile => profileView.rx.data
    } else {
        viewModel.$guestMessage => guestLabel.rx.text
    }
    
    // Loops
    for (index, item) in viewModel.items.enumerated() {
        viewModel.$items.map { $0[index] } => itemViews[index].rx.data
    }
}
```

### Multiple Binding Contexts

You can organize bindings into logical groups:

```swift
final class ComplexViewController: UIViewController, BindingContext {
    let disposeBag = DisposeBag()
    
    func setupUserBindings() {
        binding {
            viewModel.$username => usernameLabel.rx.text
            viewModel.$avatar => avatarImageView.rx.image
        }
    }
    
    func setupFormBindings() {
        binding {
            viewModel.$email <=> emailField.rx.text ?? ""
            viewModel.$phone <=> phoneField.rx.text ?? ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserBindings()
        setupFormBindings()
    }
}
```

### Custom Operators with Transformations

Combine binding operators with RxSwift operators:

```swift
binding {
    // Transform before binding
    viewModel.$count
        .map { "\($0) items" }
        .drive(countLabel.rx.text)
    
    // Filter and bind
    viewModel.$status
        .filter { $0 != .idle }
        .drive(statusLabel.rx.text)
}
```

## API Reference

### Property Wrappers

| Wrapper | Projected Value | Use Case | Example |
|---------|----------------|----------|---------|
| `@Bindable<T>` | `Driver<T>` | One-way binding from ViewModel to View | `@Bindable var title: String` |
| `@Mutable<T>` | `BehaviorRelay<T>` | Two-way binding between ViewModel and View | `@Mutable var searchText: String` |
| `@ViewAction<T>` | `Signal<T>` | ViewModel-triggered actions with parameter | `@ViewAction var alert: (String) -> Void` |
| `@ViewAction.NoParam` | `Signal<Void>` | ViewModel-triggered actions without parameter | `@ViewAction.NoParam var refresh: () -> Void` |

### Operators

| Operator | Left Operand | Right Operand | Description |
|----------|-------------|---------------|-------------|
| `=>` | `Driver<T>` / `Signal<T>` | `Observer` / Closure | One-way binding |
| `<=>` | `BehaviorRelay<T>` | `ControlProperty<T>` | Two-way binding |
| `??` | `ControlProperty<T?>` | `T` | Provide default value for optional |

## Testing

The framework includes comprehensive test suites:

- **Unit Tests**: Property wrapper behavior, binding operators
- **Memory Leak Tests**: Verify no retain cycles in bindings
- **Thread Safety Tests**: Concurrent access scenarios
- **Result Builder Tests**: Conditional and loop support

Run tests:
```bash
swift test
# or
xcodebuild test -scheme Binding
```

## Migration Guide

### From Direct RxSwift

**Before:**
```swift
class ViewModel {
    let username = BehaviorRelay<String>(value: "")
    let isLoading = BehaviorRelay<Bool>(value: false)
}

// In ViewController
viewModel.username.asDriver()
    .drive(usernameLabel.rx.text)
    .disposed(by: disposeBag)
```

**After:**
```swift
class ViewModel {
    @Mutable var username: String = ""
    @Bindable var isLoading: Bool = false
}

// In ViewController (conforming to BindingContext)
binding {
    viewModel.$username => usernameLabel.rx.text
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Credits

Created by Sugeng Wibowo
Copyright © 2020 KmkLabs

## Related Projects

- [RxSwift](https://github.com/ReactiveX/RxSwift) - Reactive Programming in Swift
- [RxCocoa](https://github.com/ReactiveX/RxSwift/tree/main/RxCocoa) - RxSwift bindings for UIKit and Cocoa
