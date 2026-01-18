import UIKit

class HomeViewController: UIViewController {

    // MARK: - UI Elements

    private let baguaShapeLayer = CAShapeLayer()

    // 3. The App Title ("ChiCheck")
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "chichek"
        
        let fontSize: CGFloat = 56
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .light) // Lighter weight for elegance
        if let descriptor = systemFont.fontDescriptor.withDesign(.serif) {
            label.font = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            label.font = systemFont
        }

        label.textColor = .white
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Gold accent glow
        label.layer.shadowColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor // Gold
        label.layer.shadowOffset = CGSize(width: 0, height: 0)
        label.layer.shadowOpacity = 0.7
        label.layer.shadowRadius = 20
        
        // Letter spacing for luxury feel
        let attributedString = NSMutableAttributedString(string: "chichek")
        attributedString.addAttribute(.kern, value: 3.0, range: NSRange(location: 0, length: attributedString.length))
        label.attributedText = attributedString
                
        return label
    }()

    // 4. The Mission Statement
    private let missionLabel: UILabel = {
        let label = UILabel()
        label.text = "harmonize your space.\nelevate your energy."
        
        let fontSize: CGFloat = 16
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            label.font = systemFont
        }
        
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0
        label.transform = CGAffineTransform(translationX: 0, y: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtle letter spacing for refinement
        let attributedString = NSMutableAttributedString(string: "harmonize your space.\nelevate your energy.")
        attributedString.addAttribute(.kern, value: 0.8, range: NSRange(location: 0, length: attributedString.length))
        label.attributedText = attributedString
        
        return label
    }()

    // 5. The "Begin Analysis" Button
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("begin analysis", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        
        // Subtle white border on black background
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // White text
        button.setTitleColor(.white, for: .normal)
        
        button.layer.cornerRadius = 28
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Soft gold glow
        button.layer.shadowColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor
        button.layer.shadowOffset = .zero
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 15
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Black background
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
        baguaShapeLayer.position = CGPoint(x: view.center.x, y: view.center.y - 20)
    }

    // MARK: - 2. Bagua Shape (Zen minimalist on black)

    private func setupBaguaShape() {
        let width: CGFloat = 320
        let height: CGFloat = 320
        
        let path = UIBezierPath()
        let points = [
            CGPoint(x: width * 0.29, y: 0),     CGPoint(x: width * 0.71, y: 0),
            CGPoint(x: width, y: height * 0.29), CGPoint(x: width, y: height * 0.71),
            CGPoint(x: width * 0.71, y: height), CGPoint(x: width * 0.29, y: height),
            CGPoint(x: 0, y: height * 0.71),     CGPoint(x: 0, y: height * 0.29)
        ]
        
        path.move(to: points.last!)
        for point in points { path.addLine(to: point) }
        path.close()
        
        baguaShapeLayer.path = path.cgPath
        baguaShapeLayer.fillColor = UIColor.clear.cgColor
        
        // Subtle gold accent
        baguaShapeLayer.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.2).cgColor
        baguaShapeLayer.lineWidth = 1.5
        
        // Soft gold glow
        baguaShapeLayer.shadowColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor
        baguaShapeLayer.shadowOpacity = 0.3
        baguaShapeLayer.shadowRadius = 20
        baguaShapeLayer.shadowOffset = .zero
        
        baguaShapeLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        baguaShapeLayer.position = CGPoint(x: view.center.x, y: view.center.y - 20)
        
        // Very slow, meditative rotation
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 120 // Ultra slow
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        baguaShapeLayer.add(rotation, forKey: "slowSpin")
        
        // Subtle breathing effect
        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = 0.98
        breathe.toValue = 1.02
        breathe.duration = 6.0
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        baguaShapeLayer.add(breathe, forKey: "breathe")
        
        view.layer.addSublayer(baguaShapeLayer)
    }

    // MARK: - 3. UI Setup

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(missionLabel)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),

            // Much tighter spacing for premium, cohesive feel
            missionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            missionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            missionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 240),
            startButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Animation Sequence

    private func animateSequence() {
        // Gentle fade in for title
        UIView.animate(withDuration: 1.5, delay: 0.0, options: .curveEaseOut) {
            self.titleLabel.alpha = 1.0
        } completion: { _ in
            self.animateTitleGlow()
        }

        // Mission statement flows in
        UIView.animate(withDuration: 1.2, delay: 0.8, options: .curveEaseOut) {
            self.missionLabel.alpha = 1.0
            self.missionLabel.transform = .identity
        }

        // Button appears with gentle spring
        UIView.animate(withDuration: 1.0, delay: 1.8, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: .curveEaseOut) {
            self.startButton.alpha = 1.0
            self.startButton.transform = .identity
        } completion: { _ in
            self.animateButtonBreathing()
        }
    }
    
    // Soft breathing gold glow on title
    private func animateTitleGlow() {
        let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        radiusAnimation.fromValue = 20
        radiusAnimation.toValue = 30
        radiusAnimation.duration = 3.0
        radiusAnimation.autoreverses = true
        radiusAnimation.repeatCount = .infinity
        radiusAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let opacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        opacityAnimation.fromValue = 0.7
        opacityAnimation.toValue = 1.0
        opacityAnimation.duration = 3.0
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        titleLabel.layer.add(radiusAnimation, forKey: "glowingShadow")
        titleLabel.layer.add(opacityAnimation, forKey: "pulsingShadow")
    }
    
    // Subtle breathing animation for button
    private func animateButtonBreathing() {
        UIView.animate(withDuration: 2.5, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.startButton.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }
    }
    
    // MARK: - Actions

    @objc func didTapStart() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Add a subtle press animation
        UIView.animate(withDuration: 0.1, animations: {
            self.startButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.startButton.transform = .identity
            }
        }

        let setupVC = ScanSetupViewController()
        navigationController?.pushViewController(setupVC, animated: true)
    }
}
