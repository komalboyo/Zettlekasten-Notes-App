import UIKit

class TagFilterCell: UICollectionViewCell {
    
    // Make sure this matches the name used in NotesListVC
    @IBOutlet weak var tagLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10
        self.backgroundColor = .systemGray5
    }
    
    func configure(selected: Bool) {
        self.backgroundColor = selected ? .systemBlue : .systemGray5
        tagLabel.textColor = selected ? .white : .label
    }
}
