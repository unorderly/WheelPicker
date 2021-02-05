import UIKit

class CenterView<View: CollectionCenter>: UICollectionReusableView {

    weak var view: View?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
        let view = View()

        view.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(view)

        let constraints = [
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0),
        ]
        NSLayoutConstraint.activate(constraints)

        self.view = view
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func apply(_ attributes: UICollectionViewLayoutAttributes) {
        if let value = (attributes as? CenterAttributes<View.Value>)?.value {
            view?.set(value: value)
        }

        let size = view?.systemLayoutSizeFitting(CGSize(width: attributes.frame.width, height: 0)) ?? .zero
        self.frame = CGRect(x: attributes.frame.midX - size.width / 2,
                            y: attributes.frame.midY - size.height / 2,
                            width: size.width,
                            height: size.height)
    }
}

class CenterAttributes<Value: Hashable>: UICollectionViewLayoutAttributes {
    var value: Value?
}

class Layout<Center: CollectionCenter>: UICollectionViewFlowLayout {

    private let maxAngle : CGFloat = CGFloat.pi / 2

    private var _halfDim : CGFloat {
            return _visibleRect.height / 2
    }

    private var _mid : CGFloat {
            return _visibleRect.midY
    }

    private var _visibleRect : CGRect {
        if let cv = collectionView {
            return CGRect(origin: cv.contentOffset, size: cv.bounds.size)
        }
        return CGRect.zero
    }

    var selected: Center.Value {
        didSet {
            self.invalidateLayout()
        }
    }

    init(selected: Center.Value) {
        self.selected = selected
        super.init()

        sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        minimumLineSpacing = 0.0
        self.register(CenterView<Center>.self, forDecorationViewOfKind: "center")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == "center" && indexPath == IndexPath(item: 0, section: 0) {
            let attributes = CenterAttributes<Center.Value>(forDecorationViewOfKind: elementKind, with: indexPath)
            attributes.value = selected
            attributes.frame = CGRect(x: 0, y: _mid, width: _visibleRect.width, height: 0)
            attributes.zIndex = 2
            return attributes
        }
        return nil
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes {
            if attributes.frame.midY > _mid {
                attributes.frame.origin.y -= min(attributes.frame.midY - _mid, attributes.frame.height)
            }
            let distance = _mid - attributes.frame.midY
            let currentAngle = maxAngle * distance / _halfDim / (CGFloat.pi / 2)
            var transform = CATransform3DIdentity

            transform = CATransform3DTranslate(transform, 0, distance, -_halfDim - 20)
            transform = CATransform3DRotate(transform, currentAngle, 1, 0, 0)
            transform = CATransform3DTranslate(transform, 0, 0, _halfDim)

            attributes.transform3D = transform
            attributes.isHidden = abs(currentAngle) > maxAngle
            attributes.zIndex = 1
            return attributes
        }

        return nil
    }

    public func originalAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return super.layoutAttributesForItem(at: indexPath)
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = [UICollectionViewLayoutAttributes]()
        if self.collectionView!.numberOfSections > 0 {
            for i in 0 ..< self.collectionView!.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(item: i, section: 0)
                attributes.append(self.layoutAttributesForItem(at: indexPath)!)
            }
        }

        if let deco = self.layoutAttributesForDecorationView(ofKind: "center", at: IndexPath(row: 0, section: 0)) {
            attributes.append(deco)
        }

        return attributes
    }
}
