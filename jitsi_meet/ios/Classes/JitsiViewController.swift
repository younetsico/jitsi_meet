import UIKit
import JitsiMeetSDK

class JitsiViewController: UIViewController {
    
    @IBOutlet weak var videoButton: UIButton?
    
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?
    var url :  String = ""
    
    var eventSink:FlutterEventSink? = nil
    var roomName:String? = nil
    var serverUrl:URL? = nil
    var subject:String? = nil
    var audioOnly:Bool? = false
    var audioMuted: Bool? = false
    var videoMuted: Bool? = false
    var token:String? = nil
    var isInPictureInPicture: Bool = false
    var featureFlags: Dictionary<String, Any>? = Dictionary();
    
    
    let jistiMeetUserInfo = JitsiMeetUserInfo()
    
    override func loadView() {
        
        super.loadView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        var mutatedData : [AnyHashable : Any]
        mutatedData = ["event":"onJitSiClosed","url":url]
        self.eventSink?(mutatedData)
    }
    
    @objc func openButtonClicked(sender : UIButton){
        
        //openJitsiMeetWithOptions();
    }
    
    @objc func closeButtonClicked(sender : UIButton){
        cleanUp();
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        //print("VIEW DID LOAD")
        self.view.backgroundColor = UIColor.red.withAlphaComponent(0)
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        openJitsiMeet();
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        pipViewCoordinator?.resetBounds(bounds: rect)
    }
    
    // This is needed to avoid the Flutter view behind it, to be hit by touch events.
    // See:
    // https://github.com/flutter/flutter/issues/14720
    // https://github.com/flutter/flutter/issues/35784#issuecomment-516243057
     open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(isInPictureInPicture){
            super.touchesBegan(touches, with: event)
        }
     }
    
    func openJitsiMeet() {
        cleanUp()
        // create and configure jitsimeet view
        let jitsiMeetView = JitsiMeetView()
        
        
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.welcomePageEnabled = true
            builder.room = self.roomName
            builder.serverURL = self.serverUrl
            builder.userInfo = self.jistiMeetUserInfo
            builder.setAudioOnly(self.audioOnly ?? false)
            builder.setAudioMuted(self.audioMuted ?? false)
            builder.setVideoMuted(self.videoMuted ?? false)
            if(self.subject != nil){
                builder.setSubject(self.subject!)
            }
            
            builder.token = self.token
            
            self.featureFlags?.forEach{ key,value in
                builder.setFeatureFlag(key, withValue: value);
                
            }
            
        }
        
        
        jitsiMeetView.join(options)
        
        // Enable jitsimeet view to be a view that can be displayed
        // on top of all the things, and let the coordinator to manage
        // the view state and interactions
        pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        pipViewCoordinator?.configureAsStickyView(withParentView: view)
        
        // animate in
        jitsiMeetView.alpha = 0
        pipViewCoordinator?.show()
    }
    
    func closeJitsiMeeting(){
        jitsiMeetView?.leave()
    }

    
    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
        
        //self.dismiss(animated: true, completion: nil)
    }
}

extension JitsiViewController: JitsiMeetViewDelegate {
    
    func conferenceWillJoin(_ data: [AnyHashable : Any]!) {
        //        print("CONFERENCE WILL JOIN")
        var mutatedData = data
        mutatedData?.updateValue("onConferenceWillJoin", forKey: "event")
        self.eventSink?(mutatedData)
    }
    
    func conferenceJoined(_ data: [AnyHashable : Any]!) {
        //        print("CONFERENCE JOINED")
        var mutatedData = data
        mutatedData?.updateValue("onConferenceJoined", forKey: "event")
        self.eventSink?(mutatedData)
    }
    
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        //        print("CONFERENCE TERMINATED")
        var mutatedData = data
        mutatedData?.updateValue("onConferenceTerminated", forKey: "event")
        self.eventSink?(mutatedData)
        
        DispatchQueue.main.async {
            self.pipViewCoordinator?.hide() { _ in
                self.cleanUp()
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        //        print("CONFERENCE PIP IN")
        var mutatedData = data
        mutatedData?.updateValue("onPictureInPictureWillEnter", forKey: "event")
        self.eventSink?(mutatedData)
        isInPictureInPicture = true
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }
    
    func exitPicture() {
                print("CONFERENCE PIP OUT")
        
        var mutatedData : [AnyHashable : Any]
        
        mutatedData = ["event":"onPictureInPictureTerminated","url":url]
        self.eventSink?(mutatedData)
        isInPictureInPicture = false
        DispatchQueue.main.async {
            self.pipViewCoordinator?.exitPictureInPicture()
        }
    }
}

