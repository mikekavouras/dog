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
    fileprivate let perRow: CGFloat = 3
    private var stickers = [MSSticker]()
    
    lazy private var database: CKDatabase = {
        let container = CKContainer(identifier: "iCloud.com.mikekavouras.DogCMS")
        return container.publicCloudDatabase
    }()
    
    lazy private var documentDirectoryPath: String? = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let documentDirectoryPath = paths.first {
            return "\(documentDirectoryPath)/Dog/Dog"
        }
        return nil
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    private func setup() {
        setupStickers()
        setupFileSystem()
    }

    private func setupStickers() {
        guard let path = documentDirectoryPath else { return }
        
        fetchStickers { maybeRecords in
            guard let records = maybeRecords else { return }
            // generate images from asset data
            
            records.forEach { record in
                if let asset = record["image"] as? CKAsset,
                    let data = try? Data(contentsOf: asset.fileURL),
                    let image = UIImage(data: data)
                {
                    let filename = "\(path)/\(record.recordID.recordName).png"
                    print(filename)
                    let png = UIImagePNGRepresentation(image)
                    do {
                        let url = URL(fileURLWithPath: filename)
                        try png?.write(to: url)
                        let sticker = try MSSticker(contentsOfFileURL: url, localizedDescription: "")
                        self.stickers.append(sticker)
                    }
                    catch {
                        print(error)
                    }
                }
                self.collectionView?.reloadData()
            }
        }
    }
    
    private func setupFileSystem() {
        if let path = documentDirectoryPath {
            let manager = FileManager.default
            if !manager.fileExists(atPath: path) {
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Couldn't create your directory")
                }
            }
        }
    }
    
    private func fetchStickers(_ onCompletion: @escaping ([CKRecord]?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Sticker", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        let operation = CKQueryOperation(query: query)
        operation.qualityOfService = .userInitiated
        database.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                onCompletion(records)
            }
        }
    }
}

extension StickerCollectionViewController {
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? StickerCell else {
            return UICollectionViewCell()
        }
        cell.stickerView.sticker = stickers[indexPath.row]
        return cell
    }
}

extension StickerCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.size.width - (padding * 4)) / perRow
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
