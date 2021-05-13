#if canImport(AppKit)
import Combine
import AppKit

protocol NSScrollViewDelegate: AnyObject {
    func scrollViewDidScroll(_ scrollView: NSScrollView)
    func scrollViewDidEndScrolling(_ scrollView: NSScrollView)
}
class ScrollView: NSScrollView {
    weak var delegate: NSScrollViewDelegate?

    private var endPublisher: PassthroughSubject<Void, Never> = .init()

    private var cancellable: AnyCancellable?

    var isScrolling: Bool = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.cancellable = self.endPublisher.debounce(for: 0.4, scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                if let `self` = self {
                    self.delegate?.scrollViewDidEndScrolling(self)
                    self.isScrolling = false
                }
            })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
//        print("Scroll", event.scrollingDeltaY, event.hasPreciseScrollingDeltas, event.phase, event.momentumPhase, self.documentVisibleRect.origin)
        self.isScrolling = true
        delegate?.scrollViewDidScroll(self)
        self.endPublisher.send(())
    }
}


class CollectionPickerView<Cell: NSCollectionViewItem, Center: NSView, Value: Hashable>: NSView,
NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, NSScrollViewDelegate where Value: Comparable {
    var values: [Value] = [] {
        didSet {
            if self.values != oldValue {
                let selected = oldValue[self.selectedIndex]
                if let index = self.values.firstIndex(of: selected) {
                    self.selectedIndex = index
                } else {
                    self.selectedIndex = 0
                }
                self.reload()
            }
        }
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
                    self.scrollToItem(at: self.selectedIndex, animated: false)
    }

    private static var itemIdentifier: NSUserInterfaceItemIdentifier { NSUserInterfaceItemIdentifier("wheelpicker.item") }

    private lazy var diffDataSource: NSCollectionViewDiffableDataSource<Int, Value> = {
        self.collectionView.register(Cell.self, forItemWithIdentifier: Self.itemIdentifier)
        let dataSource = NSCollectionViewDiffableDataSource<Int, Value>(collectionView: self.collectionView) {
            collectionView, indexPath, id in
            let item = collectionView.makeItem(withIdentifier: Self.itemIdentifier, for: indexPath)
            if let cell = item as? Cell {
                self.configureCell(cell, id)
            }
            return item
        }
        return dataSource
    }()

    private lazy var sizingCell = Cell()

    public let publisher: CurrentValueSubject<Value, Never>

    private var selectedIndex: Int {
        didSet {
            if oldValue != self.selectedIndex {
                if let overriden = self.overriddenSelected,
                   let index = self.values.lastIndex(where: { $0 < overriden }),
                   index != self.selectedIndex {
                    self.overriddenSelected = nil
                }
                DispatchQueue.main.async {
                    self.publisher.send(self.selectedValue)
                }
                self.cvLayout?.selected = self.selectedValue
                self.updateAccessibility()
            }
        }
    }

    private var selectedValue: Value {
        if let overriden = self.overriddenSelected {
            return overriden
        } else if self.values.indices.contains(self.selectedIndex) {
            return self.values[self.selectedIndex]
        } else {
            return self.values[0]
        }
    }

    private var overriddenSelected: Value?

    var configureCell: (Cell, Value) -> Void

    var configureCenter: (Center, Value) -> Void {
        get { self.cvLayout?.configureCenter ?? { _, _ in } }
        set { self.cvLayout?.configureCenter = newValue }
    }

//    var centerSize: Int {
//        get { self.cvLayout?.centerSize ?? 1 }
//        set { self.cvLayout?.centerSize = newValue }
//    }

    var centerSize: Int = 1 {
        didSet {
            self.cvLayout?.centerSize = self.centerSize
            self.reload()
        }
    }
    init(values: [Value],
         selected: Value,
         configureCell: @escaping (Cell, Value) -> Void,
         configureCenter: @escaping (Center, Value) -> Void) {
        self.configureCell = configureCell
        self.publisher = CurrentValueSubject(selected)
        self.selectedIndex = values.firstIndex(of: selected) ?? 0
        super.init(frame: .zero)

        self.layer?.backgroundColor = NSColor.clear.cgColor

        let scrollView = ScrollView(frame: .zero)
        scrollView.delegate = self
        scrollView.scrollerInsets.right = -100
        scrollView.scrollerInsets.left = -100

        let cvLayout = Layout<Center, Value>(selected: selected, configureCenter: configureCenter)

        let cv = NSCollectionView(frame: .zero)
        scrollView.documentView = cv
        cv.collectionViewLayout = cvLayout
        self.collectionView = cv
        cv.allowsMultipleSelection = false
        cv.isSelectable = true
        cv.delegate = self
        cv.dataSource = self.diffDataSource
        cv.layer?.backgroundColor = NSColor.clear.cgColor
        cv.layer?.sublayerTransform = {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 2000
            return transform
        }()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            scrollView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            scrollView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0)
        ])

        self.values = values

        self.reload()

//        self.isAccessibilityElement = true
//        self.accessibilityTraits.insert(NSAccessibilityTraits.adjustable)
        self.updateAccessibility()
    }

//    override func accessibilityIncrement() {
//        let new = self.selectedIndex + 1
//        if self.values.indices.contains(new) {
//            self.scrollToItem(at: new)
//        }
//    }
//
//    override func accessibilityDecrement() {
//        let new = self.selectedIndex - 1
//        if self.values.indices.contains(new) {
//            self.scrollToItem(at: new)
//        }
//    }

    private func updateAccessibility() {
        let value = self.selectedValue
//        self.accessibilityValue = (value as? AccessibleValue)?.accessibilityText ?? (value as? CustomStringConvertible)?
//            .description
    }


    override func layout() {
        super.layout()
        self.layer?.mask = {
            let maskLayer = CAGradientLayer()
            maskLayer.frame = self.bounds
            maskLayer.colors = [
                NSColor.clear.cgColor,
                NSColor.black.cgColor,
                NSColor.black.cgColor,
                NSColor.clear.cgColor
            ]
            maskLayer.locations = [0.0, 0.33, 0.66, 1.0]
            maskLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
            maskLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
            return maskLayer
        }()
        self.sizeCache.removeAll()
//        if !self.initializePosition {
//            self.initializePosition = true
//            self.scrollToItem(at: self.selectedIndex, animated: false)
//        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var initializePosition = false

    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if !self.initializePosition {
            self.initializePosition = true
            self.scrollToItem(at: self.selectedIndex, animated: false)
        }
    }

    func reload() {
        self.sizeCache.removeAll()
        var snapshot = NSDiffableDataSourceSnapshot<Int, Value>()
        snapshot.appendSections([0])
        snapshot.appendItems(self.values, toSection: 0)

        self.diffDataSource.apply(snapshot, animatingDifferences: false) {
            self.scrollToItem(at: self.selectedIndex, animated: false)
        }
        self.updateAccessibility()
    }

    private var cvLayout: Layout<Center, Value>? {
        self.collectionView.collectionViewLayout as? Layout<Center, Value>
    }

    private weak var collectionView: NSCollectionView!

    func offsetForItem(at index: Int) -> CGFloat {
        var offset = self.cvLayout?.originalAttributesForItem(at: IndexPath(item: index, section: 0))?.frame.midY ?? 0
        offset -= self.bounds.height / 2
        return offset
    }

    func select(value: Value) {
        if !((self.collectionView.enclosingScrollView as? ScrollView)?.isScrolling ?? false) {
            if let index = self.values.firstIndex(of: value) {
                if index != self.selectedIndex {
                    self.scrollToItem(at: index)
                }
            } else if let index = self.values.lastIndex(where: { $0 < value }),
                      self.overriddenSelected != value {
                self.overriddenSelected = value
                self.scrollToItem(at: index)
            }
        }
    }

    func scrollToItem(at index: Int, animated: Bool = true) {
        guard self.values.indices.contains(index) else {
            return
        }
        let point = CGPoint(x: self.collectionView.contentOffset.x,
                            y: self.offsetForItem(at: index))

        print("Scroll", index, point, animated)

        if animated  {
            NSAnimationContext.current.allowsImplicitAnimation = true
            self.collectionView.animator().scroll(point)
        } else {
            self.collectionView.scroll(point)
        }
        self.selectedIndex = index
    }

    func didScroll(end: Bool) {
        let mid = CGRect(x: self.collectionView.contentOffset.x + self.bounds.width / 2,
                         y: self.collectionView.contentOffset.y + self.bounds.height / 2,
                         width: 1,
                         height: 1)
        let cells = self.collectionView.visibleItems().filter { cell in
            cell.view.frame.intersects(mid)
        }
        .compactMap(self.collectionView.indexPath(for:))
        .sorted()

        if let index = cells.first?.item {
            self.selectedIndex = index
            if end {
                self.scrollToItem(at: index, animated: true)
            }
        }
    }

    func scrollViewDidEndScrolling(_ scrollView: NSScrollView) {
        self.didScroll(end: true)
    }

    func scrollViewDidScroll(_ scrollView: NSScrollView) {
        self.didScroll(end: false)
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else {
            return
        }
        guard self.selectedIndex != indexPath.item else {
            return
        }


        if indexPath.item > self.selectedIndex {
            self.scrollToItem(at: indexPath.item - self.centerSize + 1)
        } else {
            self.scrollToItem(at: indexPath.item)
        }
    }

    func collectionView(_ collectionView: NSCollectionView,
                        layout collectionViewLayout: NSCollectionViewLayout,
                        insetForSectionAt section: Int) -> NSEdgeInsets {
        let number = collectionView.numberOfItems(inSection: section)
        let firstIndexPath = IndexPath(item: 0, section: section)
        let firstSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: firstIndexPath)
        let lastIndexPath = IndexPath(item: number - 1, section: section)
        let lastSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: lastIndexPath)
        return NSEdgeInsets(top: (self.bounds.size.height - firstSize.height / 2) / 2, left: 0,
                            bottom: (self.bounds.size.height - lastSize.height / 2) / 2, right: 0)
    }

    private var sizeCache: [AnyHashable: CGSize] = [:]

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let value = self.diffDataSource.itemIdentifier(for: indexPath) else {
            return .zero
        }
        let cacheId: AnyHashable = (value as? SizeIdentifiable)?.sizeIdentifier ?? AnyHashable(value)
        if let cached = sizeCache[cacheId] {
            return cached
        } else {
            self.configureCell(self.sizingCell, value)
            let size = self.sizingCell.view.fittingSize

            let new = CGSize(width: self.bounds.width - 40, height: size.height)
            self.sizeCache[cacheId] = new
            return new
        }
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}
#endif
