//
//  LoadingCell.swift
//  Dog MessagesExtension
//
//  Created by Mike on 2/6/26.
//

import UIKit

class LoadingCell: UICollectionViewCell {
    
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .large)
    private let loadingLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Configure activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .label
        contentView.addSubview(activityIndicator)
        
        // Configure loading label
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = "Loading Stickers..."
        loadingLabel.textAlignment = .center
        loadingLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        loadingLabel.textColor = .label
        loadingLabel.numberOfLines = 0
        contentView.addSubview(loadingLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -20),
            
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            loadingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            loadingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
        
        activityIndicator.startAnimating()
    }
}
