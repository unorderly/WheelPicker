import UIKit
import Combine

protocol CollectionCell: UICollectionViewCell {
    associatedtype Value: Hashable

    func set(value: Value)
}

protocol CollectionCenter: UIView {
    associatedtype Value: Hashable

    func set(value: Value)
}

class CollectionPickerView<Cell: CollectionCell, Center: CollectionCenter>: UICollectionView, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate where Cell.Value == Center.Value {
    var values: [Cell.Value] = [] {
        didSet {
            self.reload()
        }
    }

    private lazy var diffDataSource: UICollectionViewDiffableDataSource<Int, Cell.Value> = {
        let cellRegistration = UICollectionView.CellRegistration<Cell, Cell.Value> { cell, _, value in
            cell.set(value: value)
        }

//        let centerRegistration = UICollectionView.SupplementaryRegistration<Center>(elementKind: "center") { view, _, _ in
////            view
//        }

        let dataSource = UICollectionViewDiffableDataSource<Int, Cell.Value>(collectionView: self) { collectionView, indexPath, id in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                for: indexPath,
                                                                item: id)
        }
//        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
//            if kind == "center" && indexPath == IndexPath(item: 0, section: 0) {
//                return collectionView.dequeueConfiguredReusableSupplementary(using: centerRegistration, for: indexPath)
//            }
//            return nil
//        }
        return dataSource
    }()

    private lazy var sizingCell: Cell = Cell()

    public let publisher: CurrentValueSubject<Cell.Value, Never>

    private var selectedIndex: Int {
        didSet {
            if self.values.indices.contains(self.selectedIndex), oldValue != self.selectedIndex {
                self.publisher.send(values[self.selectedIndex])
                self.layout?.selected = values[self.selectedIndex]
            }
        }
    }

    init(values: [Cell.Value], selected: Cell.Value) {
        self.publisher = CurrentValueSubject(selected)
        self.selectedIndex = values.firstIndex(of: selected) ?? 0
        let layout = Layout<Center>(selected: selected)
        super.init(frame: .zero, collectionViewLayout: layout)
        self.delegate = self
        self.dataSource = self.diffDataSource
        self.values = values

        self.isScrollEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollView.DecelerationRate.fast
        self.backgroundColor = UIColor.clear

        self.layer.sublayerTransform = {
            var transform = CATransform3DIdentity;
            transform.m34 = -1.0 / 2000;
            return transform;
        }()

        self.reload()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reload() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Cell.Value>()
        snapshot.appendSections([0])
        snapshot.appendItems(values, toSection: 0)

        diffDataSource.apply(snapshot, animatingDifferences: false, completion: nil)

//        self.collectionViewLayout.invalidateLayout()
    }


    var layout: Layout<Center>? {
        return self.collectionViewLayout as? Layout<Center>
    }

    func offsetForItem(at index: Int) -> CGFloat {
        var offset = self.layout?.originalAttributesForItem(at: IndexPath(item: index, section: 0))?.frame.midY ?? 0
        offset -= self.bounds.height / 2
        return offset
    }

    func select(value: Cell.Value) {
        if !self.isDragging, !self.isDecelerating,
           let index = self.values.firstIndex(of: value),
           index != selectedIndex {
            self.scrollToItem(at: index)
        }
    }

    func scrollToItem(at index: Int, animated: Bool = true) {
        guard values.indices.contains(index) else {
            return
        }

        self.setContentOffset(
            CGPoint(
                x: self.contentOffset.x,
                y: offsetForItem(at: index)),
            animated: animated)
        self.selectedIndex = index
    }

    func didScroll(end: Bool) {
        let mid = CGRect(x: self.contentOffset.x + self.bounds.width / 2,
                        y: self.contentOffset.y + self.bounds.height / 2,
                        width: 1,
                        height: 1)
         let cells = visibleCells.filter({ cell in
            cell.frame.intersects(mid)
         })
         .compactMap(self.indexPath(for:))
         .sorted()

        if let index = cells.first?.item {

            self.selectedIndex = index

            if end {
                self.scrollToItem(at: index, animated: true)
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScroll(end: true)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        didScroll(end: !decelerate)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.didScroll(end: false)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.scrollToItem(at: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let number = collectionView.numberOfItems(inSection: section)
        let firstIndexPath = IndexPath(item: 0, section: section)
        let firstSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: firstIndexPath)
        let lastIndexPath = IndexPath(item: number - 1, section: section)
        let lastSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: lastIndexPath)
        return UIEdgeInsets(
            top: (collectionView.bounds.size.height - firstSize.height/2) / 2, left: 0,
            bottom: (collectionView.bounds.size.height - lastSize.height/2) / 2, right: 0
        )
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let value = self.diffDataSource.itemIdentifier(for: indexPath) else {
            return .zero
        }
        self.sizingCell.set(value: value)
        let size = self.sizingCell.systemLayoutSizeFitting(CGSize(width: collectionView.bounds.width, height: 0))
        return CGSize(width: collectionView.bounds.width, height: size.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

}


