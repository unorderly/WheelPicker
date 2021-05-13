#if canImport(UIKit)
import UIKit

private class CenterView<View: UIView>: UICollectionReusableView {
    weak var view: View?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let view = View()

        view.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(view)

        let constraints = [
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0)
        ]
        NSLayoutConstraint.activate(constraints)

        self.view = view
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func apply(_ attributes: UICollectionViewLayoutAttributes) {
        guard let view = self.view else {
            return
        }

        (attributes as? CenterAttributes<View>)?.configure(view)

        let size = view.systemLayoutSizeFitting(CGSize(width: attributes.frame.width, height: 0))
        self.frame = CGRect(x: attributes.frame.minX,
                            y: attributes.frame.midY - size.height / 2,
                            width: attributes.frame.width,
                            height: size.height)
    }
}

private final class CenterAttributes<View: UIView>: UICollectionViewLayoutAttributes {
    var configure: (View) -> Void = { _ in }
    var selected: AnyHashable?

    convenience init(selected: AnyHashable, indexPath: IndexPath) {
        self.init(forDecorationViewOfKind: "center", with: indexPath)
        self.selected = selected
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = (object as? CenterAttributes<View>), self.selected == other.selected else {
            return false
        }
        return super.isEqual(object)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        (copy as? CenterAttributes<View>)?.selected = self.selected
        (copy as? CenterAttributes<View>)?.configure = self.configure
        return copy
    }
}

struct HashableTuple: Hashable {
    let a: AnyHashable
    let b: AnyHashable

    init(_ a: AnyHashable, _ b: AnyHashable) {
        self.a = a
        self.b = b
    }

    init(_ a: AnyHashable, _ b: AnyHashable, _ c: AnyHashable) {
        self.a = a
        self.b = HashableTuple(b, c)
    }
}

class Layout<Center: UIView, Value: Hashable>: UICollectionViewFlowLayout {
    private let maxAngle = CGFloat.pi / 2

    private var _halfDim: CGFloat {
        self._visibleRect.height / 2
    }

    private var _mid: CGFloat {
        self._visibleRect.midY
    }

    private var _visibleRect: CGRect {
        if let cv = collectionView {
            return CGRect(origin: cv.contentOffset, size: cv.bounds.size)
        }
        return CGRect.zero
    }

    var selected: Value {
        didSet {
            if oldValue != self.selected {
                self.invalidateLayout()
            }
        }
    }

    var centerSize: Int = 1 {
        didSet {
            if self.centerSize != oldValue {
                self.invalidateLayout()
            }
        }
    }

    var configureCenter: (Center, Value) -> Void

    init(selected: Value,
         configureCenter: @escaping (Center, Value) -> Void) {
        self.selected = selected
        self.configureCenter = configureCenter
        super.init()

        sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        minimumLineSpacing = 0.0
        self.register(CenterView<Center>.self, forDecorationViewOfKind: "center")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                    at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == "center", indexPath == IndexPath(item: 0, section: 0) {
            let attributes = CenterAttributes<Center>(selected: HashableTuple(selected, centerSize, _visibleRect.width),
                                                      indexPath: indexPath)
            attributes.configure = { [unowned self] view in self.configureCenter(view, self.selected) }
            attributes.frame = CGRect(x: 0, y: self._mid, width: self._visibleRect.width, height: 0)
            attributes.zIndex = 2
            return attributes
        }
        return nil
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes {
            self.adjust(attributes: attributes)
            return attributes
        }

        return nil
    }

    private func adjust(attributes: UICollectionViewLayoutAttributes) {
        if attributes.frame.midY > self._mid {
            attributes.frame.origin.y -= min(attributes.frame.midY - self._mid,
                                             attributes.frame.height * CGFloat(self.centerSize - 1))
        }
        let distance = self._mid - attributes.frame.midY
        let currentAngle = self.maxAngle * distance / self._halfDim / (CGFloat.pi / 2)
        var transform = CATransform3DIdentity

        transform = CATransform3DTranslate(transform, 0, distance, -self._halfDim - 20)
        transform = CATransform3DRotate(transform, currentAngle, 1, 0, 0)
        transform = CATransform3DTranslate(transform, 0, 0, self._halfDim)

        attributes.transform3D = transform
        attributes.isHidden = abs(currentAngle) > self.maxAngle
        attributes.zIndex = 1
    }

    public func originalAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForItem(at: indexPath)
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []
        if self.collectionView!.numberOfSections > 0 {
            for i in 0 ..< self.collectionView!.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(item: i, section: 0)
                let attr = self.layoutAttributesForItem(at: indexPath)!
                if attr.frame.intersects(rect), !attr.isHidden {
                    attributes.append(attr)
                }
            }

            if self.collectionView!.numberOfItems(inSection: 0) > 0,
               let deco = self.layoutAttributesForDecorationView(ofKind: "center", at: IndexPath(row: 0, section: 0)) {
                attributes.append(deco)
            }
        }

        return attributes
    }
}
#endif
