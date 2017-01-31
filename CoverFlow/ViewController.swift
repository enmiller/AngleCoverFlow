//
//  ViewController.swift
//  CoverFlow
//
//  Created by Eric Miller on 1/27/17.
//  Copyright © 2017 Tiny Zepplin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var firstBackgroundImageView: UIImageView!
    @IBOutlet weak var secondBackgroundImageView: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    fileprivate let image1 = UIImage(imageLiteralResourceName: "cover_flow_1")
    fileprivate let image2 = UIImage(imageLiteralResourceName: "cover_flow_2")
    fileprivate let image3 = UIImage(imageLiteralResourceName: "cover_flow_3")
    
    var samples: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        samples.append(contentsOf: [image1, image2, image3])
        
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.backgroundColor = UIColor.clear
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let flowLayout = collectionView.collectionViewLayout as? TZPAngularCoverFlowLayout {
            flowLayout.itemSize = CGSize(
                width: collectionView.bounds.width - (flowLayout.itemSpacing * 2),
                height: collectionView.bounds.height - 80 // this is just a number I made up for the demo.
            )
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
        updateBackgroundImageViews()
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return samples.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as? TZPCircularCollectionViewCell else {
            preconditionFailure("Unexpected cell type")
        }
        
        cell.imageView.image = samples[indexPath.row]
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected \(indexPath)")
    }
    
    // MARK: - UIScrollViewDelegate
    fileprivate var currentPageIndex: Int = 0
    fileprivate var currentContentOffsetX: CGFloat = 0.0
    fileprivate var possibleNextIndex: Int = 1
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // There is at least one known issue regarding scrolling:
        // 1. Changing direction while between two cells will cause a slight flicker.
        // I believe this could be resolved with some optimizations in the update code
        
        let offsetX = scrollView.contentOffset.x
        let scrollingRight = currentContentOffsetX < offsetX
        let lastPage = currentPageIndex == (samples.count - 1)
        
        let rawPageValue = offsetX / scrollView.bounds.width
        let currentIndex = scrollingRight ? max(Int(floor(rawPageValue)), 0) : min(Int(ceil(rawPageValue)), samples.count-1)
        let nextIndex = scrollingRight ? Int(ceil(rawPageValue)) : max(Int(floor(rawPageValue)), 0)
        let adjustedPageValue = scrollingRight ? abs(rawPageValue - CGFloat(currentIndex)) : (1 - abs(rawPageValue - CGFloat(currentIndex)))
        var needsUpdating: Bool = false
        
        if currentPageIndex == currentIndex {
            if lastPage, scrollingRight {
                // Prevents the last page from applying the fade value to the background image view
                return
            }
            
            firstBackgroundImageView.alpha = scrollingRight ? 1 - adjustedPageValue : adjustedPageValue
            secondBackgroundImageView.alpha = scrollingRight ? adjustedPageValue : 1 - adjustedPageValue
        } else {
            needsUpdating = true
        }
        
        if possibleNextIndex != nextIndex {
            needsUpdating = true
        }
        
        self.currentPageIndex = currentIndex
        self.currentContentOffsetX = offsetX
        self.possibleNextIndex = nextIndex
        
        if needsUpdating {
            updateBackgroundImageViews()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let rawPageValue = offsetX / scrollView.bounds.width
        let currentIndex = max(Int(floor(rawPageValue)), 0)
        self.currentPageIndex = currentIndex
        self.currentContentOffsetX = offsetX
        
        updateBackgroundImageViews()
    }
    
    fileprivate func updateBackgroundImageViews() {
        var nextIndex = possibleNextIndex
        if nextIndex == (samples.count) {
            nextIndex = max(nextIndex - 2, 0)
        }
        
        firstBackgroundImageView.image = samples[currentPageIndex]
        firstBackgroundImageView.alpha = 1.0
        secondBackgroundImageView.alpha = 0.0
        secondBackgroundImageView.image = samples[nextIndex]
    }
}

