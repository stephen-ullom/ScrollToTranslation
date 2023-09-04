//
//  OverlayContainerViewController.swift
//  ScrollToTranslation
//
//  Created by Gaétan Zanella on 08/08/2018.
//  Copyright © 2018 Gaétan Zanella. All rights reserved.
//

import UIKit

private enum Constant {
  static let minimumHeight: CGFloat = 400
  static let minimumVelocityConsideration: CGFloat = 20
  static let defaultTranslationDuration: TimeInterval = 0.5
  static let maximumTranslationDuration: TimeInterval = 0.6
}

enum OverlayPosition {
  case maximum, minimum
}

class OverlayContainerViewController: UIViewController, OverlayViewControllerDelegate {
  enum OverlayInFlightPosition {
    case minimum
    case maximum
    case progressing
  }

  private let overlayViewController: OverlayViewController

  private lazy var translatedView = UIView()
  private lazy var translatedViewHeightContraint = self.makeTranslatedViewHeightConstraint()

  private var overlayPosition: OverlayPosition = .minimum
  private var maxHeight: CGFloat

  private var translatedViewTargetHeight: CGFloat {
    switch overlayPosition {
    case .maximum:
      return maxHeight
    case .minimum:
      return Constant.minimumHeight
    }
  }

  private var overlayInFlightPosition: OverlayInFlightPosition {
    let height = translatedViewHeightContraint.constant
    if height == maxHeight {
      return .maximum
    } else if height == Constant.minimumHeight {
      return .minimum
    } else {
      return .progressing
    }
  }

  // MARK: Life Cycle

  init(overlayViewController: OverlayViewController, maxHeight: CGFloat) {
    self.overlayViewController = overlayViewController
    self.maxHeight = maxHeight
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UIViewController

  override func loadView() {
    view = PassThroughView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpController()
  }

  // MARK: OverlayViewControllerDelegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard shouldTranslateView(following: scrollView) else { return }
    translateView(following: scrollView)
  }

  func scrollView(
    _ scrollView: UIScrollView,
    willEndScrollingWithVelocity velocity: CGPoint,
    targetContentOffset: UnsafeMutablePointer<CGPoint>
  ) {
    switch overlayInFlightPosition {
    case .maximum:
      break
    case .minimum, .progressing:
      targetContentOffset.pointee = .zero
    }
    animateTranslationEnd(following: scrollView, velocity: velocity)
  }

  // MARK: Public

  func moveOverlay(to position: OverlayPosition) {
    moveOverlay(to: position, duration: Constant.defaultTranslationDuration, velocity: .zero)
  }

  // MARK: Private

  private func setUpController() {
    view.addSubview(translatedView)
    translatedView.gz_pinToSuperview(edges: [.left, .right, .bottom])
    translatedViewHeightContraint.isActive = true
    gz_addChild(overlayViewController, in: translatedView, edges: [.right, .left, .top])
    overlayViewController.view.heightAnchor.constraint(equalToConstant: maxHeight).isActive = true
    translatedView.backgroundColor = .red
    translatedView.layer.cornerRadius = 32
    translatedView.layer.masksToBounds = true
    overlayViewController.tableView.backgroundColor = .blue
    overlayViewController.delegate = self
  }

  private func shouldTranslateView(following scrollView: UIScrollView) -> Bool {
    guard scrollView.isTracking else { return false }
    let offset = scrollView.contentOffset.y
    switch overlayInFlightPosition {
    case .maximum:
      return offset < 0
    case .minimum:
      return offset > 0
    case .progressing:
      return true
    }
  }

  private func translateView(following scrollView: UIScrollView) {
    scrollView.contentOffset = .zero
    let translation = translatedViewTargetHeight - scrollView.panGestureRecognizer.translation(in: view).y
    translatedViewHeightContraint.constant = max(
      Constant.minimumHeight,
      min(translation, maxHeight)
    )
  }

  private func animateTranslationEnd(following scrollView: UIScrollView, velocity: CGPoint) {
    let distance = maxHeight - Constant.minimumHeight
    let progressDistance = translatedViewHeightContraint.constant - Constant.minimumHeight
    let progress = progressDistance / distance
    let velocityY = -velocity.y * 100
    if abs(velocityY) > Constant.minimumVelocityConsideration && progress != 0 && progress != 1 {
      let rest = abs(distance - progressDistance)
      let position: OverlayPosition
      let duration = TimeInterval(rest / abs(velocityY))
      if velocityY > 0 {
        position = .minimum
      } else {
        position = .maximum
      }
      moveOverlay(to: position, duration: duration, velocity: velocity)
    } else {
      if progress < 0.5 {
        moveOverlay(to: .minimum)
      } else {
        moveOverlay(to: .maximum)
      }
    }
  }

  private func moveOverlay(
    to position: OverlayPosition,
    duration: TimeInterval,
    velocity: CGPoint
  ) {
    overlayPosition = position
    translatedViewHeightContraint.constant = translatedViewTargetHeight
    print(velocity.y)
    UIView.animate(
      withDuration: min(duration, Constant.maximumTranslationDuration),
      delay: 0,
      usingSpringWithDamping: velocity.y == 0 ? 1 : 0.7,
      initialSpringVelocity: abs(velocity.y),
      options: [.allowUserInteraction],
      animations: {
        self.view.layoutIfNeeded()
      }, completion: nil
    )
  }

  private func makeTranslatedViewHeightConstraint() -> NSLayoutConstraint {
    return translatedView.heightAnchor.constraint(equalToConstant: Constant.minimumHeight)
  }
}
