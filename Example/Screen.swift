//
//  ViewController.swift
//  FunctionalViewControllers
//
//  Created by Chris Eidhof on 03/09/14.
//  Copyright (c) 2014 Chris Eidhof. All rights reserved.
//

import UIKit
import Box

public func map<A,B>(vc: Screen<A>, f: A -> B) -> Screen<B> {
    return Screen { callback in
        return vc.run { y in
            callback(f(y))
        }
    }
}

public func map<A,B>(nc: NavigationController<A>, f: A -> B) -> NavigationController<B> {
    return NavigationController { callback in
        return nc.build { (y, nc) in
            callback(f(y), nc)
        }
    }
}

extension UIViewController {
    public func presentModal<A>(screen: NavigationController<A>, cancellable: Bool, callback: A -> ()) {
        let vc = screen.build { [unowned self] x, nc in
            callback(x)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        if cancellable {
            let cancelButton = BarButton(title: BarButtonTitle.SystemItem(UIBarButtonSystemItem.Cancel), callback: { _ in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            let rootVC = vc.viewControllers[0] as! UIViewController
            rootVC.setLeftBarButton(cancelButton)
        }
        presentViewController(vc, animated: true, completion: nil)
    }
}

public struct Screen<A> {
    private let build: (A -> ()) -> UIViewController
    public var navigationItem: NavigationItem

    public init(_ build: (A -> ()) -> UIViewController) {
        self.build = build
        navigationItem = defaultNavigationItem
    }

    public init(_ navigationItem: NavigationItem, _ build: (A -> ()) -> UIViewController) {
        self.build = build
        self.navigationItem = navigationItem
    }

    public func run(f: A -> ()) -> UIViewController {
        let vc = build(f)
        vc.applyNavigationItem(navigationItem)
        return vc
    }
}

func ignore<A>(_: A, _: UINavigationController) { }

public struct NavigationController<A> {
    public let build: (f: (A, UINavigationController) -> ()) -> UINavigationController

    public func run() -> UINavigationController {
        return build { _ in }
    }
}

public func navigationController<A>(vc: Screen<A>) -> NavigationController<A> {
    return NavigationController { callback in
        let navController = UINavigationController()
        let rootController = vc.run { callback($0, navController) }
        navController.viewControllers = [rootController]
        return navController
    }
}

infix operator >>> { associativity left }

public func >>><A,B>(l: NavigationController<A>, r: A -> Screen<B>) -> NavigationController<B> {
    return NavigationController { (callback) -> UINavigationController in
        let nc = l.build { a, nc in
            let rvc = r(a).run { c in
                callback(c, nc)
            }
            nc.pushViewController(rvc, animated: true)

        }
        return nc
    }
}

public func textViewController(string: String) -> Screen<()> {
    return Screen { _ in
        var tv = TextViewController()
        tv.textView.text = string
        return tv
    }
}

class TextViewController: UIViewController {
    var textView: UITextView = {
        var tv = UITextView()
        tv.editable = false
        return tv
        }()

    override func viewDidLoad() {
        view.addSubview(textView)
        textView.frame = view.bounds
    }
}

public func modalButton<A>(title: BarButtonTitle, nc: NavigationController<A>, callback: A -> ()) -> BarButton {
    return BarButton(title: title, callback: { context in
        context.viewController.presentModal(nc, cancellable: true, callback: callback)
    })
}

public func add<A>(screen: Screen<A>, callback: A -> ()) -> BarButton {
    return modalButton(.SystemItem(.Add), navigationController(screen), callback)
}

// TODO: is this a good name?
infix operator <|> { associativity left }

public func <|><A,B>(screen: A -> Screen<B>, button: A -> BarButton) -> A -> Screen<B> {
    return { a in
        var screen = screen(a)
        screen.navigationItem.rightBarButtonItem = button(a)
        return screen
    }
}

public func tableViewController<A>(configuration: CellConfiguration<A>) -> [A] -> Screen<A> {
    return { items in
        return asyncTableVC({ $0(items) }, configuration)
    }
}

public func standardCell<A>(f: A -> String) -> CellConfiguration<A> {
    var config: CellConfiguration<A> = CellConfiguration()
    config.render = { cell, a in
        cell.textLabel?.text = f(a)
    }
    return config
}

public func value1Cell<A>(f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return twoTextCell(.Value1)(f)
}

public func subtitleCell<A>(f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return twoTextCell(.Subtitle)(f)
}

public func value2Cell<A>(f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return twoTextCell(.Value2)(f)
}

private func twoTextCell<A>(style: UITableViewCellStyle)(_ f: A -> (title: String, subtitle: String)) -> CellConfiguration<A> {
    return CellConfiguration(render: { (cell: UITableViewCell, a: A) in
        let (title, subtitle) = f(a)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        }, style: style)
}

public struct CellConfiguration<A> {
    var render: (UITableViewCell, A) -> () = { _ in }
    var style: UITableViewCellStyle = UITableViewCellStyle.Default
}


public func asyncTableVC<A>(loadData: ([A] -> ()) -> (), configuration: CellConfiguration<A>, reloadable: Bool = true, navigationItem: NavigationItem = defaultNavigationItem) -> Screen<A> {
    return Screen(navigationItem) { callback in
        var myTableViewController = MyViewController(style: UITableViewStyle.Plain)
        myTableViewController.items = nil
        loadData { myTableViewController.items = $0.map { Box($0) } }
        myTableViewController.cellStyle = configuration.style
        if reloadable {
            myTableViewController.reload = { (f: [AnyObject]? -> ()) in
                loadData {
                    f($0.map { Box($0) })
                }
            }
        }
        myTableViewController.configureCell = { cell, obj in
            if let boxed = obj as? Box<A> {
                configuration.render(cell, boxed.value)
            }
            return cell
        }
        myTableViewController.callback = { x in
            if let boxed = x as? Box<A> {
                callback(boxed.value)
            }
        }
        return myTableViewController
    }
}

extension UIBarButtonItem {

}

class MyViewController: UITableViewController {
    var cellStyle: UITableViewCellStyle = .Default
    var items: [AnyObject]? = [] {
        didSet {
            self.view.backgroundColor = items == nil ? UIColor.grayColor() : UIColor.whiteColor()
            self.tableView.reloadData()
        }
    }

    var reload: (([AnyObject]? -> ()) -> ())? {
        didSet {
            self.refreshControl = reload == nil ? nil : UIRefreshControl()
            self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        }
    }

    var callback: AnyObject -> () = { _ in () }
    var configureCell: (UITableViewCell, AnyObject) -> UITableViewCell = { $0.0 }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : UITableViewCell = UITableViewCell(style: cellStyle, reuseIdentifier: nil) // todo dequeue
        var obj: AnyObject = items![indexPath.row]
        return configureCell(cell, obj)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var obj: AnyObject = items![indexPath.row]
        callback(obj)
    }

    func refresh(sender: UIRefreshControl?) {
        reload? { [weak self] items in
            self?.items = items
            sender?.endRefreshing()
        }
    }
}

@objc class CompletionHandler: NSObject {
    let handler: BarButtonContext -> ()
    weak var viewController: UIViewController?
    init(_ handler: BarButtonContext -> (), _ viewController: UIViewController) {
        self.handler = handler
        self.viewController = viewController
    }

    @objc func tapped(sender: UIBarButtonItem) {
        let context = BarButtonContext(button: sender, viewController: viewController!)
        self.handler(context)
    }
}

public enum BarButtonTitle {
    case Text(String)
    case SystemItem(UIBarButtonSystemItem)
}

public struct BarButtonContext {
    public let button: UIBarButtonItem
    public let viewController: UIViewController
}

public struct BarButton {
    public let title: BarButtonTitle
    public let callback: BarButtonContext -> ()
    public init(title: BarButtonTitle, callback: BarButtonContext -> ()) {
        self.title = title
        self.callback = callback
    }
}

public let defaultNavigationItem = NavigationItem(title: nil, rightBarButtonItem: nil)


public struct NavigationItem {
    public var title: String?
    public var rightBarButtonItem: BarButton?
    public var leftBarButtonItem: BarButton?

    public init(title: String? = nil, rightBarButtonItem: BarButton? = nil, leftBarButtonItem: BarButton? = nil) {
        self.title = title
        self.rightBarButtonItem = rightBarButtonItem
        self.leftBarButtonItem = leftBarButtonItem
    }
}

extension BarButton {
    func barButtonItem(completionHandler: CompletionHandler) -> UIBarButtonItem {
        switch title {
        case .Text(let title):
            return UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Plain, target: completionHandler, action: "tapped:")
        case .SystemItem(let systemItem):
            return UIBarButtonItem(barButtonSystemItem: systemItem, target: completionHandler, action: "tapped:")
        }
    }
}

var AssociatedRightCompletionHandle: UInt8 = 0
var AssociatedLeftCompletionHandle: UInt8 = 0

extension UIViewController {
    // todo this should be on the bar button...
    var rightBarButtonCompletion: CompletionHandler? {
        get {
            return objc_getAssociatedObject(self, &AssociatedRightCompletionHandle) as? CompletionHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedRightCompletionHandle, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }

    var leftBarButtonCompletion: CompletionHandler? {
        get {
            return objc_getAssociatedObject(self, &AssociatedLeftCompletionHandle) as? CompletionHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedLeftCompletionHandle, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }

    func setRightBarButton(barButton: BarButton) {
        let completion = CompletionHandler(barButton.callback, self)
        self.rightBarButtonCompletion = completion
        self.navigationItem.rightBarButtonItem = barButton.barButtonItem(completion)
    }

    func setLeftBarButton(barButton: BarButton) {
        let completion = CompletionHandler(barButton.callback, self)
        self.leftBarButtonCompletion = completion
        self.navigationItem.leftBarButtonItem = barButton.barButtonItem(completion)
    }

    func applyNavigationItem(navigationItem: NavigationItem) {
        self.navigationItem.title = navigationItem.title
        if let barButton = navigationItem.rightBarButtonItem {
            setRightBarButton(barButton)
        }
        if let barButton = navigationItem.leftBarButtonItem {
            setLeftBarButton(barButton)
        }
    }
    
}
