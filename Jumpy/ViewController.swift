//
//  ViewController.swift
//  Jumpy
//
//  Created by JARMourato on 26/07/16.
//  Copyright © 2016 JARMourato. All rights reserved.
//

import UIKit

//MARK: Constants

let jumpHeightStep: CGFloat = 45.0
let fallVelocity: CGFloat = 600 //pointsPerSecond
let jumpVelocity: CGFloat = 200 //pointsPerSecond
let obstacleVelocity: CGFloat = 100 //pointsPerSecond
let rotationAngle: CGFloat = CGFloat(M_PI_2)
let gapConstant: CGFloat = 8.0
let playerHeight: CGFloat = 20.0
let gapHeight: CGFloat = playerHeight*gapConstant
let colors = [#colorLiteral(red: 0.1529411765, green: 0.2196078431, blue: 0.2980392157, alpha: 1), #colorLiteral(red: 0.1294117647, green: 0.1843137255, blue: 0.2470588235, alpha: 1), #colorLiteral(red: 0.1137254902, green: 0.4156862745, blue: 0.6784313725, alpha: 1), #colorLiteral(red: 0.08235294118, green: 0.6980392157, blue: 0.5411764706, alpha: 1), #colorLiteral(red: 0.07058823529, green: 0.5725490196, blue: 0.4470588235, alpha: 1), #colorLiteral(red: 0.1411764706, green: 0.7803921569, blue: 0.3529411765, alpha: 1), #colorLiteral(red: 0.1176470588, green: 0.6431372549, blue: 0.2941176471, alpha: 1), #colorLiteral(red: 0.9333333333, green: 0.7333333333, blue: 0, alpha: 1), #colorLiteral(red: 0.9411764706, green: 0.5450980392, blue: 0, alpha: 1), #colorLiteral(red: 0.8784313725, green: 0.4156862745, blue: 0.03921568627, alpha: 1), #colorLiteral(red: 0.7882352941, green: 0.2470588235, blue: 0, alpha: 1), #colorLiteral(red: 0.8823529412, green: 0.2, blue: 0.1607843137, alpha: 1), #colorLiteral(red: 0.7019607843, green: 0.1411764706, blue: 0.1098039216, alpha: 1), #colorLiteral(red: 0.537254902, green: 0.2352941176, blue: 0.662745098, alpha: 1), #colorLiteral(red: 0.4823529412, green: 0.1490196078, blue: 0.6235294118, alpha: 1), #colorLiteral(red: 0.6862745098, green: 0.7137254902, blue: 0.7333333333, alpha: 1), #colorLiteral(red: 0.5137254902, green: 0.5843137255, blue: 0.5843137255, alpha: 1), #colorLiteral(red: 0.4235294118, green: 0.4745098039, blue: 0.4784313725, alpha: 1)]


final class ViewController: UIViewController {
  
  private enum State {
    case ready
    case playing
    case over
  }
  
  @IBOutlet var tapToStartLabel: UILabel!
  @IBOutlet var scoreLabel: UILabel!
  @IBOutlet var maxScoreLabel: UILabel!
  
  private var playerAnimator: UIViewPropertyAnimator?
  private var playerRotator: UIViewPropertyAnimator?
  private var player: UIView = UIView(frame: CGRect(x: 0, y: 0, width: playerHeight, height: playerHeight))
  
  private var displayLink: CADisplayLink?
  private var state: State = .ready
  
  private var obstacles: [UIView] = []
  private var obstacleAnimators: [UIViewPropertyAnimator] = []
  private var obstacleTimer: Timer?
  
  private var score: Int = 0
  private var maxScore: Int = 0
  
  private var shouldRotate: Bool = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
    view.addGestureRecognizer(tap)
    setupPlayer()
    resetGame()
  }
  
  func tapped() {
    if case .ready = state {
      startGame()
    }
    jump()
  }
  
}

extension ViewController {
  
  func setupPlayer() {
    player.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.5098039216, blue: 0.8352941176, alpha: 1)
    view.addSubview(player)
    resetPlayerPosition()
  }
  
  func resetPlayerPosition() {
    player.center.y = view.center.y
    player.center.x = view.frame.size.width*0.25
    player.transform = CGAffineTransform.identity
  }
  
  func playerHasFallen() -> Bool {
    guard let vFrame = player.layer.presentation()?.frame else {
      return false
    }
    
    return vFrame.origin.y > (view.frame.size.height - vFrame.size.height)
  }
  
  func playerHasCollided() -> Bool {
    for obstacle in obstacles {
      if let playerFrame = player.layer.presentation()?.frame,
        let obstacle = obstacle.layer.presentation()?.frame,
        playerFrame.intersects(obstacle) {
        return true
      }
    }
    return false
  }
  
  func updateScore() {
    var count: Int = 0
    for (index,obstacle) in obstacles.enumerated().reversed() {
      if let playerFrame = player.layer.presentation()?.frame,
      let obstacle = obstacle.layer.presentation()?.frame,
        playerFrame.origin.x > (obstacle.origin.x + obstacle.size.width) {
        obstacles.remove(at: index)
        count += 1
        
      }
    }
    score += Int(count/2) // One top and one bottom
    scoreLabel.text = "Score: \(score)"
  }
  
}

extension ViewController {

  private func randomColor() -> UIColor {
    return colors[Int(arc4random_uniform(UInt32(colors.count)))]
  }
  
  func createObstacle() -> UIView {
    let width: CGFloat = 30
    let height = (view.frame.size.height/2)*1.5
    let obstacle = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: height))
    obstacle.layer.cornerRadius = 0.2*width
    return obstacle
  }

  func spawnObstacle(outsideView: Bool = false) {
    let color = randomColor()
    let bottomObstacle = createObstacle()
    let factor: CGFloat = outsideView ? 1.25 : 0.75
    let startX = view.frame.size.width*factor
    let min = view.frame.size.height/2 - bottomObstacle.frame.size.height/2 * 0.4
    let max = view.frame.size.height/2 + bottomObstacle.frame.size.height/2 * 0.4
    let startY = CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    
    bottomObstacle.frame.origin = CGPoint(x: startX, y: startY)
    
    let topObstacle = createObstacle()
    let topStartY = startY - topObstacle.frame.size.height - gapHeight

    topObstacle.frame.origin = CGPoint(x: startX, y: topStartY)
    
    bottomObstacle.backgroundColor = color
    topObstacle.backgroundColor = color
    
    view.addSubview(bottomObstacle)
    view.addSubview(topObstacle)
    
    view.sendSubview(toBack: bottomObstacle)
    view.sendSubview(toBack: topObstacle)

    
    obstacles.append(bottomObstacle)
    obstacles.append(topObstacle)
    
    let distance = startX + bottomObstacle.frame.size.width
    let duration = distance/obstacleVelocity
    
    let bottomAnimator = UIViewPropertyAnimator(duration: TimeInterval(duration), curve: .linear) {
      bottomObstacle.frame.origin.x = -bottomObstacle.frame.size.width
    }
    bottomAnimator.addCompletion {_ in 
      bottomObstacle.removeFromSuperview()
    }
    
    let topAnimator = UIViewPropertyAnimator(duration: TimeInterval(duration), curve: .linear) {
      topObstacle.frame.origin.x = -topObstacle.frame.size.width
    }
    topAnimator.addCompletion {_ in
      topObstacle.removeFromSuperview()
    }
  
    obstacleAnimators.append(bottomAnimator)
    obstacleAnimators.append(topAnimator)
  }
  
  func removeObstacles() {
    obstacles.forEach{ $0.removeFromSuperview() }
    obstacles = []
  }
  
  func moveObstacles() {
    while obstacleAnimators.count > 0 {
      let animator = obstacleAnimators.removeLast()
      guard animator.state == .inactive else { return }
      animator.startAnimation()
    }
  }
  
}

extension ViewController {
  
  func startDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayLinkExecute))
    displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
  }
  
  func stopDisplayLink() {
    displayLink?.isPaused = true
    displayLink?.remove(from: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    displayLink = nil
  }
  
  func displayLinkExecute() {
    if playerHasFallen() || playerHasCollided() {
      gameOver()
    }
    updateScore()
  }
  
  func startObstacleSpawnTimer() {
    let interval = view.frame.size.width*0.5/obstacleVelocity
    obstacleTimer = Timer.scheduledTimer(timeInterval: TimeInterval(interval), target: self, selector: #selector(gerenateObstacle(timer:)), userInfo: nil, repeats: true)
  }
  
  func stopObstacleSpawnTimer() {
    if let obstacleTimer = obstacleTimer, obstacleTimer.isValid {
      obstacleTimer.invalidate()
    }
  }
  
  func gerenateObstacle(timer: Timer) {
    spawnObstacle(outsideView: true)
    moveObstacles()
  }
}

extension ViewController {

  func resetGame() {
    removeObstacles()
    spawnObstacle()
    spawnObstacle(outsideView: true)
    resetPlayerPosition()
    tapToStartLabel.isHidden = false
    score = 0
    scoreLabel.text = "Score: \(score)"
    maxScoreLabel.text = maxScore > 0 ? "Max Score: \(maxScore)" : ""
    state = .ready
  }
  
  func startGame() {
    startDisplayLink()
    startObstacleSpawnTimer()
    moveObstacles()
    maxScoreLabel.text = ""
    state = .playing
  }
  
  func gameOver() {
    shouldRotate = false
    stopObstacleSpawnTimer()
    stopDisplayLink()
    stopAnimators()
    tapToStartLabel.isHidden = false
    state = .over
    maxScore = max(maxScore, score)
    resetGame()
  }

}

extension ViewController {

  func stopAnimators() {
    playerAnimator?.stopAnimation(true)
    playerAnimator = nil
    playerRotator?.stopAnimation(true)
    playerRotator = nil
    obstacleAnimators.forEach { $0.stopAnimation(true) }
    obstacleAnimators = []
  }
  
  func rotate(duration: TimeInterval) {
    guard shouldRotate else { return }

    let cubicParameters = UICubicTimingParameters(controlPoint1: CGPoint(x: 0.0, y: 0.4), controlPoint2: CGPoint(x: 0.4, y: 1.0))
    
    playerRotator = UIViewPropertyAnimator(duration: duration, timingParameters: cubicParameters)
  
    playerRotator?.addAnimations { // curve: .easeOut
      self.player.transform = self.player.transform.rotate(rotationAngle)
    }
    playerRotator?.addCompletion { _ in
      self.rotate(duration: duration)
    }
    playerRotator?.startAnimation()
  }
  
  func jump() {
    tapToStartLabel.isHidden = true
  
    guard let currentHeight = player.layer.presentation()?.frame.origin.y else { return }
    playerAnimator?.stopAnimation(true)

    let finalHeight = currentHeight - jumpHeightStep
    let duration = jumpHeightStep/jumpVelocity
    shouldRotate = true
    
    playerAnimator = UIViewPropertyAnimator(duration: TimeInterval(duration), curve: .easeOut ){
      self.player.frame.origin.y = finalHeight
    }
    playerAnimator?.addCompletion { _ in
      self.shouldRotate = false
      self.fall()
    }
    playerAnimator?.startAnimation()
    
    rotate(duration: Double(duration)/2.0)
  }
  
  func fall() {
    let finalHeight = view.frame.size.height
    let currentHeight = player.frame.origin.y
    let distanceToBottom = finalHeight - currentHeight
    let duration = distanceToBottom/fallVelocity
    
    playerAnimator = UIViewPropertyAnimator(duration: TimeInterval(duration), curve: .easeIn ){
      self.player.frame.origin.y = finalHeight
    }
    playerAnimator?.startAnimation()
  }
  
}

