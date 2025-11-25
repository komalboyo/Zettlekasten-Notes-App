//
//  NotesListCell.swift
//  NotesApp
//
//  Created by Jana's MacBook Pro on 6/11/24.
//

import UIKit

class NotesListCell: UITableViewCell {

    static let identifier = "NotesListCell"
    
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak private var titleLbl: UILabel!
    @IBOutlet weak private var descriptionLbl: UILabel!
    @IBOutlet weak private var timeLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupCell(note: Note) {
        titleLbl.text = note.title
        descriptionLbl.text = note.desc
        
        // 1. Get the AI Mood
        let moodEmoji = SentimentAnalyzer.shared.getSentimentEmoji(for: note.text)
        
        // 2. Combine with Time
        // Result looks like: "🔥 10:30 AM"
        timeLbl.text = "\(moodEmoji) \(note.time)"
        
        // Tag Logic (Existing)
        if let noteTags = note.tags, !noteTags.isEmpty {
            let cleanTags = noteTags.replacingOccurrences(of: "#", with: "")
            tagsLabel.text = "#" + cleanTags.replacingOccurrences(of: " ", with: " #")
            tagsLabel.isHidden = false
        } else {
            tagsLabel.text = ""
            tagsLabel.isHidden = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
