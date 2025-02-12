import Foundation
import XCTest
import WebKit
@testable import Strada

class BridgeDelegateTests: XCTestCase {
    private var delegate: BridgeDelegate!
    private var destination: AppBridgeDestination!
    private var bridge: BridgeSpy!
    private let json = """
        {"title":"Page-title","subtitle":"Page-subtitle"}
    """
    
    override func setUp() async throws {
        destination = AppBridgeDestination()
        delegate = BridgeDelegate(location: "https://37signals.com",
                                  destination: destination,
                                  componentTypes: [OneBridgeComponent.self, BridgeComponentSpy.self])
        
        bridge = BridgeSpy()
        delegate.bridge = bridge
        delegate.onViewDidLoad()
    }
    
    func testBridgeDidInitialize() {
        delegate.bridgeDidInitialize()
        
        XCTAssertTrue(bridge.registerComponentsWasCalled)
        XCTAssertEqual(bridge.registerComponentsArg, ["one", "two"])
     
        // Registered components are lazy initialized.
        let componentOne: BridgeComponentSpy? = delegate.component()
        let componentTwo: BridgeComponentSpy? = delegate.component()
        XCTAssertNil(componentOne)
        XCTAssertNil(componentTwo)
    }
    
    func testBridgeDidReceiveMessage() {
        let json = """
            {"title":"Page-title","subtitle":"Page-subtitle"}
        """
        let message = Message(id: "1",
                              component: "two",
                              event: "connect",
                              metadata: .init(url: "https://37signals.com"),
                              jsonData: json)
        
        var component: BridgeComponentSpy? = delegate.component()
        
        XCTAssertNil(component)
        XCTAssertTrue(delegate.bridgeDidReceiveMessage(message))
        
        component = delegate.component()
        
        XCTAssertNotNil(component)
        // Make sure the component has delegate set, and did receive the message.
        XCTAssertTrue(component!.onReceiveMessageWasCalled)
        XCTAssertEqual(component?.onReceiveMessageArg, message)
        XCTAssertNotNil(component?.delegate)
    }
    
    func testBridgeIgnoresMessageForUnknownComponent() {
        let json = """
            {"title":"Page-title","subtitle":"Page-subtitle"}
        """
        let message = Message(id: "1",
                              component: "page",
                              event: "connect",
                              metadata: .init(url: "https://37signals.com/another_url"),
                              jsonData: json)
        
        XCTAssertFalse(delegate.bridgeDidReceiveMessage(message))
    }
    
    func testBridgeIgnoresMessageForInactiveDestination() {
        let message = Message(id: "1",
                              component: "one",
                              event: "connect",
                              metadata: .init(url: "https://37signals.com"),
                              jsonData: json)
        
        XCTAssertTrue(delegate.bridgeDidReceiveMessage(message))
        
        var component: OneBridgeComponent? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewDidDisappear()
        XCTAssertFalse(delegate.bridgeDidReceiveMessage(message))
        
        component = delegate.component()
        XCTAssertNil(component)
    }
    
    func testBridgeForwardsViewWillAppearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewWillAppear()
        XCTAssertTrue(component!.onViewWillAppearWasCalled)
    }
    
    func testBridgeForwardsViewDidAppearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)

        delegate.onViewDidAppear()
        XCTAssertTrue(component!.onViewDidAppearWasCalled)
    }
    
    func testBridgeForwardsViewWillDisappearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewWillDisappear()
        XCTAssertTrue(component!.onViewWillDisappearWasCalled)
    }
    
    func testBridgeForwardsViewDidDisappearToComponents() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewDidDisappear()
        XCTAssertTrue(component!.onViewDidDisappearWasCalled)
    }
    
    func testBridgeDestinationIsActiveAfterViewWillDisappearIsCalled() {
        delegate.bridgeDidReceiveMessage(testMessage())
        
        let component: BridgeComponentSpy? = delegate.component()
        XCTAssertNotNil(component)
        
        delegate.onViewWillDisappear()
        XCTAssertTrue(delegate.bridgeDidReceiveMessage(testMessage()))
    }
    
    // MARK: reply(with:)
   
    func test_replyWithSucceedsWhenBridgeIsSet() {
        let message = testMessage()
        let success = delegate.reply(with: message)
        
        XCTAssertTrue(success)
        XCTAssertTrue(bridge.replyWithMessageWasCalled)
        XCTAssertEqual(bridge.replyWithMessageArg, message)
    }
    
    func test_replyWithFailsWhenBridgeNotSet() {
        delegate.bridge = nil

        let message = testMessage()
        let success = delegate.reply(with: message)

        XCTAssertFalse(success)
        XCTAssertFalse(bridge.replyWithMessageWasCalled)
        XCTAssertNil(bridge.replyWithMessageArg)
    }
    
    private func testMessage() -> Message {
        return Message(id: "1",
                       component: "two",
                       event: "connect",
                       metadata: .init(url: "https://37signals.com"),
                       jsonData: json)
    }
}
