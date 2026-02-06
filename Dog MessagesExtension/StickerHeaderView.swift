//
//  StickerHeaderView.swift
//  Dog MessagesExtension
//
//  Created by Mike on 2/6/26.
//  Copyright © 2026 Mike. All rights reserved.
//

import UIKit

protocol StickerHeaderViewDelegate: AnyObject {
    func stickerHeaderViewDidTapDismiss(_ headerView: StickerHeaderView)
}

class StickerHeaderView: UICollectionReusableView {
    
    static let reuseIdentifier = "StickerHeaderView"
    
    weak var delegate: StickerHeaderViewDelegate?
    
    // MARK: - Layout Constants
    static let containerVerticalPadding: CGFloat = 4 // top and bottom padding around container
    static let containerHorizontalPadding: CGFloat = 20 // left and right padding around container
    static let contentVerticalPadding: CGFloat = 12 // top and bottom padding inside container
    
    // Horizontal spacing constants
    static let contentLeadingPadding: CGFloat = 20 // left padding from container edge to icon
    static let iconWidth: CGFloat = 28 // icon width
    static let iconToTextSpacing: CGFloat = 14 // gap between icon and text
    static let textToButtonSpacing: CGFloat = 16 // gap between text and button
    static let buttonWidth: CGFloat = 36 // dismiss button width
    static let buttonTrailingPadding: CGFloat = 18 // right padding from button to container edge
    
    static let labelStackSpacing: CGFloat = 1 // gap between title and subtitle
    static let minHeight: CGFloat = 70
    
    // Computed properties
    static var horizontalPadding: CGFloat { containerHorizontalPadding * 2 }
    static var verticalPadding: CGFloat { containerVerticalPadding * 2 + contentVerticalPadding * 2 }
    static var contentPadding: CGFloat { 
        contentLeadingPadding + iconWidth + iconToTextSpacing + textToButtonSpacing + buttonWidth + buttonTrailingPadding 
    }
    
    // MARK: - Height Calculation
    static func calculateHeight(for width: CGFloat, message: String) -> CGFloat {
        // Calculate title label height
        let titleFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let titleHeight = ceil(titleFont.lineHeight)
        
        // Calculate subtitle label height
        let availableWidth = width - horizontalPadding - contentPadding
        let labelSize = (message as NSString).boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular)],
            context: nil
        )
        
        // Add title + spacing + subtitle
        let totalTextHeight = titleHeight + labelStackSpacing + ceil(labelSize.height)
        let calculatedHeight = totalTextHeight + verticalPadding
        
        return max(minHeight, calculatedHeight)
    }
    
    private let blurEffectView: UIVisualEffectView = {
        // Use Liquid Glass effect if available (iOS 26.0+), fallback to blur
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect()
            // Make the glass interactive so it reacts to touch
            glassEffect.isInteractive = true
            effect = glassEffect
        } else {
            // Fallback to standard blur for iOS < 26.0
            effect = UIBlurEffect(style: .systemMaterial)
        }
        let effectView = UIVisualEffectView(effect: effect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        return effectView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear // Make transparent so blur shows through
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 14 // Icon to text gap - set by iconToTextSpacing constant
        stack.alignment = .center // Center alignment for single-line text
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let leadingIcon: UIImageView = {
        let icon = UIImageView()
        // Use hierarchical rendering mode with primary color
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            .applying(UIImage.SymbolConfiguration(hierarchicalColor: .label))
        icon.image = UIImage(systemName: "hand.tap.fill", withConfiguration: config)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.isUserInteractionEnabled = false
        return icon
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Drag onto messages"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure title doesn't get compressed
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return label
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Tap and hold a sticker to drag it onto a message"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure label expands vertically and doesn't get compressed
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return label
    }()
    
    private lazy var labelStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, label])
        stack.axis = .vertical
        stack.spacing = Self.labelStackSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        
        // Close button icon
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .label
        
        // Add adaptive background that works in both light and dark mode
        button.backgroundColor = .tertiarySystemFill
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        
        // Important: Set content mode and image alignment
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(containerView)
        
        // Add blur effect as the background of the container
        containerView.addSubview(blurEffectView)
        
        // Add icon and label stack to content stack
        contentStack.addArrangedSubview(leadingIcon)
        contentStack.addArrangedSubview(labelStack)
        
        // Add subviews to the blur's content view for proper layering
        blurEffectView.contentView.addSubview(contentStack)
        blurEffectView.contentView.addSubview(dismissButton)
        
        NSLayoutConstraint.activate([
            // Container constraints (with padding)
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: Self.containerVerticalPadding),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.containerHorizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.containerHorizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.containerVerticalPadding),
            
            // Blur effect fills the entire container
            blurEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Leading icon size
            leadingIcon.widthAnchor.constraint(equalToConstant: Self.iconWidth),
            leadingIcon.heightAnchor.constraint(equalToConstant: Self.iconWidth),
            
            // Content stack positioning - with vertical padding
            contentStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Self.contentVerticalPadding),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Self.contentVerticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Self.contentLeadingPadding),
            contentStack.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor, constant: -Self.textToButtonSpacing),
            
            // Dismiss button constraints - centered vertically
            dismissButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Self.buttonTrailingPadding),
            dismissButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            dismissButton.heightAnchor.constraint(equalToConstant: Self.buttonWidth)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Make container and blur fully rounded (pill shape)
        let cornerRadius = containerView.bounds.height / 2
        containerView.layer.cornerRadius = cornerRadius
        containerView.layer.masksToBounds = true
        
        blurEffectView.layer.cornerRadius = cornerRadius
        blurEffectView.layer.masksToBounds = true
        
        // Make dismiss button fully rounded (circle)
        dismissButton.layer.cornerRadius = dismissButton.bounds.height / 2
        dismissButton.layer.masksToBounds = true
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            // Start animating the icon when the view appears
            startIconAnimation()
        } else {
            // Stop the timer when the view is removed from the window
            stopIconAnimation()
        }
    }
    
    private func startIconAnimation() {
        // Use manual UIView animation for reliable, predictable behavior
        // This avoids issues with symbol effects getting stuck in scaled states
        animateIconManually()
    }
    
    private func animateIconManually() {
        // Simple scale down animation
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
            self.leadingIcon.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            // Scale back up after a short pause
            UIView.animate(withDuration: 0.35, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                self.leadingIcon.transform = .identity
            }) { _ in
                // Wait 3 seconds then repeat
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if self.window != nil {
                        self.animateIconManually()
                    }
                }
            }
        }
    }
    
    private func stopIconAnimation() {
        // Clean up all animations and reset transform
        leadingIcon.layer.removeAllAnimations()
        leadingIcon.transform = .identity
    }
    
    @objc private func dismissButtonTapped() {
        delegate?.stickerHeaderViewDidTapDismiss(self)
    }
    
    func configure(message: String) {
        label.text = message
    }
}

