//
//  StickerCollectionViewController.swift
//  Dog MessagesExtension
//
//  Created by Mike on 7/6/18.
//  Copyright © 2018 Mike. All rights reserved.
//

import UIKit
import Messages
import CloudKit

private let reuseIdentifier = "Cell"

class StickerCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    fileprivate let padding: CGFloat = 8
    private var stickers = [MSSticker]()
    private var isFirstLaunch = true
    private weak var headerView: StickerHeaderView?
    private var hasAnimatedHeader = false
    
    // MARK: - Header Configuration
    
    // Header dismissal state
    private var isHeaderDismissed: Bool {
        get {
            UserDefaults.standard.bool(forKey: "stickerHeaderDismissed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "stickerHeaderDismissed")
        }
    }
    
    // Calculate columns dynamically based on width
    private var columnsPerRow: CGFloat {
        guard let collectionView = collectionView else { return 3 }
        let width = collectionView.bounds.width
        // Use 3 columns for portrait-ish widths, 5 for landscape-ish widths
        // Rough threshold: if width > 500, use 5 columns, otherwise 3
        return width > 500 ? 5 : 3
    }
    
    lazy private var database: CKDatabase = {
        let container = CKContainer(identifier: "iCloud.com.mikekavouras.DogCMS")
        return container.publicCloudDatabase
    }()
    
    lazy private var documentDirectoryPath: URL? = {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("Dog/Dog")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🟢 viewDidLoad called")
        
        // MARK: - DEBUG: Uncomment to reset header dismissal for testing
//         UserDefaults.standard.removeObject(forKey: "stickerHeaderDismissed")

        // Register the header view for collection view
        collectionView?.register(StickerHeaderView.self, 
                                 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, 
                                 withReuseIdentifier: StickerHeaderView.reuseIdentifier)
        
        // Set up liquid glass first (if enabled)
        // Temporarily disabled to test
        // setupLiquidGlassBackground()
        
        // Load stickers synchronously before first display to avoid flicker
        loadInitialStickers()
    }
    
    
    private func showLoadingIndicator() {
        guard collectionView?.backgroundView == nil else { return }
        
        print("📍 Showing loading indicator")
        let loadingBackgroundView = UIView()
        loadingBackgroundView.backgroundColor = .clear
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .label
        activityIndicator.startAnimating()
        loadingBackgroundView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: loadingBackgroundView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingBackgroundView.centerYAnchor)
        ])
        
        collectionView?.backgroundView = loadingBackgroundView
    }
    
    private func hideLoadingIndicator() {
        print("📍 Hiding loading indicator")
        collectionView?.backgroundView = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🟢 viewWillAppear called")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🟢 viewDidAppear called - drawer should be visible now")
        
        // Trigger header animation now that everything is visible
        if !hasAnimatedHeader, let header = headerView {
            hasAnimatedHeader = true
            header.animateIn()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Invalidate layout when rotating to recalculate cell sizes and header
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
    
    private func clearCache() {
        print("🗑️ Clearing cache for testing...")
        
        // Clear sticker files
        if let directoryURL = documentDirectoryPath {
            let manager = FileManager.default
            if manager.fileExists(atPath: directoryURL.path) {
                do {
                    let files = try manager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                    for file in files {
                        try manager.removeItem(at: file)
                        print("   Deleted: \(file.lastPathComponent)")
                    }
                    print("✅ Cache cleared successfully")
                } catch {
                    print("❌ Error clearing cache: \(error)")
                }
            }
        }
        
        // Clear metadata
        if let metadataURL = metadataFileURL {
            try? FileManager.default.removeItem(at: metadataURL)
            print("✅ Metadata cleared")
        }
    }
    
    private func setupLiquidGlassBackground() {
        if #available(iOS 26.0, *) {
            // Create a Liquid Glass effect for the background
            let glassEffect = UIGlassEffect()
            
            // Create a visual effect view with the glass effect
            let glassBackgroundView = UIVisualEffectView(effect: glassEffect)
            glassBackgroundView.frame = view.bounds
            glassBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Insert the glass background behind the collection view
            view.insertSubview(glassBackgroundView, at: 0)
            
            // Make the collection view background transparent so glass shows through
            collectionView?.backgroundColor = .clear
        } else {
            // Fallback for older iOS versions - use a blur effect
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            let blurBackgroundView = UIVisualEffectView(effect: blurEffect)
            blurBackgroundView.frame = view.bounds
            blurBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            view.insertSubview(blurBackgroundView, at: 0)
            collectionView?.backgroundColor = .clear
        }
    }

    private func syncWithCloudKit(directoryURL: URL) async {
        print("🔄 Starting background sync with CloudKit...")
        
        do {
            let records = try await fetchStickers()
            print("✅ Fetched \(records.count) stickers from CloudKit")
            
            let metadata = loadStickerMetadata()
            var updatedStickers: [MSSticker] = []
            var needsUpdate = false
            
            // Track which record names we got from CloudKit
            let cloudKitRecordNames = Set(records.map { $0.recordID.recordName })
            
            // STEP 1: Process all CloudKit records (download new/updated)
            for record in records {
                let recordName = record.recordID.recordName
                let fileURL = directoryURL.appendingPathComponent("\(recordName).png")
                let description = (record["description"] as? String) ?? "Dog Sticker"
                
                // Check if we need to download this sticker
                let needsDownload = !FileManager.default.fileExists(atPath: fileURL.path) ||
                                   hasRecordChanged(record, metadata: metadata)
                
                if needsDownload {
                    print("   ⬇️ Downloading: \(recordName)")
                    if let asset = record["image"] as? CKAsset,
                       let data = try? Data(contentsOf: asset.fileURL),
                       let image = UIImage(data: data),
                       let png = UIImagePNGRepresentation(image)
                    {
                        try png.write(to: fileURL)
                        needsUpdate = true
                        
                        // Update metadata
                        saveStickerMetadata(recordName: recordName, 
                                          modificationDate: record.modificationDate,
                                          description: description)
                        print("   ✅ Downloaded: \(recordName)")
                    }
                }
                
                // Load the sticker
                if let sticker = try? MSSticker(contentsOfFileURL: fileURL, localizedDescription: description) {
                    updatedStickers.append(sticker)
                }
            }
            
            // STEP 2: Clean up deleted stickers (files that exist locally but aren't in CloudKit)
            let manager = FileManager.default
            if let localFiles = try? manager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                .filter({ $0.pathExtension == "png" }) {
                
                for localFile in localFiles {
                    let recordName = localFile.deletingPathExtension().lastPathComponent
                    if !cloudKitRecordNames.contains(recordName) {
                        // This file was deleted from CloudKit - remove it
                        print("   🗑️ Removing deleted sticker: \(recordName)")
                        try? manager.removeItem(at: localFile)
                        needsUpdate = true
                    }
                }
            }
            
            // STEP 3: Sort stickers by CloudKit order
            let recordOrder = records.map { $0.recordID.recordName }
            updatedStickers.sort { sticker1, sticker2 in
                let url1 = sticker1.imageFileURL.lastPathComponent.replacingOccurrences(of: ".png", with: "")
                let url2 = sticker2.imageFileURL.lastPathComponent.replacingOccurrences(of: ".png", with: "")
                let index1 = recordOrder.firstIndex(of: url1) ?? Int.max
                let index2 = recordOrder.firstIndex(of: url2) ?? Int.max
                return index1 < index2
            }
            
            // STEP 4: Update UI if there were changes
            let hasChanges = updatedStickers.count != self.stickers.count || needsUpdate
            
            if hasChanges {
                print("🔄 Changes detected - updating collection view")
                await MainActor.run {
                    self.stickers = updatedStickers
                    // Hide loading if this is first launch
                    if self.isFirstLaunch {
                        hideLoadingIndicator()
                        self.isFirstLaunch = false
                    }
                    self.collectionView?.reloadData()
                }
            } else {
                print("✅ No changes - stickers are up to date")
                // Still hide loading if first launch completed successfully
                if self.isFirstLaunch {
                    await MainActor.run {
                        hideLoadingIndicator()
                        self.isFirstLaunch = false
                    }
                }
            }
            
        } catch {
            print("❌ CloudKit sync failed: \(error.localizedDescription)")
            
            // Check for specific CloudKit errors
            if let ckError = error as? CKError {
                switch ckError.code {
                case .notAuthenticated:
                    print("⚠️ Not signed into iCloud")
                case .networkUnavailable, .networkFailure:
                    print("⚠️ Network unavailable")
                case .permissionFailure:
                    print("⚠️ Permission denied")
                case .unknownItem:
                    print("⚠️ CloudKit container not found")
                default:
                    print("⚠️ CloudKit error: \(ckError.code.rawValue)")
                }
            }
            
            print("📱 Continuing with cached stickers")
        }
    }
    
    private func hasRecordChanged(_ record: CKRecord, metadata: [String: StickerMetadata]) -> Bool {
        let recordName = record.recordID.recordName
        guard let cachedMetadata = metadata[recordName] else { return true }
        return record.modificationDate != cachedMetadata.modificationDate
    }
    
    // MARK: - Metadata Management
    
    private struct StickerMetadata: Codable {
        let modificationDate: Date?
        let description: String
    }
    
    private var metadataFileURL: URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("Dog/sticker_metadata.json")
    }
    
    private func loadStickerMetadata() -> [String: StickerMetadata] {
        guard let fileURL = metadataFileURL,
              let data = try? Data(contentsOf: fileURL),
              let metadata = try? JSONDecoder().decode([String: StickerMetadata].self, from: data)
        else { return [:] }
        return metadata
    }
    
    private func saveStickerMetadata(recordName: String, modificationDate: Date?, description: String) {
        guard let fileURL = metadataFileURL else { return }
        
        var metadata = loadStickerMetadata()
        metadata[recordName] = StickerMetadata(modificationDate: modificationDate, description: description)
        
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: fileURL)
        }
    }
    
    // MARK: - Initial Loading (Synchronous to prevent flicker)
    
    private func loadInitialStickers() {
        // Create directory if needed
        guard let directoryURL = documentDirectoryPath else { return }
        
        let manager = FileManager.default
        if !manager.fileExists(atPath: directoryURL.path) {
            try? manager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Load cached stickers SYNCHRONOUSLY on main thread
        // This prevents the flicker on launch by having content ready before first display
        print("📂 Loading initial stickers synchronously")
        
        guard let fileURLs = try? manager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "png" })
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        else {
            print("📭 No cached stickers - first launch detected")
            isFirstLaunch = true
            showLoadingIndicator()
            // Start async sync for first launch
            Task { await syncWithCloudKit(directoryURL: directoryURL) }
            return
        }
        
        let metadata = loadStickerMetadata()
        var cachedStickers: [MSSticker] = []
        
        for fileURL in fileURLs {
            let recordName = fileURL.deletingPathExtension().lastPathComponent
            let description = metadata[recordName]?.description ?? "Dog Sticker"
            
            if let sticker = try? MSSticker(contentsOfFileURL: fileURL, localizedDescription: description) {
                cachedStickers.append(sticker)
            }
        }
        
        if !cachedStickers.isEmpty {
            print("✅ Loaded \(cachedStickers.count) stickers synchronously - ready for display")
            self.stickers = cachedStickers
            isFirstLaunch = false
            
            // Now sync in background
            Task { await syncWithCloudKit(directoryURL: directoryURL) }
        } else {
            print("⚠️ Found files but couldn't load - showing loading")
            isFirstLaunch = true
            showLoadingIndicator()
            Task { await syncWithCloudKit(directoryURL: directoryURL) }
        }
    }
    
    private func setupFileSystem() {
        if let directoryURL = documentDirectoryPath {
            let manager = FileManager.default
            if !manager.fileExists(atPath: directoryURL.path) {
                do {
                    try manager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Couldn't create your directory: \(error)")
                }
            }
        }
    }
    
    private func fetchStickers() async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Sticker", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        let result = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperationMaximumResults)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        return records
    }
}

// MARK: - UICollectionViewDataSource
// MARK: -

extension StickerCollectionViewController {


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("📊 numberOfItemsInSection: returning \(stickers.count) stickers")
        return stickers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("📱 cellForItemAt: \(indexPath.item)")
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? StickerCell else {
            print("   ❌ Failed to dequeue StickerCell")
            return UICollectionViewCell()
        }
        
        print("   ✅ Setting sticker for cell \(indexPath.item)")
        cell.stickerView.sticker = stickers[indexPath.row]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: StickerHeaderView.reuseIdentifier,
                for: indexPath
            ) as? StickerHeaderView else {
                return UICollectionReusableView()
            }
            
            headerView.delegate = self
            headerView.configure(message: StickerHeaderView.defaultInstruction)
            self.headerView = headerView // Store reference for later animation
            return headerView
        }
        
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
// MARK: - 

extension StickerCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // Only show header if not dismissed and stickers are loaded
        if !isHeaderDismissed && !stickers.isEmpty {
            let width = collectionView.bounds.width
            let height = StickerHeaderView.calculateHeight(for: width, message: StickerHeaderView.defaultInstruction)
            return CGSize(width: width, height: height)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Use collection view's current width for accurate sizing during rotation
        let collectionWidth = collectionView.bounds.width
        let columns = columnsPerRow
        let width = (collectionWidth - (padding * (columns + 1))) / columns
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return padding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return padding
    }
}
// MARK: - StickerHeaderViewDelegate
// MARK: -

extension StickerCollectionViewController: StickerHeaderViewDelegate {
    func stickerHeaderViewDidTapDismiss(_ headerView: StickerHeaderView) {
        print("📍 Header dismissed by user")
        
        // Save dismissal state
        isHeaderDismissed = true
        
        // Animate header removal by invalidating layout
        collectionView?.performBatchUpdates({
            collectionView?.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
}

