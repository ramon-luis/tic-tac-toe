//
//  ViewController.swift
//  TicTacToe
//
//  Created by Ramon RODRIGUEZ on 2/6/17.
//  Copyright © 2017 Ramon Rodriguez. All rights reserved.
//

import UIKit
import AVFoundation

class GameViewController: UIViewController {
    

    // enum for status of a game slot
    enum Piece {
        case x
        case o
        case open
    }
    
    // -MARK: Properties
    // game slots (places to draw an x or o): stored from left to right, top to bottom
    var gameSlotViews = [UIView]()
    var gameSlotPieceImageViews = [UIImageView]()
    var gameSlotPieces = [Piece]()
    
    // track current player
    var bIsXTurn = false
    var currentPlayerImage = #imageLiteral(resourceName: "TicTacToeX-Blue")
    var winningPlayer: Piece = Piece.open  // not x or o to start
    
    // params of game peices
    var gamePieceWidth = 105
    var xPieceStartX: CGFloat = 5
    var xPieceStartY: CGFloat = 100
    var oPieceStartX: CGFloat = 265
    var oPieceStartY: CGFloat = 100
    
    // key info to calculate start and end points of winning line (no magic numbers)
    let gameBoardEdgeX: CGFloat = 10.0
    let gameBoardEdgeY: CGFloat = 245
    let overlap: CGFloat = 5.0
    let gameBoardWidth: CGFloat = 355.0 // same for height: gameboard is a square
    let gameBoardSectionCount: CGFloat = 3.0
    let winningLine = CAShapeLayer()
    
    // sound references
    var audioPlayer = AVAudioPlayer()
    var startMoveSound = URL(fileURLWithPath: Bundle.main.path(forResource: "goodMove", ofType: "wav")!)
    var goodMoveSound = URL(fileURLWithPath: Bundle.main.path(forResource: "startMove", ofType: "wav")!)
    var badMoveSound = URL(fileURLWithPath: Bundle.main.path(forResource: "badMove", ofType: "wav")!)
    var tieGameSound = URL(fileURLWithPath: Bundle.main.path(forResource: "tieGame", ofType: "wav")!)
    var winGameSound = URL(fileURLWithPath: Bundle.main.path(forResource: "winGame", ofType: "wav")!)
    
    // connections to game pieces
    @IBOutlet weak var xImageView: UIImageView!
    @IBOutlet weak var oImageView: UIImageView!
    
    // connections to game slot views
    @IBOutlet weak var aaView: UIView!  // aa = top row, top column
    @IBOutlet weak var abView: UIView!
    @IBOutlet weak var acView: UIView!
    @IBOutlet weak var baView: UIView!
    @IBOutlet weak var bbView: UIView!
    @IBOutlet weak var bcView: UIView!
    @IBOutlet weak var caView: UIView!
    @IBOutlet weak var cbView: UIView!
    @IBOutlet weak var ccView: UIView!

    // connections to game play instruction views
    @IBOutlet weak var fuzzyView: UIView!
    @IBOutlet weak var gameInfoView: UIView!
    @IBOutlet weak var gameInfoLabel: UILabel!
    @IBOutlet weak var closeGameInfoButton: UIButton!
    

    // ***********************************************************
    // ******                VIEW DID LOAD                  ******
    // ***********************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startNewGame()
    }
    
    // ***********************************************************
    // ******        METHODS TO INITIALIZE NEW GAME         ******
    // ***********************************************************
    
    // start new game
    private func startNewGame() {
        clearAnyGamePlayVisuals()
        resetGameSlotViews()
        resetAllGameSlotsAsOpen()
        resetGamePieceStartingLocations()
        resetGameInfoScreen()
        resetFirstPlayerAsX()
    }
    
    // get rid of any images from pieces played or winning line
    private func clearAnyGamePlayVisuals() {
        // remove all gameSlotImageViews
        for imageView in gameSlotPieceImageViews {
            imageView.removeFromSuperview()
        }
        
        // remove winning line
        winningLine.removeFromSuperlayer()
    }
    
    // set the game slot views: manages the imageViews that are assigned game piece images
    private func resetGameSlotViews(){
        gameSlotViews.removeAll()
        gameSlotViews = [aaView, abView, acView,
                         baView, bbView, bcView,
                         caView, cbView, ccView]
    }
    
    // set game slots as open: manages what piece is in which location
    private func resetAllGameSlotsAsOpen() {
        gameSlotPieces.removeAll()
        gameSlotPieces = [Piece.open, Piece.open, Piece.open,
                          Piece.open, Piece.open, Piece.open,
                          Piece.open, Piece.open, Piece.open]
    }
    
    // reset starting location of game piece images
    private func resetGamePieceStartingLocations() {
        xImageView.frame.origin.x = xPieceStartX
        xImageView.frame.origin.y =  xPieceStartY
        oImageView.frame.origin.x = oPieceStartX
        oImageView.frame.origin.y = oPieceStartY
        oImageView.isHidden = false
        xImageView.isHidden = false
    }
    
    // setup qualities of gameplay instructions
    private func resetGameInfoScreen() {
        // hide game play instruction screens
        gameInfoView.isHidden = true
        fuzzyView.isHidden = true
        hideGameInfo()
        
        // assign blur effect
        // - Attribution: http://stackoverflow.com/questions/30953201/adding-blur-effect-to-background-in-swift
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = fuzzyView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        fuzzyView.addSubview(blurEffectView)
    }
    
    // set X as first player and animate accordingly
    private func resetFirstPlayerAsX() {
        winningPlayer = Piece.open // no winner if X is taking first turn
        bIsXTurn = false
        switchPlayerTurn()
    }
    
    
    // ***********************************************************
    // ******      METHODS TO HANDLE PANNING GAME PLAY      ******
    // ***********************************************************
    
    // handle pan action
    // -Attribution: https://www.raywenderlich.com/76020/using-uigesturerecognizer-with-swift-tutorial
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        // update the imageView based on user panning
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
        
        // panning started: play sound
        if (recognizer.state == UIGestureRecognizerState.began) {
            playSound(url: startMoveSound)
        }
        
        // panning stopped: check if good move and then process move accordingly
        if (recognizer.state == UIGestureRecognizerState.ended) {
            // get the active piece
            if let activePiece = recognizer.view {
                // see if good move
                let isGoodMove = evaluateMove(movedGamePiece: activePiece)
                
                // check if game over, otherwise complete move: restore game piece images and switch player if was good move
                if (isGameOver()) {
                    processGameOver()
                } else {
                    completeMove(movedGamePiece: activePiece, isValidMove: isGoodMove)
                }
            }
        }
    }
    
    
    // ***********************************************************
    // ******       METHODS TO HANDLE PLACING PIECES        ******
    // ***********************************************************
    
    // checks if was a good move (places piece if it was before returning boolean)
    private func evaluateMove(movedGamePiece: UIView) -> Bool {
        // variables to check where piece was placed and if it was a good move
        var index = 0
        let lastGameSlotIndex = gameSlotViews.count
        
        // loop until a good move is made or all game slots have been checked
        while (index < lastGameSlotIndex) {
            // place piece in an open game slot or increment index to check more game slots
            if (isInOpenGameSlot(activePiece: movedGamePiece, index: index)) {
                placeGamePiece(index: index)  // place game piece
                return true  // found open slot & placed piece: good move
            } else {
                index += 1  // increment: check if other gameSlots contain piece
            }
        }
        
        // completed loop with no match: bad move
        return false
    }
    
    // check if the game piece was released inside an open game slot
    private func isInOpenGameSlot(activePiece: UIView, index: Int) -> Bool {
        let isValidPosition = gameSlotViews[index].frame.contains(activePiece.frame)
        let isOpenPosition = (gameSlotPieces[index] == Piece.open)
        return isValidPosition && isOpenPosition
    }
    
    // place a game piece in a game slot
    private func placeGamePiece(index: Int) {
        // create new game piece image, center in game slot
        let newImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: CGFloat(gamePieceWidth), height: CGFloat(gamePieceWidth)))
        newImageView.center.x = gameSlotViews[index].center.x
        newImageView.center.y = gameSlotViews[index].center.y
        
        // make image either X or O and add to view
        newImageView.image = (bIsXTurn) ? #imageLiteral(resourceName: "TicTacToeX-Blue") : #imageLiteral(resourceName: "TicTacToeO-Pink")
        self.view.addSubview(newImageView)
        
        // play sound
        playSound(url: goodMoveSound)
        
        // update piece in game slot so future pieces can't be placed there
        gameSlotPieces[index] = (bIsXTurn) ? Piece.x : Piece.o
        
        // store in imageViews so that it can be deleted on new game
        gameSlotPieceImageViews.append(newImageView)
    }
    
    // set gamepiece back to original location
    private func completeMove(movedGamePiece: UIView, isValidMove: Bool) {
        // if bad move, then animate back to starting spot
        if (!isValidMove) {
            playSound(url: badMoveSound)
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseInOut], animations: {
                movedGamePiece.frame.origin.x = (self.bIsXTurn) ? self.xPieceStartX : self.oPieceStartX
                movedGamePiece.frame.origin.y = (self.bIsXTurn) ? self.xPieceStartY : self.oPieceStartY
            }, completion: nil)
        } else {
            // just make pieces show up at origin again and switch players
            movedGamePiece.frame.origin.x = (bIsXTurn) ? xPieceStartX : oPieceStartX
            movedGamePiece.frame.origin.y = (bIsXTurn) ? xPieceStartY : oPieceStartY
            switchPlayerTurn()
        }
    }
    
    
    // ***********************************************************
    // ******         METHODS TO CHANGE PLAYER TURNS        ******
    // ***********************************************************
    
    // switch the player turn
    private func switchPlayerTurn() {
        // switch current player
        bIsXTurn = !bIsXTurn
        
        // animate player pieces accordingly
        if bIsXTurn {
            activateCurrentPlayer(currentPlayerImageView: xImageView)
            deactivateLastPlayer(lastPlayerImageView: oImageView)
        } else {
            activateCurrentPlayer(currentPlayerImageView: oImageView)
            deactivateLastPlayer(lastPlayerImageView: xImageView)
        }
    }

    // activate current player peice: enable user interaction & high alpha
    private func activateCurrentPlayer(currentPlayerImageView: UIImageView) {
        currentPlayerImageView.isUserInteractionEnabled = true
        currentPlayerImageView.alpha = 1.0
        self.view.bringSubview(toFront: currentPlayerImageView)
        
        // animate: grow, then shrink
        // - Attribution: https://www.raywenderlich.com/76200/basic-uiview-animation-swift-tutorial
        UIView.animate(withDuration: 0.4, delay: 0, animations: {
            currentPlayerImageView.transform = CGAffineTransform(scaleX: 2, y: 2)
        }, completion: { finished in
            UIView.animate(withDuration: 0.2, delay: 0, animations: {
                currentPlayerImageView.transform = CGAffineTransform.identity
            })
        })
    }
    
    // deactivate last player piece: disable user interaction and low alpha
    private func deactivateLastPlayer(lastPlayerImageView: UIImageView) {
        lastPlayerImageView.isUserInteractionEnabled = false
        lastPlayerImageView.alpha = 0.5
    }
    
    
    // ***********************************************************
    // ******         METHODS TO CHECK IF GAME OVER         ******
    // ***********************************************************
    
    // check if either player wins or is cats game
    private func isGameOver() -> Bool {
        return isWinForX() || isWinForO() || isFullGameBoard()
        
    }
    
    // check if no more open game slots (i.e. all pieces played)
    private func isFullGameBoard() -> Bool {
        // loop through game slots to see if any are still open
        for gameSlot in gameSlotPieces {
            if gameSlot == Piece.open {
                return false
            }
        }
        return true
    }

    // check if X player wins
    private func isWinForX() -> Bool {
        return isTopAcrossWin(player: Piece.x) || isMiddleAcrossWin(player: Piece.x) || isBottomAcrossWin(player: Piece.x) || isLeftDownWin(player: Piece.x) || isMiddleDownWin(player: Piece.x) || isRightDownWin(player: Piece.x) || isTopLeftDiagonalWin(player: Piece.x) || isBottomLeftDiagonalWin(player: Piece.x)
    }
    
    // check if O player wins
    private func isWinForO() -> Bool {
        return isTopAcrossWin(player: Piece.o) || isMiddleAcrossWin(player: Piece.o) || isBottomAcrossWin(player: Piece.o) || isLeftDownWin(player: Piece.o) || isMiddleDownWin(player: Piece.o) || isRightDownWin(player: Piece.o) || isTopLeftDiagonalWin(player: Piece.o) || isBottomLeftDiagonalWin(player: Piece.o)
    }
    
    
    // ***********************************************************
    // ****  METHODS TO CHECK IF A PLAYER HAS THREE IN A ROW  ****
    // ***********************************************************
    
    private func isTopAcrossWin(player: Piece) -> Bool {
        return (gameSlotPieces[0] == player) && (gameSlotPieces[0] == gameSlotPieces[1]) && (gameSlotPieces[0] == gameSlotPieces[2])
    }
    
    private func isMiddleAcrossWin(player: Piece) -> Bool {
        return (gameSlotPieces[3] == player) && (gameSlotPieces[3] == gameSlotPieces[4]) && (gameSlotPieces[3] == gameSlotPieces[5])
    }
    
    private func isBottomAcrossWin(player: Piece) -> Bool {
        return (gameSlotPieces[6] == player) && (gameSlotPieces[6] == gameSlotPieces[7]) && (gameSlotPieces[6] == gameSlotPieces[8])
    }
    
    private func isLeftDownWin(player: Piece) -> Bool {
        return (gameSlotPieces[0] == player) && (gameSlotPieces[0] == gameSlotPieces[3]) && (gameSlotPieces[0] == gameSlotPieces[6])
    }
    
    private func isMiddleDownWin(player: Piece) -> Bool {
        return (gameSlotPieces[1] == player) && (gameSlotPieces[1] == gameSlotPieces[4]) && (gameSlotPieces[1] == gameSlotPieces[7])
    }
    
    private func isRightDownWin(player: Piece) -> Bool {
        return (gameSlotPieces[2] == player) && (gameSlotPieces[2] == gameSlotPieces[5]) && (gameSlotPieces[2] == gameSlotPieces[8])
    }
    
    private func isTopLeftDiagonalWin(player: Piece) -> Bool {
        return (gameSlotPieces[0] == player) && (gameSlotPieces[0] == gameSlotPieces[4]) && (gameSlotPieces[0] == gameSlotPieces[8])
    }
    
    private func isBottomLeftDiagonalWin(player: Piece) -> Bool {
        return (gameSlotPieces[6] == player) && (gameSlotPieces[6] == gameSlotPieces[4]) && (gameSlotPieces[6] == gameSlotPieces[2])
    }
    
    
    // ***********************************************************
    // ******         METHODS TO HANDLE GAME OVER           ******
    // ***********************************************************
    
    // handle game over
    func processGameOver() {
        // set winning player
        if (isWinForO()) {
            winningPlayer = Piece.o
        } else if (isWinForX()) {
            winningPlayer = Piece.x
        }
        
        // hide user game pieces
        xImageView.isHidden = true
        oImageView.isHidden = true
        
        // check if tie game
        let isTieGame = winningPlayer == Piece.open
        
        // if no tie, then draw winning line
        if (!isTieGame) {
            drawWinningLine()
            playSound(url: winGameSound)
            
        } else {
            playSound(url: tieGameSound)
        }
        
        // wait 2 seconds before showing summary info
        // - Attribution: http://stackoverflow.com/questions/24034544/dispatch-after-gcd-in-swift
        let deadlineTime = DispatchTime.now() + .seconds(2)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.updateGameInfoForGameOver()
            self.showGameInfo()
        }
    }
    
    // draw line for winner
    // - Attribution: http://stackoverflow.com/questions/40556112/how-to-draw-a-line-in-swift-3
    private func drawWinningLine() {
        // store x,y values for start and end points
        var startX: CGFloat = 0.0
        var startY: CGFloat = 0.0
        var endX: CGFloat = 0.0
        var endY: CGFloat = 0.0
        
        // store width of a game board "section"
        let gameBoardSectionWidth = gameBoardWidth / gameBoardSectionCount
        
        // set start and end x,y based on win type
        if (isTopAcrossWin(player: winningPlayer)) {
            startX = gameBoardEdgeX - overlap
            startY = gameBoardEdgeY + (gameBoardSectionWidth / 2)
            endX = gameBoardEdgeX + gameBoardWidth + overlap
            endY = startY
        } else if (isMiddleAcrossWin(player: winningPlayer)) {
            startX = gameBoardEdgeX - overlap
            startY = gameBoardEdgeY + (gameBoardWidth / 2)
            endX = gameBoardEdgeX + gameBoardWidth + overlap
            endY = startY
        } else if (isBottomAcrossWin(player: winningPlayer)) {
            startX = gameBoardEdgeX - overlap
            startY = gameBoardEdgeY  + gameBoardWidth - (gameBoardWidth / 2)
            endX = gameBoardEdgeX + gameBoardWidth + overlap
            endY = startY
        } else if (isLeftDownWin(player: winningPlayer)) {
            startX = gameBoardEdgeX + (gameBoardSectionWidth / 2)
            startY = gameBoardEdgeY - overlap
            endX = startX
            endY = gameBoardEdgeY + gameBoardWidth + overlap
        } else if (isMiddleDownWin(player: winningPlayer)) {
            startX = gameBoardEdgeX + (gameBoardWidth / 2)
            startY = gameBoardEdgeY - overlap
            endX = startX
            endY = gameBoardEdgeY + gameBoardWidth + overlap
        } else if (isRightDownWin(player: winningPlayer)) {
            startX = gameBoardEdgeX + gameBoardWidth - (gameBoardSectionWidth / 2)
            startY = gameBoardEdgeY - overlap
            endX = startX
            endY = gameBoardEdgeY + gameBoardWidth + overlap
        } else if (isTopLeftDiagonalWin(player: winningPlayer)) {
            startX = gameBoardEdgeX - overlap
            startY = gameBoardEdgeY - overlap
            endX = gameBoardEdgeX + gameBoardWidth + overlap
            endY = gameBoardEdgeY + gameBoardWidth + overlap
        } else if (isBottomLeftDiagonalWin(player: winningPlayer)) {
            startX = gameBoardEdgeX - overlap
            startY = gameBoardEdgeY + gameBoardWidth + overlap
            endX = gameBoardEdgeX + gameBoardWidth + overlap
            endY = gameBoardEdgeY - overlap
        }
        
        // assign start and end points
        let start: CGPoint = CGPoint(x: startX, y: startY)
        let end: CGPoint = CGPoint(x: endX, y: endY)
        
        // draw the line
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        winningLine.path = linePath.cgPath
        winningLine.strokeColor = UIColor.red.cgColor
        winningLine.lineWidth = 10
        winningLine.lineJoin = kCALineJoinRound
        self.view.layer.addSublayer(winningLine)
    }
    
    // update the game info
    func updateGameInfoForGameOver() {
        // determine the text to display based on winning player
        var gameOverText: String
        switch winningPlayer {
        case Piece.o:
            gameOverText = "O wins!"
        case Piece.x:
            gameOverText = "X wins!"
        case Piece.open:
            gameOverText = "Tie game."
        }
        
        // update the label and button title
        gameInfoLabel.text = gameOverText
        closeGameInfoButton.setTitle("Play Again", for: .normal)
    }
    
    
    // ***********************************************************
    // ******         METHODS FOR HOW-TO-PLAY SCREEN        ******
    // ***********************************************************
    
    // show game instructions
    @IBAction func howToPlay(_ sender: Any) {
        updateGameInfoForInstructions()
        showGameInfo()
    }
    
    // close the game info view
    @IBAction func closeGameInfo(_ sender: Any) {
        // if game over: start a new game, else close game info view
        if (isGameOver()) {
            startNewGame()
        } else {
            hideGameInfo()
        }
    }
    
    // get the version and build
    // - Attribution: http://stackoverflow.com/questions/24501288/getting-version-and-build-info-with-swift
    func getVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "Version: \(version), Build \(build)"
    }
    
    // show the game play instructions
    private func showGameInfo() {
        // unhide blurry background & gameplay instructions
        fuzzyView.isHidden = false
        gameInfoView.isHidden = false
            
        // bring blurry background and game play insturctions to top of views
        self.view.bringSubview(toFront: fuzzyView)
        self.view.bringSubview(toFront: gameInfoView)
        
        // animate gameplay instructions from above
        // - Attribution: https://www.raywenderlich.com/146603/ios-animation-tutorial-getting-started-2
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseOut], animations: {
            self.gameInfoView.center.y += self.view.bounds.height
        }, completion: nil)
    }
    
    // update the label to show instructions
    func updateGameInfoForInstructions() {
        gameInfoLabel.text = "How To Play\nDrag a piece to an open spot.\nFirst with three in a row wins.\n\n\(getVersion())"
        closeGameInfoButton.setTitle("Close", for: .normal)
    }
    
    // hide game play instructions
    private func hideGameInfo() {
        // animate gameplay instructions to below
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseIn], animations: {
            self.gameInfoView.center.y += self.view.bounds.height
        }, completion: { finished in
            // hide blurry background on completion
            self.fuzzyView.isHidden = true
            
            // set gameplay view hidden at top
            self.gameInfoView.center.y -= self.view.bounds.height
            self.gameInfoView.center.y -= self.view.bounds.height
        })
    }
    
    
    // ***********************************************************
    // ******            METHODS FOR SOUND EFFECTS          ******
    // ***********************************************************
    
    // helper function to play a sound
    private func playSound(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)  // set the sound as URL
            audioPlayer.prepareToPlay()
            audioPlayer.play()  // play the sound
        } catch let error {
            print(error.localizedDescription)
        }
    }

    
}

