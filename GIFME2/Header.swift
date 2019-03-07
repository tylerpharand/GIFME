import UIKit

class Header: UICollectionViewCell  {
    
    override init(frame: CGRect)    {
        super.init(frame: frame)

        setupHeaderViews()
    }
    
    var headerIcon : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "header_icon")
        imageView.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let dateLabel: UILabel = {
        let title = UILabel()
        title.text = "My Stickers"
        title.textColor = UIColor(red: 54/255.0, green: 49/255.0, blue: 77/255.0, alpha: 1)
        title.font = UIFont(name: "AvenirNext-Bold", size: 31)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    func setupHeaderViews()   {
        addSubview(dateLabel)
        addSubview(headerIcon)
        
        headerIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        headerIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        headerIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        headerIcon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        
        dateLabel.leftAnchor.constraint(equalTo: headerIcon.rightAnchor, constant: 20).isActive = true
        dateLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
