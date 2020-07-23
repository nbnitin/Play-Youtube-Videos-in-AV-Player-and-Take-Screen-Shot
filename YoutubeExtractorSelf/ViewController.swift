//
//  ViewController.swift
//  YoutubeExtractorSelf
//
//  Created by Nitin on 03/07/20.
//  Copyright © 2020 Nitin. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    //variables
    var playerLayer: AVPlayerLayer!
    var player : AVPlayer!
    var pro : DispatchQueue = DispatchQueue(label: "takeScreenShot")
    
    //outlets
    @IBOutlet weak var imgScreenShot: UIImageView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var btnCapture: UIButton!/*{
        didSet{
                btnCapture.setTitle("Capturing...", for: .disabled)
                btnCapture.setTitle("Capture Video", for: .normal)
           }
    }*/
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let youtube = YoutubeExtractor()
        
        youtube.extractInfo(for: .urlString("https://www.youtube.com/watch?v=dyCa82fY84I"), success: { info in
            DispatchQueue.main.async {
                print("end date",Date())
                
                
                self.player = AVPlayer(url: URL(string:info.highestQualityPlayableLink!)!)
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer.frame = self.playerView.bounds
                self.playerView.layer.addSublayer(self.playerLayer)
                self.player.play()
                self.activity.stopAnimating()
            }
        }) { error in
            print(error)
        }
        
//        btnCapture.setTitle("Capturing...", for: .disabled)
//        btnCapture.setTitle("Capture Video", for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

       
    }
    
    
    @IBAction func takeScreenShot(_ sender: Any) {
        
        if ( activity.isAnimating ) {
            return
        }
        
        pro.async {
            DispatchQueue.main.async {
                self.screenShotMethod()
            }
            
        }
        
    }
    
    private func screenShotMethod()
    {
        
        if let url = (player.currentItem?.asset as? AVURLAsset)?.url {
            btnCapture.isEnabled = false

            let asset = AVAsset(url: url)
            
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.requestedTimeToleranceAfter = player.currentTime()
            imageGenerator.requestedTimeToleranceBefore = player.currentTime()
            
            if let thumb: CGImage = try? imageGenerator.copyCGImage(at: player.currentTime(), actualTime: nil) {
                
                //print("video img successful")
                imgScreenShot.image = UIImage(cgImage: thumb)
                btnCapture.isEnabled = true
            } else {
                btnCapture.isEnabled = true
            }
            
            
        }
    }
}

