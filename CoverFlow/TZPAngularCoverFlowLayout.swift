//
//  TZPAngularCoverFlowLayout.swift
//  CoverFlow
//
//  Created by Eric Miller on 1/27/17.
//  Copyright © 2017 Tiny Zepplin. All rights reserved.
//

import UIKit

class TZPAngularCoverFlowLayout: UICollectionViewFlowLayout {
    
    /**
     A spacing value applied to the item size to inset the cell from the left
     and right edges to give a card effect.
     */
    @IBInspectable var itemSpacing: CGFloat = 0.0
    
    /**
     Should be a value between 0.0 and 1.0.
     */
    @IBInspectable var scaleFactor: CGFloat = 1.0 {
        didSet {
            if scaleFactor > 1.0 {
                scaleFactor = 1.0
            } else if scaleFactor < 0.0 {
                scaleFactor = 0.0
            }
        }
    }
    
    /**
     Desired item rotation in degrees.
     */
    @IBInspectable var rotationAngle: CGFloat = 0.0
    
    /**
     Should be a value between 0.0 and 1.0.
     */
    @IBInspectable var flickVelocityThreshold: CGFloat = 0.5 {
        didSet {
            if flickVelocityThreshold > 1.0 {
                flickVelocityThreshold = 1.0
            } else if flickVelocityThreshold < 0.0 {
                flickVelocityThreshold = 0.0
            }
        }
    }
    
    fileprivate var numberOfDataSourceItems: Int = 0
    
    override func prepare() {
        super.prepare()
        precondition(self.scrollDirection == .horizontal, "TZPAngularCoverFlowLayout")
        precondition(collectionView!.numberOfSections == 1, "TZPAngularCoverFlowLayout only supports 1 section")
        
        numberOfDataSourceItems = collectionView?.numberOfItems(inSection: 0) ?? 0
    }
    
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            preconditionFailure("Must have a collection view.")
        }
        
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let contentSize = CGSize(
            width: CGFloat(numberOfItems) * itemWidth(),
            height: collectionView.bounds.height
        )
        return contentSize
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
        
        // Swiping left on the first item
        if newBounds.origin.x < 0.0 {
            return false
        }
        
        // Swiping right on the last item
        let lastPageXOffset = collectionView.contentSize.width - itemWidth()
        if newBounds.origin.x > lastPageXOffset {
            return false
        }
        
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        // Not optimized to only update possibly visible cells
        let startIndex = 0
        let endIndex = collectionView.numberOfItems(inSection: 0) - 1

        var attributesList: [UICollectionViewLayoutAttributes] = []
        for row in startIndex...endIndex {
            let path = IndexPath(row: row, section: 0)
            if let attrs = layoutAttributesForItem(at: path) {
                attributesList.append(attrs)
            }
        }
        
        return attributesList
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else {
            return super.layoutAttributesForItem(at: indexPath)
        }
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let centerX = ((itemWidth() * CGFloat(indexPath.row))) + (collectionView.bounds.width / 2.0)
        attributes.size = self.itemSize
        attributes.center = CGPoint(x: centerX, y: self.collectionView!.bounds.midY)
        
        return interpolate(attributes, forXOffset: collectionView.contentOffset.x)
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        let isScrollingRight = velocity.x >= 0.0
        let rawPageValue = collectionView.contentOffset.x / collectionView.bounds.width
        let currentPageIndex = isScrollingRight ? floor(rawPageValue) : ceil(rawPageValue)
        let nextPageIndex = isScrollingRight ? ceil(rawPageValue) : floor(rawPageValue)
        let adjustedPageValue = isScrollingRight ? abs(rawPageValue - currentPageIndex) : (1 - abs(rawPageValue - currentPageIndex))
    
        var minMin: CGFloat = 0.0
        if flickVelocityThreshold  < abs(velocity.x) {
            minMin = nextPageIndex
        } else {
            if adjustedPageValue > 0.5 {
                minMin = nextPageIndex
            } else {
                minMin = currentPageIndex
            }
        }
        
        let clampedIndex = clamp(minMin: minMin, minMax: CGFloat(numberOfDataSourceItems - 1), maxMax: 0)
        var newXOffset = clampedIndex * collectionView.bounds.width
        newXOffset = newXOffset == 0.0 ? 1.0 : newXOffset
        
        let targetContentOffset = CGPoint(
            x: newXOffset,
            y: proposedContentOffset.y
        )
        return targetContentOffset
    }
    
    // MARK: - Private
    fileprivate func interpolate(_ attributes: UICollectionViewLayoutAttributes, forXOffset xOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        guard let collectionView = collectionView else {
            preconditionFailure("Must have a collection view")
        }
        
        let attributesPath = attributes.indexPath
        
        let collectionViewWidth = collectionView.bounds.width
        let minInterval = CGFloat(attributesPath.row - 1) * collectionViewWidth
        let maxInterval = CGFloat(attributesPath.row + 1) * collectionViewWidth
        
        let minX: CGFloat = 0.0
        let maxX: CGFloat = collectionView.bounds.width
        let spanX = maxX - minX
        
        let interpolatedX = min(max(minX + ((spanX / (maxInterval - minInterval)) * (xOffset - minInterval)), minX), maxX)
        
        var tf = CATransform3DIdentity
        let rotationInterpolationFactor = interpolationFactor(with: interpolatedX, span: spanX, adjustment: rotationAngle)
        let angle = -rotationAngle + rotationInterpolationFactor
        tf = CATransform3DRotate(tf, -degreesToRad(angle), 0, 0, 1)
        
        let scaleInterpolationFactor = interpolationFactor(with: interpolatedX, span: spanX, adjustment: (1.0 - scaleFactor))
        let scale = 1.0 - abs(1 - scaleFactor - scaleInterpolationFactor)
        tf = CATransform3DScale(tf, scale, scale, scale)
        
        attributes.transform3D = tf
        return attributes
    }
    
    fileprivate func interpolationFactor(with interpolatedX: CGFloat, span: CGFloat, adjustment: CGFloat) -> CGFloat {
        return interpolatedX * 2 * adjustment / span
    }
    
    fileprivate func itemWidth() -> CGFloat {
        return itemSize.width + (itemSpacing * 2)
    }
}

fileprivate func clamp<T: Comparable>(minMin: T, minMax: T, maxMax: T) -> T {
    return max(min(minMin, minMax), maxMax)
}

fileprivate func degreesToRad(_ degrees:CGFloat)->CGFloat {
    return CGFloat(Double(degrees) * M_PI / 180)
}
