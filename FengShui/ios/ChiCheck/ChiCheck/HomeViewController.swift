import UIKit

class HomeViewController: UIViewController {

    // MARK: - UI Elements

    private let gradientLayer = CAGradientLayer()
    private let baguaShapeLayer = CAShapeLayer()

    // 3. The App Title ("ChiCheck")
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ChiChek"
        
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
        
        label.layer.shadowColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor // Gold
                label.layer.shadowOffset = CGSize(width: 0, height: 0)
                label.layer.shadowOpacity = 0.6 // Starts softer
                label.layer.shadowRadius = 10   // Starts smaller
                
                return label
    }()

    // 4. The Mission Statement
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
        
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0
        label.transform = CGAffineTransform(translationX: 0, y: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 5. The "Begin Analysis" Button
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Begin Analysis", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        button.backgroundColor = UIColor.white
        button.setTitleColor(UIColor(red: 0.1, green: 0.3, blue: 0.3, alpha: 1.0), for: .normal)
        
        button.layer.cornerRadius = 25
        button.alpha = 0
        button.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        button.layer.shadowColor = UIColor.white.cgColor
        button.layer.shadowOffset = .zero
        button.layer.shadowOpacity = 0.6
        button.layer.shadowRadius = 15
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
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
        gradientLayer.frame = view.bounds
        baguaShapeLayer.position = CGPoint(x: view.center.x, y: view.center.y - 33)
    }

    // MARK: - 1. Flowing Sand Background (UPDATED COLORS)

    private func setupGradientBackground() {
        // Baby Blue
        let babyBlue = UIColor(red: 137/255, green: 207/255, blue: 240/255, alpha: 1.0).cgColor
        // Mint Green
        let mint = UIColor(red: 152/255, green: 255/255, blue: 152/255, alpha: 1.0).cgColor
        
        // UPDATED: Soft Sand/Gold (Removed the Purple/Aurora)
        let softSand = UIColor(red: 240/255, green: 230/255, blue: 140/255, alpha: 1.0).cgColor
        
        // Initial State
        gradientLayer.colors = [babyBlue, mint, softSand]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)

        animateGradientFlow(colors: [babyBlue, mint, softSand])
    }

    private func animateGradientFlow(colors: [CGColor]) {
        let set1 = [colors[0], colors[1], colors[2]]
        let set2 = [colors[2], colors[0], colors[1]]
        let set3 = [colors[1], colors[2], colors[0]]

        let animation = CAKeyframeAnimation(keyPath: "colors")
        animation.values = [set1, set2, set3, set1]
        animation.keyTimes = [0, 0.33, 0.66, 1.0]
        animation.duration = 8.0
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        
        gradientLayer.add(animation, forKey: "colorFlow")
    }

    // MARK: - 2. Bagua Shape (UPDATED VISIBILITY)

    private func setupBaguaShape() {
        let width: CGFloat = 300
        let height: CGFloat = 300
        
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
        
        // UPDATED: Make it much more obvious
        baguaShapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor // High Opacity
        baguaShapeLayer.lineWidth = 6 // Thicker line
        
        // Added Glow Effect to Bagua
        baguaShapeLayer.shadowColor = UIColor.white.cgColor
        baguaShapeLayer.shadowOpacity = 0.8
        baguaShapeLayer.shadowRadius = 10
        baguaShapeLayer.shadowOffset = .zero
        
        baguaShapeLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        baguaShapeLayer.position = CGPoint(x: view.center.x, y: view.center.y - 33)
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 60
        rotation.repeatCount = .infinity
        
        baguaShapeLayer.add(rotation, forKey: "slowSpin")
        
        view.layer.insertSublayer(baguaShapeLayer, above: gradientLayer)
    }

    // MARK: - 3. UI Setup

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
            startButton.widthAnchor.constraint(equalToConstant: 220),
            startButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    // MARK: - Animation Sequence

    private func animateSequence() {
        UIView.animate(withDuration: 1.2, delay: 0.0, options: .curveEaseOut) {
                    self.titleLabel.alpha = 1.0
                } completion: { _ in
                    self.animateTitleGlow()
                }

        UIView.animate(withDuration: 1.0, delay: 0.8, options: .curveEaseOut) {
            self.missionLabel.alpha = 1.0
            self.missionLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.8, delay: 2.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.startButton.alpha = 1.0
            self.startButton.transform = .identity
        }
    }
    
    // NEW FUNCTION: Makes the Golden Shadow Breathe/Gloom
        private func animateTitleGlow() {
            // Animate Radius (Expansion)
            let radiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
            radiusAnimation.fromValue = 10
            radiusAnimation.toValue = 30 // Glows outwards
            radiusAnimation.duration = 2.5
            radiusAnimation.autoreverses = true
            radiusAnimation.repeatCount = .infinity
            
            // Animate Opacity (Intensity)
            let opacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            opacityAnimation.fromValue = 0.6
            opacityAnimation.toValue = 1.0 // Becomes intense gold
            opacityAnimation.duration = 2.5
            opacityAnimation.autoreverses = true
            opacityAnimation.repeatCount = .infinity
            
            titleLabel.layer.add(radiusAnimation, forKey: "glowingShadow")
            titleLabel.layer.add(opacityAnimation, forKey: "pulsingShadow")
        }
    
    // MARK: - Actions

    @objc func didTapStart() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let setupVC = ScanSetupViewController()
        navigationController?.pushViewController(setupVC, animated: true)
    }
}
