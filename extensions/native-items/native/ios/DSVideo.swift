import UIKit
import AVKit
import AVFoundation

extension Extension.NativeItems {
    class VideoItem: NativeItem {
        override class var name: String { return "DSVideo" }

        override class func register() {
            onCreate() {
                return VideoItem()
            }

            onSet("source") {
                (item: VideoItem, val: String) in
                item.setSource(val: val)
            }

            onSet("loop") {
                (item: VideoItem, val: Bool) in
                item.loop = val
            }

            onCall("start") {
                (item: VideoItem, args: [Any?]) in
                item.running = true
                item.player?.seek(to: kCMTimeZero)
                item.player?.play()
            }

            onCall("stop") {
                (item: VideoItem, args: [Any?]) in
                item.running = false
                item.player?.pause()
            }
        }

        var player: AVPlayer?
        var layer: AVPlayerLayer?
        var loop = false
        var running = false

        override var width: CGFloat {
            didSet {
                super.width = width
                updatePlayerSize()
            }
        }

        override var height: CGFloat {
            didSet {
                super.height = height
                updatePlayerSize()
            }
        }

        override init(view: UIView = UIView()) {
            super.init(view: view)
        }

        private func updatePlayerSize() {
            layer?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }

        @objc func playerItemDidReachEnd(notification: Notification) {
            if loop {
                player?.seek(to: kCMTimeZero)
                player?.play()
            }
        }

        func setSource(val: String) {
            layer?.removeFromSuperlayer()
            player = nil
            layer = nil

            let url = URL(string: val)
            guard url != nil else { return }

            player = AVPlayer(url: url!)
            layer = AVPlayerLayer(player: player)
            updatePlayerSize()
            view.layer.addSublayer(layer!)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidReachEnd(notification:)),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: player!.currentItem
            )

            if running {
                player?.play()
            }
        }
    }
}
