import UIKit

class EditNoteVC: UIViewController {

    static let identifier = "EditNoteVC"
    var note: Note!
    weak var delegate: NotesListDelegate?

    // MARK: - Outlets
    @IBOutlet weak var titleTextField: UITextField! // Make sure this is connected!
    @IBOutlet weak private var textView: UITextView!
    @IBOutlet weak var tagsTextField: UITextField!
    
    // Dropdown Table
    @IBOutlet weak var suggestionsTableView: UITableView! // Make sure this is connected!

    // Variables for Dropdown
    var allExistingTags: [String] = []
    var filteredTags: [String] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Setup Inputs
        tagsTextField.delegate = self
        setupSuggestions()
        
        // 2. Load and Split Data (Title vs Body)
        if let fullText = note?.text {
            // Split the text by lines
            let components = fullText.components(separatedBy: "\n")
            
            // First line is Title
            titleTextField.text = components.first
            
            // Rest of the lines are Body
            if components.count > 1 {
                textView.text = components.dropFirst().joined(separator: "\n")
            } else {
                textView.text = ""
            }
        }
        
        // Load Tags
        tagsTextField.text = note?.tags
    }
    
    @IBAction func autoTagButtonTapped(_ sender: Any) {
        print("DEBUG: Button was tapped!") // If you don't see this, the button is disconnected.
            
            // 1. Get Text
            let title = titleTextField.text ?? ""
            let body = textView.text ?? ""
            let fullText = "\(title) \(body)"
            
            print("DEBUG: Analyzing text: '\(fullText)'")
            
            // 2. Check Logic
            if fullText.trimmingCharacters(in: .whitespaces).isEmpty {
                print("DEBUG: Text is empty, stopping.")
                return
            }
            
            // 3. Generate
            let suggestedTags = SmartTagger.shared.generateTags(from: fullText)
            print("DEBUG: SmartTagger found: \(suggestedTags)")
            
            if suggestedTags.isEmpty {
                print("DEBUG: No keywords found. Try typing 'Apple' or 'Meeting'.")
            }
            
            // 4. Update UI
            let currentText = tagsTextField.text ?? ""
            var newTagsString = currentText.trimmingCharacters(in: .whitespaces)
            
            for tag in suggestedTags {
                if !newTagsString.lowercased().contains(tag.lowercased()) {
                    newTagsString += " #\(tag)"
                }
            }
            
            tagsTextField.text = newTagsString
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 1. COMBINE Title and Body into one string
        let title = titleTextField.text ?? ""
        let body = textView.text ?? ""
        
        // Format: "Title \n Body"
        if !title.isEmpty {
            note.text = title + "\n" + body
        } else {
            note.text = body
        }
        
        // 2. Capture Tags
        note.tags = tagsTextField.text
        
        // 3. Check if we should Save or Delete
        // We only delete if EVERYTHING is empty.
        let titleIsEmpty = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyIsEmpty = body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let tagsAreEmpty = (note.tags ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if titleIsEmpty && bodyIsEmpty && tagsAreEmpty {
            print("DEBUG: Note is empty. Deleting.")
            deleteNote()
        } else {
            print("DEBUG: Saving Note. Title: \(title)")
            updateNote()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Optional: Auto-focus the body or title if you want
        // textView.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - Actions
    @IBAction func saveButtonTapped(_ sender: Any) {
        // Dismiss keyboard to trigger any final text updates
        view.endEditing(true)
        // Pop back (This triggers viewWillDisappear, which handles the saving)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Data Helpers
    private func updateNote() {
        note.lastUpdated = Date()
        CoreDataManager.shared.save()
        delegate?.refreshNotes()
    }
    
    private func deleteNote() {
        delegate?.deleteNote(with: note.id)
        CoreDataManager.shared.deleteNote(note)
    }
    
    // MARK: - Tag Dropdown Logic
    func setupSuggestions() {
        allExistingTags = CoreDataManager.shared.getAllUniqueTags()
        
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        
        suggestionsTableView.isHidden = true
        suggestionsTableView.layer.cornerRadius = 8
        suggestionsTableView.layer.borderWidth = 1
        suggestionsTableView.layer.borderColor = UIColor.systemGray4.cgColor
        
        tagsTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc func textFieldDidChange() {
        guard let text = tagsTextField.text, !text.isEmpty else {
            suggestionsTableView.isHidden = true
            return
        }
        
        let components = text.components(separatedBy: " ")
        guard let lastWord = components.last, !lastWord.isEmpty else {
            suggestionsTableView.isHidden = true
            return
        }
        
        let searchString = lastWord.replacingOccurrences(of: "#", with: "")
        filteredTags = allExistingTags.filter { $0.lowercased().contains(searchString.lowercased()) }
        
        suggestionsTableView.isHidden = filteredTags.isEmpty
        suggestionsTableView.reloadData()
    }
}

// MARK: - TableView (Dropdown)
extension EditNoteVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        cell.textLabel?.text = "#" + filteredTags[indexPath.row]
        cell.backgroundColor = .secondarySystemGroupedBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTag = filteredTags[indexPath.row]
        if let currentText = tagsTextField.text {
            var components = currentText.components(separatedBy: " ")
            components.removeLast()
            components.append("#" + selectedTag)
            tagsTextField.text = components.joined(separator: " ") + " "
        }
        suggestionsTableView.isHidden = true
        // We do NOT call updateNote here, wait for viewWillDisappear
    }
}

// MARK: - Delegates
// CRITICAL FIX: We removed the logic that overwrites note.text immediately.
extension EditNoteVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            textView.becomeFirstResponder() // Jump to body
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
