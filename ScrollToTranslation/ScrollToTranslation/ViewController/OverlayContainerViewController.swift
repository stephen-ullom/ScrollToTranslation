//
//  OverlayContainerViewController.swift
//  ScrollToTranslation
//
//  Created by Gaétan Zanella on 08/08/2018.
//  Copyright © 2018 Gaétan Zanella. All rights reserved.
//

import UIKit

private struct Constant {
    static let minimumHeight: CGFloat = 200
    static let maximumHeight: CGFloat = 500
    static let minimumVelocityConsideration: CGFloat = 500
    static let defaultTranslationDuration: TimeInterval = 0.25
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

    private var translatedViewTargetHeight: CGFloat {
        switch overlayPosition {
        case .maximum:
            return Constant.maximumHeight
        case .minimum:
            return Constant.minimumHeight
        }
    }

    private var overlayInFlightPosition: OverlayInFlightPosition {
        let height = translatedViewHeightContraint.constant
        if height == Constant.maximumHeight {
            return .maximum
        } else if height == Constant.minimumHeight {
            return .minimum
        } else {
            return .progressing
        }
    }

    // MARK: - Life Cycle

    init(overlayViewController: OverlayViewController) {
        self.overlayViewController = overlayViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func loadView() {
        view = PassThroughView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpController()
    }

    // MARK: - OverlayViewControllerDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard shouldTranslateView(following: scrollView) else { return }
        translateView(following: scrollView)
    }

    func scrollViewDidStopScrolling(_ scrollView: UIScrollView) {
        switch overlayInFlightPosition {
        case .maximum, .minimum:
            break
        case .progressing:
            scrollView.isScrollEnabled = false
            scrollView.isScrollEnabled = true
            animateTranslationEnd(following: scrollView)
        }
    }

    // MARK: - Public

    func moveOverlay(to position: OverlayPosition) {
        moveOverlay(to: position, duration: Constant.defaultTranslationDuration, options: [])
    }

    // MARK: - Private

    private func setUpController() {
        view.addSubview(translatedView)
        translatedView.gz_pinToSuperview(edges: [.left, .right, .bottom])
        translatedViewHeightContraint.isActive = true
        gz_addChild(overlayViewController, in: translatedView, edges: [.right, .left, .top])
        overlayViewController.view.heightAnchor.constraint(equalToConstant: Constant.maximumHeight).isActive = true
        translatedView.backgroundColor = .red
        overlayViewController.tableView.backgroundColor = .red
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
            min(translation, Constant.maximumHeight)
        )
    }

    private func animateTranslationEnd(following scrollView: UIScrollView) {
        let distance = Constant.maximumHeight - Constant.minimumHeight
        let progressDistance = translatedViewHeightContraint.constant - Constant.minimumHeight
        let progress = progressDistance / distance
        let velocity = scrollView.panGestureRecognizer.velocity(in: view).y
        if abs(velocity) > Constant.minimumVelocityConsideration && progress != 0 && progress != 1 {
            let rest = abs(distance - progressDistance)
            let position: OverlayPosition
            let duration = TimeInterval(rest / velocity)
            if velocity > 0 {
                position = .minimum
            } else {
                position = .maximum
            }
            moveOverlay(
                to: position,
                duration: duration,
                options: .curveEaseInOut
            )
        } else {
            if progress < 0.5 {
                moveOverlay(to: .minimum)
            } else {
                moveOverlay(to: .maximum)
            }
        }
    }

    private func moveOverlay(to position: OverlayPosition,
                             duration: TimeInterval,
                             options: UIViewAnimationOptions) {
        overlayPosition = position
        translatedViewHeightContraint.constant = translatedViewTargetHeight
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: {
                self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func makeTranslatedViewHeightConstraint() -> NSLayoutConstraint {
        return translatedView.heightAnchor.constraint(equalToConstant: Constant.minimumHeight)
    }
}
