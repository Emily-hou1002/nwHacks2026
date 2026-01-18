import UIKit

import UIKit

class ScanSetupViewController: UIViewController {
    // Keep the animator instance
    let transition = DissolveTransitionAnimator()
    private var didPushFirstStep = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Keep this VC minimal; we only attach delegate and push in viewDidAppear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Only push/replace once
        guard !didPushFirstStep else { return }
        didPushFirstStep = true

        if let nav = navigationController {
            // set ourselves as delegate for custom transitions
            nav.delegate = self
            nav.interactivePopGestureRecognizer?.delegate = self
            nav.interactivePopGestureRecognizer?.isEnabled = true

            let builder = ScanDataBuilder()
            let firstStep = RoomTypeViewController(dataBuilder: builder)

            // --- REPLACE this container (self) in the nav stack with firstStep ---
            var vcs = nav.viewControllers

            if let myIndex = vcs.firstIndex(of: self) {
                // replace only the ScanSetupViewController entry with firstStep
                vcs[myIndex] = firstStep
                nav.setViewControllers(vcs, animated: true)
            } else {
                // fallback: if for some reason self isn't in the stack, push normally
                nav.pushViewController(firstStep, animated: true)
            }
        } else {
            // fallback if the ScanSetupVC wasn't embedded in a navigation controller:
            let builder = ScanDataBuilder()
            let firstStep = RoomTypeViewController(dataBuilder: builder)
            let modalNav = UINavigationController(rootViewController: firstStep)
            modalNav.delegate = self
            modalNav.interactivePopGestureRecognizer?.delegate = self
            modalNav.navigationBar.isHidden = true
            present(modalNav, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // remove delegate if this VC is leaving to avoid affecting other parts of app
        if let nav = navigationController, nav.delegate === self {
            nav.delegate = nil
            nav.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

// Attach delegates
extension ScanSetupViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // Optionally limit the custom animation to only controllers in your flow:
        // if fromVC is that flow or toVC is that flow then return transition, else nil.
        // For now, return the transition for push/pop in this flow:
        return transition
    }
}

// Keep interactive pop gesture working
extension ScanSetupViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // allow edge-swipe only when more than one controller in nav stack
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}


// MARK: - 1. Custom Transition Animator (Dissolve)
class DissolveTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration: TimeInterval = 0.4
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.addSubview(toView)
        toView.alpha = 0.0
        
        // Subtle scale animation
        toView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            fromView.alpha = 0.0
            toView.alpha = 1.0
            toView.transform = .identity
        } completion: { _ in
            fromView.alpha = 1.0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - 2. Data Model
class ScanDataBuilder {
    var roomType: String?
    var roomStyle: String?
    var intention: String?
    var birthDate: Date?
    
    func toScanData() -> ScanData? {
    guard let type = roomType,
    let intention = intention,
    let date = birthDate else { return nil }


    return ScanData(
    roomType: type,
    roomStyle: roomStyle ?? "Unknown",
    intention: intention,
    birthDate: date
    )
}
}

// MARK: - 3. Yin Yang View (Visuals)
class YinYangView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func draw(_ rect: CGRect) {
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (size / 2) - 2
        
        // 1. Draw White Base
        let fullCircle = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.white.setFill()
        fullCircle.fill()
        
        // 2. Draw Black Section
        let blackPath = UIBezierPath()
        let topSubCenter = CGPoint(x: center.x, y: center.y - radius/2)
        let bottomSubCenter = CGPoint(x: center.x, y: center.y + radius/2)
        
        blackPath.move(to: CGPoint(x: center.x, y: center.y + radius))
        blackPath.addArc(withCenter: center, radius: radius, startAngle: .pi/2, endAngle: -.pi/2, clockwise: true)
        blackPath.addArc(withCenter: topSubCenter, radius: radius/2, startAngle: -.pi/2, endAngle: .pi/2, clockwise: true)
        blackPath.addArc(withCenter: bottomSubCenter, radius: radius/2, startAngle: -.pi/2, endAngle: .pi/2, clockwise: false)
        blackPath.close()
        
        UIColor.black.withAlphaComponent(0.85).setFill()
        blackPath.fill()
        
        // 3. Draw Dots (Smaller now)
        let dotRadius = radius / 16 // Made dots smaller
        
        let whiteDot = UIBezierPath(arcCenter: topSubCenter, radius: dotRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.white.setFill()
        whiteDot.fill()
        
        let blackDot = UIBezierPath(arcCenter: bottomSubCenter, radius: dotRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.black.withAlphaComponent(0.85).setFill()
        blackDot.fill()
        
        // 4. Outline (White)
        let outline = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.white.setStroke()
        outline.lineWidth = 1.5
        outline.stroke()
        
        let sCurve = UIBezierPath()
        sCurve.move(to: CGPoint(x: center.x, y: center.y - radius))
        sCurve.addArc(withCenter: topSubCenter, radius: radius/2, startAngle: -.pi/2, endAngle: .pi/2, clockwise: true)
        sCurve.addArc(withCenter: bottomSubCenter, radius: radius/2, startAngle: -.pi/2, endAngle: .pi/2, clockwise: false)
        sCurve.stroke()
    }
}

// MARK: - 4. Bagua Option View (Bubble)
class BaguaOptionView: UIView {
    var title: String = ""
    var isSelected: Bool = false {
        didSet { updateAppearance() }
    }
    
    private let circleView = UIView()
    private let iconImageView = UIImageView()
    private let label = UILabel()
    
    init(title: String, iconName: String, size: CGFloat) {
        self.title = title
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        
        // 1. Circle
        circleView.frame = bounds
        circleView.backgroundColor = .black
        circleView.layer.cornerRadius = size / 2
        circleView.layer.borderWidth = 1
        circleView.layer.borderColor = UIColor(white: 0.3, alpha: 1.0).cgColor
        addSubview(circleView)
        
        // 2. Calculated Layout to group Icon & Text tighter
        let totalContentHeight: CGFloat = (size * 0.4) + 12 // Icon + Text
        let startY = (size - totalContentHeight) / 2
        
        // Icon
        let iconSize = size * 0.4
        iconImageView.frame = CGRect(
            x: (size - iconSize) / 2,
            y: startY - 2, // Slight upward nudge
            width: iconSize,
            height: iconSize
        )
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        if let customImage = UIImage(named: iconName) {
            iconImageView.image = customImage
        } else {
            iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        }
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        circleView.addSubview(iconImageView)
        
        // Label
        label.text = title
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        // Place text directly under icon
        label.frame = CGRect(x: 4, y: iconImageView.frame.maxY + 2, width: size - 8, height: 14)
        circleView.addSubview(label)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func updateAppearance() {
        if isSelected {
            circleView.layer.borderColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0).cgColor
            circleView.layer.borderWidth = 3
            iconImageView.tintColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
            label.textColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
                self.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }
        } else {
            circleView.layer.borderColor = UIColor(white: 0.3, alpha: 1.0).cgColor
            circleView.layer.borderWidth = 1
            iconImageView.tintColor = .white
            label.textColor = .white
            
            UIView.animate(withDuration: 0.3) {
                self.transform = .identity
            }
        }
    }
}

// MARK: - 5. Base Controller (Parent Class)
class BaseBaguaViewController: UIViewController {
    
    let questionLabel = UILabel()
    let swipeHintLabel = UILabel()
    let baguaView = YinYangView()
    var optionViews: [BaguaOptionView] = []
    
    private let circleRadius: CGFloat = 170
    private let iconSize: CGFloat = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupBagua()
        setupHeader()
        setupSwipeHint()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
    }
    
    private func setupBagua() {
        baguaView.alpha = 1.0
        baguaView.backgroundColor = .clear
        view.addSubview(baguaView)
        baguaView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            baguaView.widthAnchor.constraint(equalToConstant: 340),
            baguaView.heightAnchor.constraint(equalToConstant: 340),
            baguaView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            baguaView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40)
        ])
    }
    
    private func setupHeader() {
        questionLabel.font = .systemFont(ofSize: 28, weight: .bold)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        view.addSubview(questionLabel)
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Moved Title down slightly to clear the back button area
            questionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    
    private func setupSwipeHint() {
        swipeHintLabel.text = "Swipe left to continue  >>>"
        swipeHintLabel.font = .systemFont(ofSize: 16, weight: .medium)
        swipeHintLabel.textColor = .lightGray
        swipeHintLabel.textAlignment = .center
        swipeHintLabel.alpha = 0
        view.addSubview(swipeHintLabel)
        swipeHintLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            swipeHintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            swipeHintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setupOptions(data: [(title: String, icon: String)]) {
        view.layoutIfNeeded()
        let centerPoint = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2 + 40)
        let count = CGFloat(data.count)
        let step = (2 * CGFloat.pi) / count
        var angle: CGFloat = -CGFloat.pi / 2
        
        for item in data {
            let optionView = BaguaOptionView(title: item.title, iconName: item.icon, size: iconSize)
            var currentRadius = circleRadius
            if item.title == "bathroom" || item.title == "office" || item.title == "industrial" || item.title == "bohemian" {
                            currentRadius -= 20 // Pull them in by 25 points
                        }
            
            let x = centerPoint.x + currentRadius * cos(angle)
            let y = centerPoint.y + currentRadius * sin(angle)
            optionView.center = CGPoint(x: x, y: y)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:)))
            optionView.addGestureRecognizer(tap)
            
            view.addSubview(optionView)
            optionViews.append(optionView)
            
            angle += step
        }
    }
    
    func showSwipeHint() {
        if swipeHintLabel.alpha == 0 {
            UIView.animate(withDuration: 0.5) {
                self.swipeHintLabel.alpha = 1.0
                self.swipeHintLabel.transform = CGAffineTransform(translationX: 0, y: -5)
            }
        }
    }
    
    @objc func optionTapped(_ sender: UITapGestureRecognizer) {}
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {}
}

// MARK: - 6. Page 1: Room Type
class RoomTypeViewController: BaseBaguaViewController {
    let dataBuilder: ScanDataBuilder
    
    init(dataBuilder: ScanDataBuilder) {
        self.dataBuilder = dataBuilder
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionLabel.text = "what type of room is this?"
        let data = [
            (title: "bedroom", icon: "bed.double.fill"),
            (title: "living room", icon: "sofa.fill"),
            (title: "office", icon: "desktopcomputer"),
            (title: "kitchen", icon: "cooktop.fill"),
            (title: "dining", icon: "table.furniture.fill"),
            (title: "bathroom", icon: "bathtub.fill"),
            (title: "meditation", icon: "leaf.fill")
        ]
        DispatchQueue.main.async { self.setupOptions(data: data) }
    }
    
    override func optionTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view as? BaguaOptionView else { return }
        optionViews.forEach { $0.isSelected = false }
        tappedView.isSelected = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        dataBuilder.roomType = tappedView.title
        showSwipeHint()
    }
    
    override func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        if dataBuilder.roomType != nil {
            let nextVC = IntentionViewController(dataBuilder: self.dataBuilder)
            navigationController?.pushViewController(nextVC, animated: true)
        } else {
            shakeQuestion()
        }
    }
    
    private func shakeQuestion() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-10, 10, -5, 5, 0]
        anim.duration = 0.4
        questionLabel.layer.add(anim, forKey: "shake")
    }
}

// MARK: - 8. Page 3: Intention
class IntentionViewController: BaseBaguaViewController {
    let dataBuilder: ScanDataBuilder
    
    init(dataBuilder: ScanDataBuilder) {
        self.dataBuilder = dataBuilder
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        questionLabel.text = "what is your intention?"
        let data = [
            (title: "creativity", icon: "paintbrush.fill"),
            (title: "balance", icon: "scale.3d"),
            (title: "knowledge", icon: "book.fill"),
            (title: "wealth", icon: "dollarsign.circle.fill"),
            (title: "health", icon: "heart.fill"),
            (title: "love", icon: "suit.heart.fill")
        ]
        DispatchQueue.main.async { self.setupOptions(data: data) }
    }
    
    override func optionTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view as? BaguaOptionView else { return }
        optionViews.forEach { $0.isSelected = false }
        tappedView.isSelected = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        dataBuilder.intention = tappedView.title
        showSwipeHint()
    }
    
    override func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        if dataBuilder.intention != nil {
            let nextVC = DateInputViewController(dataBuilder: self.dataBuilder)
            navigationController?.pushViewController(nextVC, animated: true)
        } else {
            shakeQuestion()
        }
    }
    
    private func shakeQuestion() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-10, 10, -5, 5, 0]
        anim.duration = 0.4
        questionLabel.layer.add(anim, forKey: "shake")
    }
}

// MARK: - 9. Page 4: Date Input
class DateInputViewController: UIViewController {
    let dataBuilder: ScanDataBuilder
    private let questionLabel = UILabel()
    private let datePicker = UIDatePicker()
    private let confirmButton = UIButton(type: .system)
    
    
    init(dataBuilder: ScanDataBuilder) {
        self.dataBuilder = dataBuilder
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        overrideUserInterfaceStyle = .dark
        setupUI()
    }

    private func setupUI() {
        questionLabel.text = "when were you born?"
        questionLabel.font = .systemFont(ofSize: 28, weight: .bold)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(questionLabel)
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.backgroundColor = .black
        datePicker.tintColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        
        confirmButton.setTitle("complete profile", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        confirmButton.backgroundColor = .white
        confirmButton.setTitleColor(.black, for: .normal)
        confirmButton.layer.cornerRadius = 25
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(didTapComplete), for: .touchUpInside)
        view.addSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60), // Matched BaseBagua spacing
            questionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            datePicker.widthAnchor.constraint(equalToConstant: 320),
            
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmButton.widthAnchor.constraint(equalToConstant: 220),
            confirmButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    
    @objc func didTapComplete() {
        dataBuilder.birthDate = datePicker.date
        guard let finalData = dataBuilder.toScanData() else { return }
        
        let scannerVC = ViewController()
        scannerVC.config = finalData
        navigationController?.pushViewController(scannerVC, animated: true)
        print("Data Ready: \(finalData)")
    }
}
