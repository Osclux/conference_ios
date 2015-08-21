//
//  ViewController.swift
//  HelloWorld
//
//  Created by Patrick Quinn-Graham on 3/06/2014.
//  Copyright (c) 2014 TokBox, Inc. All rights reserved.
//

import UIKit

let videoWidth : CGFloat = 320
let videoHeight : CGFloat = 240

// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key
let ApiKey = "45242822"
// Replace with your generated session ID
//let SessionID = "2_MX40NTI0MjgyMn5-MTQzNzY0ODUzMzcwNn5wSUJ5UWFvMTBzMG1nK3dVSE1GdVBYcXR-UH4"
// Replace with your generated token
//let Token = "T1==cGFydG5lcl9pZD00NTI0MjgyMiZzaWc9OGFiN2E0NGRjZDcxMmYwOThlNjBjNWUxZWQ5OGRkMDJhZjk1MzMxZDpzZXNzaW9uX2lkPTJfTVg0ME5USTBNamd5TW41LU1UUXpOelkwT0RVek16Y3dObjV3U1VKNVVXRnZNVEJ6TUcxbkszZFZTRTFHZFZCWWNYUi1VSDQmY3JlYXRlX3RpbWU9MTQzNzY1MTU4OSZub25jZT05MTcwNDc4NTQmcm9sZT1wdWJsaXNoZXImZXhwaXJlX3RpbWU9MTQzNzczNzk4OQ=="

// Change to YES to subscribe to your own stream.
let SubscribeToSelf = false

let ServerUrl = "http://88.80.175.129:4567/"
let ServerRoomNamePath = "session/"

class ViewController: UIViewController, OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate {
    
    @IBOutlet weak var otherVideoView: UIView!
    @IBOutlet weak var selfVideoView: UIView!
    @IBOutlet weak var exitCallButton: UIButton!
    
    
    var session : OTSession?
    var publisher : OTPublisher?
    var subscriber : OTSubscriber?
    let panRecognizer = UIPanGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panRecognizer.addTarget(self, action: Selector("handlePan:"))
        //panRecognizer.delaysTouchesEnded = false
        //self.view.addGestureRecognizer(panRecognizer)

        
    }
    
    override func viewWillAppear(animated: Bool) {
        // Step 2: As the view comes into the foreground, begin the connection process.
//        doConnect()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        // First ask the user for a chat room name.
        showEnterChatRoomNameDialog()
        

    }
    
    func showEnterChatRoomNameDialog() {
        let dialogController: UIAlertController = UIAlertController(title: "Anslut till chatrum", message: "Ange namnet på det chatrum du vill ansluta dig till.", preferredStyle: .Alert)

        dialogController.addTextFieldWithConfigurationHandler { textField -> Void in
            //TextField configuration
//            textField.textColor = UIColor.blueColor()
//            textFieldInDialog = textField
        }

        let connectAction: UIAlertAction = UIAlertAction(title: "Anslut", style: .Default) { action -> Void in
            let textField : UITextField = dialogController.textFields![0] as! UITextField
            NSLog("Connect to chatroom \(textField.text)")

            self.doConnectToChatRoom(textField.text)
            
        }
        dialogController.addAction(connectAction)
        self.presentViewController(dialogController, animated: true, completion: nil)
        
    }
    
    func doConnectToChatRoom(roomName: String) {
        // First ask our server for the details to connect to that chat room.
        let url = NSURL(string: ServerUrl + ServerRoomNamePath  + "/" + roomName)
        
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            var error: AutoreleasingUnsafeMutablePointer<NSError?> = nil
            let jsonResult: NSDictionary! = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: error) as? NSDictionary
            
            if (jsonResult != nil) {
                let token = jsonResult["token"] as! String
                let sessionId = jsonResult["sessionId"] as! String
                NSLog("########## token=\(token)")
                NSLog("########## sessionId=\(sessionId)")
                self.doConnectOpenTok(sessionId, token: token)
            } else {
                // couldn't load JSON, look at error
                self.showAlert("Error loading chat room data")
            }

//            let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
//            NSLog("Chat room details = \(dataString)")

        }
        
        task.resume()
        
        
    }
    
    
    @IBAction func onExitCallButton(sender: AnyObject) {
        NSLog("Exit Call");
        if let s = session {
            var maybeError : OTError?
            s.disconnect(&maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            } else {
                if let publisherView = publisher?.view {
                    publisherView.removeFromSuperview()
                }
                if let subscriberView = subscriber?.view {
                    subscriberView.removeFromSuperview()
                    subscriber = nil
                }
            }
            
            showEnterChatRoomNameDialog()
        }
    }
    
    // MARK: - OpenTok Methods

    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    func doConnectOpenTok(sessionId: String, token: String) {
        session = OTSession(apiKey: ApiKey, sessionId: sessionId, delegate: self)
        if let session = self.session {
            var maybeError : OTError?
            session.connectWithToken(token, error: &maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            }
        }
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    func doPublish() {
        publisher = OTPublisher(delegate: self)
        
        var maybeError : OTError?
        session?.publish(publisher, error: &maybeError)
        
        if let error = maybeError {
            showAlert(error.localizedDescription)
        }
        
        selfVideoView.addSubview(publisher!.view)
        publisher!.view.frame = CGRect(x: 0.0, y: 0, width: selfVideoView.frame.width, height: selfVideoView.frame.height)
    }

    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    func doSubscribe(stream : OTStream) {
        if let session = self.session {
            subscriber = OTSubscriber(stream: stream, delegate: self)

            var maybeError : OTError?
            session.subscribe(subscriber, error: &maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            }
            
        }
    }
    
    /**
     * Cleans the subscriber from the view hierarchy, if any.
     */
    func doUnsubscribe() {
        if let subscriber = self.subscriber {
            var maybeError : OTError?
            session?.unsubscribe(subscriber, error: &maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            }
            
            subscriber.view.removeFromSuperview()
            self.subscriber = nil
        }
    }
    
    // MARK: - OTSession delegate callbacks
    
    
    func sessionDidConnect(session: OTSession) {
        NSLog("sessionDidConnect (\(session.sessionId))")

        // Step 2: We have successfully connected, now instantiate a publisher and
        // begin pushing A/V streams into OpenTok.
        doPublish()
    }
    
    func sessionDidDisconnect(session : OTSession) {
        NSLog("Session disconnected (\( session.sessionId))")
    }
    
    func session(session: OTSession, streamCreated stream: OTStream) {
        NSLog("session streamCreated (\(stream.streamId))")

        // Step 3a: (if NO == subscribeToSelf): Begin subscribing to a stream we
        // have seen on the OpenTok session.
        if subscriber == nil && !SubscribeToSelf {
            doSubscribe(stream)
        }
    }
    
    func session(session: OTSession, streamDestroyed stream: OTStream) {
        NSLog("session streamCreated (\(stream.streamId))")
        
        if subscriber?.stream.streamId == stream.streamId {
            doUnsubscribe()
        }
    }
    
    func session(session: OTSession, connectionCreated connection : OTConnection) {
        NSLog("session connectionCreated (\(connection.connectionId))")
    }
    
    func session(session: OTSession, connectionDestroyed connection : OTConnection) {
        NSLog("session connectionDestroyed (\(connection.connectionId))")
    }
    
    func session(session: OTSession, didFailWithError error: OTError) {
        NSLog("session didFailWithError (%@)", error)
    }
    
    func session(session: OTSession, receivedSignalType type: String, fromConnection :OTConnection, withString: String){
        NSLog("Received \(type) \(withString)")
    }
    
    // MARK: - OTSubscriber delegate callbacks
    
    func subscriberDidConnectToStream(subscriberKit: OTSubscriberKit) {
        NSLog("subscriberDidConnectToStream (\(subscriberKit))")
        
        if let view = subscriber?.view {
            //view.userInteractionEnabled = false
            let videoDim = subscriberKit.stream.videoDimensions;
            NSLog("video dimensions w:\(videoDim.width) h:\(videoDim.height)")
            //view.frame =  CGRect(x: 0.0, y: videoHeight, width: videoWidth, height: videoHeight)
            view.frame =  CGRect(x: 0.0, y: 0, width: otherVideoView.frame.width, height: otherVideoView.frame.height)
            view.addGestureRecognizer(panRecognizer)
            self.otherVideoView.addSubview(view)
            
            
        }
    }
    
    func subscriber(subscriber: OTSubscriberKit, didFailWithError error : OTError) {
        NSLog("subscriber %@ didFailWithError %@", subscriber.stream.streamId, error)
    }
    
    // MARK: - OTPublisher delegate callbacks
    
    func publisher(publisher: OTPublisherKit, streamCreated stream: OTStream) {
        NSLog("publisher streamCreated %@", stream)

        // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
        // all participants in the OpenTok session. We will attempt to subscribe to
        // our own stream. Expect to see a slight delay in the subscriber video and
        // an echo of the audio coming from the device microphone.
        if subscriber == nil && SubscribeToSelf {
            doSubscribe(stream)
        }
    }
    
    func publisher(publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        NSLog("publisher streamDestroyed %@", stream)
        
        if subscriber?.stream.streamId == stream.streamId {
            doUnsubscribe()
        }
    }
    
    func publisher(publisher: OTPublisherKit, didFailWithError error: OTError) {
        NSLog("publisher didFailWithError %@", error)
    }
    
    // MARK: - Helpers

    func showAlert(message: String) {
        // show alertview on main UI
        dispatch_async(dispatch_get_main_queue()) {
            let al = UIAlertView(title: "OTError", message: message, delegate: nil, cancelButtonTitle: "OK")
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        testTouches(touches)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        testTouches(touches)
        // Send rotate command based on movement speed
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        testTouches(touches)
        // Send stop rotating event
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        NSLog("cancelled")
    }
    
    func testTouches(touches: Set<NSObject>) {
        // Get the first touch and its location in this view controller's view coordinate system
        //let touch = touches.first as! UITouch
        for touch: AnyObject in touches {
            //if (touch.view == subscriber?.view) {
            if let subscriberView = subscriber?.view {
                let touchView = touch.view
                //NSLog("Subscriber view \(subscriberView)")
                let touchLocation = touch.locationInView(subscriberView)
                
                //NSLog("Touch in view \(touchView)")
                if (isTouchInSubscriberView(touch as! UITouch)) {
                    NSLog("Touch in subscriber at \(touchLocation.x),\(touchLocation.y)")
                }
            }
        }

    }
    
    func isTouchInSubscriberView(touch: UITouch) -> Bool {
        if let subscriberView = subscriber?.view {
            return subscriberView.bounds.contains(touch.locationInView(subscriberView))
        }
        return false
    }
    
    func handlePan(sender:UIPanGestureRecognizer) {
        let v = sender.velocityInView(subscriber!.view)
        let t = sender.translationInView(subscriber!.view)
        let vString = Int(round(v.x)).description
        NSLog("Pan velocity x \(vString)")
        NSLog("Pan translation \(t)")
        sendPanSignal(vString)
        

    }
    
    func sendPanSignal(panString: String) {
        if let subscriber = self.subscriber {
            var maybeError : OTError?
            session?.signalWithType("pan", string: panString,
                connection: subscriber.stream.connection, error: &maybeError)
            if let error = maybeError {
                showAlert(error.localizedDescription)
            }
        }
    }
    
}

