//
//  ViewController.swift
//  Trackpadding-macOS
//
//  Created by TakahiroNagai on 2020/11/25.
//

import Cocoa
import MultipeerConnectivity
import CoreGraphics

class ViewController: NSViewController, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate {
    
    // MARK: - Properties
    var mcPeerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiser: MCNearbyServiceAdvertiser!
    
    var displayWidth: CGFloat = 0
    var displayHeight: CGFloat = 0
    
    var peersDisplayName = ""

    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screens = NSScreen.screens
        for screen in screens {
            displayWidth = max(NSWidth(screen.frame), displayWidth)
            displayHeight = max(NSHeight(screen.frame), displayHeight)
        }
        
        startMCSession()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: - User Interface
    @IBAction func clickResetButton(_ sender: NSClickGestureRecognizer) {
        stopMCSession()
        startMCSession()
    }
    
    // MARK: - Function
    /// - Tag: MultipeerConnectivity
    func startMCSession() {
        mcPeerID = MCPeerID.init(displayName: Host.current().name!)
        mcSession = MCSession.init(peer: mcPeerID!)
        mcSession.delegate = self
        mcAdvertiser = MCNearbyServiceAdvertiser.init(peer: mcPeerID, discoveryInfo: nil, serviceType: "trackpadding")
        mcAdvertiser.delegate = self
        mcAdvertiser.startAdvertisingPeer()
    }
    
    func stopMCSession() {
        mcAdvertiser.stopAdvertisingPeer()
        mcSession.disconnect()
    }
    
    /// - Tag: CGEvent
    func postClickEvent(type: CGEventType, button: CGMouseButton) {
        var mouseLocation = NSEvent.mouseLocation
        mouseLocation = CGPoint(x: mouseLocation.x, y: displayHeight - mouseLocation.y)
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: mouseLocation, mouseButton: button)
        event?.post(tap: .cghidEventTap)
    }
    
    func postMoveEvent(dx: CGFloat, dy: CGFloat) {
        var mouseLocation = NSEvent.mouseLocation
        mouseLocation = CGPoint(x: mouseLocation.x + dx * 0.5, y: displayHeight - mouseLocation.y + dy * 0.5)
        mouseLocation.x = min(max(0, mouseLocation.x), displayWidth)
        mouseLocation.y = min(max(0, mouseLocation.y), displayHeight)
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent.init(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: mouseLocation, mouseButton: .left)
        event?.post(tap: .cghidEventTap)
    }
    
    func postScrollEvent(dx: Int32, dy: Int32) {
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 1, wheel1: dy, wheel2: dx, wheel3: 0)
        event?.post(tap: .cghidEventTap)
    }
    
    /// - Tag: Utility
    func stringToCGFloat(x: NSString, y: NSString) -> (CGFloat, CGFloat) {
        let dx = CGFloat(x.floatValue)
        let dy = CGFloat(y.floatValue)
        return (dx, dy)
    }
    
    // MARK: - Delegate
    /// - Tag: MCSessionDelegate
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let str: String = String.init(data: data, encoding: .utf8)!
        let array = str.components(separatedBy: " ")
        
        switch array[0] {
        case "1Tap":
            postClickEvent(type: .leftMouseDown, button: .left)
            postClickEvent(type: .leftMouseUp, button: .left)
            
        case "2Tap":
            postClickEvent(type: .rightMouseDown, button: .right)
            postClickEvent(type: .rightMouseUp, button: .right)
            
        case "1Pan":
            let (dx, dy) = stringToCGFloat(x: array[1] as NSString, y: array[2] as NSString)
            postMoveEvent(dx: dx, dy: dy)
            
        case "2Pan":
            let (dx, dy) = stringToCGFloat(x: array[1] as NSString, y: array[2] as NSString)
            postScrollEvent(dx: Int32(dx), dy: Int32(dy))
            
            
        default:
            print("Data was not sent correctly")
        }
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    }
    /// - Tag: MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }


}

