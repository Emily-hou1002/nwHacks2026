import UIKit

class HomeViewController: UIViewController {

    // MARK: - UI Elements

    private let baguaShapeLayer = CAShapeLayer()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ChiCheck"
        
        let fontSize: CGFloat = 52
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        if let descriptor = systemFont.fontDescriptor.withDesign(.serif) {
            label.font = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            label.font = systemFont
        }

        label.textColor = .white
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Golden Glow for Title
        label.layer.shadowColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowOpacity = 0.6
        label.layer.shadowRadius = 10
        
        return label
    }()

    private let missionLabel: UILabel = {
        let label = UILabel()
        label.text = "Harmonize your space.\nElevate your energy."
        
        let fontSize: CGFloat = 18
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            label.font = systemFont
        }
        
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0
        label.transform = CGAffineTransform(translationX: 0, y: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Begin Analysis", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        // NEW STYLING: Black background, white text, white border
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2.0
        
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set background to pure black
        view.backgroundColor = .black
        
        setupBaguaShape()
        setupUI()
        
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateSequence()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baguaShapeLayer.position = CGPoint(x: view.center.x, y: view.center.y - 33)
    }

    // MARK: - Bagua Shape (UPDATED TO GOLD)

    private func setupBaguaShape() {
        let width: CGFloat = 300
        let height: CGFloat = 300
        let goldColor = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 1.0)
        
        let path = UIBezierPath()
        let points = [
            CGPoint(x: width * 0.29, y: 0),      CGPoint(x: width * 0.71, y: 0),
            CGPoint(x: width, y: height * 0.29), CGPoint(x: width, y: height * 0.71),
            CGPoint(x: width * 0.71, y: height), CGPoint(x: width * 0.29, y: height),
            CGPoint(x: 0, y: height * 0.71),     CGPoint(x: 0, y: height * 0.29)
        ]
        
        path.move(to: points.last!)
        for point in points { path.addLine(to: point) }
        path.close()
        
        baguaShapeLayer.path = path.cgPath
        baguaShapeLayer.fillColor = UIColor.clear.cgColor
        
        // UPDATED: Gold Stroke
        baguaShapeLayer.strokeColor = goldColor.cgColor
        baguaShapeLayer.lineWidth = 5
        
        // Gold Glow Effect
        baguaShapeLayer.shadowColor = goldColor.cgColor
        baguaShapeLayer.shadowOpacity = 0.5
        baguaShapeLayer.shadowRadius = 15
        baguaShapeLayer.shadowOffset = .zero
        
        baguaShapeLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        baguaShapeLayer.position = CGPoint(x: view.center.x, y: view.center.y - 33)
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 40 // Slightly faster spin for energy
        rotation.repeatCount = .infinity
        
        baguaShapeLayer.add(rotation, forKey: "slowSpin")
        view.layer.addSublayer(baguaShapeLayer)
    }

    // MARK: - UI Layout & Animations

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(missionLabel)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),

            missionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            missionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            missionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 240),
            startButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func animateSequence() {
        UIView.animate(withDuration: 1.2) {
            self.titleLabel.alpha = 1.0
        } completion: { _ in
            self.animateTitleGlow()
        }

        UIView.animate(withDuration: 1.0, delay: 0.5) {
            self.missionLabel.alpha = 1.0
            self.missionLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.8, delay: 1.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.startButton.alpha = 1.0
            self.startButton.transform = .identity
        }
    }
    
    private func animateTitleGlow() {
        let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        radiusAnimation.fromValue = 8
        radiusAnimation.toValue = 25
        radiusAnimation.duration = 2.0
        radiusAnimation.autoreverses = true
        radiusAnimation.repeatCount = .infinity
        
        titleLabel.layer.add(radiusAnimation, forKey: "glowingShadow")
    }

    @objc func didTapStart() {
        // 1. Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 2. Navigation
        // Replace 'ScanSetupViewController' with the actual name of your next screen
        let setupVC = ScanSetupViewController()
        
        if let nav = self.navigationController {
            nav.pushViewController(setupVC, animated: true)
        } else {
            // FALLBACK: If there is no navigation controller, present it modally
            setupVC.modalPresentationStyle = .fullScreen
            self.present(setupVC, animated: true, completion: nil)
        }
    }
}
