//
//  SplashViewController.swift
//  TicTacToe
//
//  Created by Ramon RODRIGUEZ on 2/13/17.
//  Copyright © 2017 Ramon Rodriguez. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    let imageSize = 105
    let imageCount = 5
    let maxX = 375 - 105
    var imageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runAnimations()
    }


    private func runAnimations() {
        
            let xLocation: CGFloat = CGFloat(arc4random_uniform(UInt32(maxX)))
            let image = (isEven(number: imageIndex)) ? #imageLiteral(resourceName: "TicTacToeO-Pink") : #imageLiteral(resourceName: "TicTacToeX-Blue")
            animateImage(xLocation: xLocation, image: image)
 

    }
    
    
    
    private func animateImage(xLocation: CGFloat, image: UIImage) {
        // create new game piece image, center in game slot
        let newImageView = UIImageView(frame: CGRect(x: xLocation, y: -200, width: CGFloat(imageSize), height: CGFloat(imageSize)))
        
        // make image either X or O and add to view
        newImageView.image = image
        self.view.addSubview(newImageView)

        // animate
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseOut], animations: {
            newImageView.center.y += (self.view.bounds.height * 2)
        }, completion: {finished in
            self.imageIndex += 1
            if (self.imageIndex < imageCount) {
                let xLocation: CGFloat = CGFloat(arc4random_uniform(UInt32(self.maxX)))
                let image = (self.isEven(number: self.imageIndex)) ? #imageLiteral(resourceName: "TicTacToeO-Pink") : #imageLiteral(resourceName: "TicTacToeX-Blue")
                self.animateImage(xLocation: xLocation, image: image)
                
            } else {
                self.performSegue(withIdentifier: "gameStart", sender: nil)
            }
            
            })
        
    }
    
    private func isEven(number: Int) -> Bool {
        return number % 2 == 0
    }
 
    
//    // MARK: - Navigation
//
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//        
//        
//        
//    }
    

}
