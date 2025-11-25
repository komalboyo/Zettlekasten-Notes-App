//
//  NotesListVC.swift
//  NotesApp
//
//  Created by Jana's MacBook Pro on 6/11/24.
//

import UIKit

protocol NotesListDelegate: AnyObject {
    func refreshNotes()
    func deleteNote(with id: UUID)
}

class NotesListVC: UIViewController {
    
    static let identifier = "NotesListVC"
    
    // MARK: - Outlets
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var notesCountLbl: UILabel!
    
    // NEW: The Outlet for the Tag Filter Bar

    @IBOutlet weak var tagsCollectionView: UICollectionView!
    
    // MARK: - Variables
    private var filteredNotes: [Note] = []
    private var searchController = UISearchController()
    
    // NEW: Variables for Tag Logic
    var allTags: [String] = []
    var selectedTag: String? = nil // nil means "All" is selected
    
    private var notes: [Note] = [] {
        didSet {
            let notesCount = "\(notes.count) \(notes.count == 1 ? "Note" : "Notes")"
            notesCountLbl.text = notesCount
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
        
        // NEW: Setup Collection View
        tagsCollectionView.delegate = self
        tagsCollectionView.dataSource = self
        
        // Initial Fetch
        fetchNotes()
        loadTags()
    }
    
    // NEW: Refresh data every time we return from Edit Screen
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Re-fetch all notes from Core Data to get latest changes
        fetchNotes()
        
        // 2. Re-fetch tags (in case a new one was added)
        loadTags()
        
        // 3. Re-apply the current filter (Tag + Search Text)
        search(searchController.searchBar.text ?? "")
        
        // 4. Reload the list
        tableView.reloadData()
    }
    
    private func setupUI() {
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.contentInset = .init(top: 0, left: 0, bottom: 30, right: 0)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    private func setupSearchBar() {
        navigationItem.searchController = searchController
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
    }
    
    private func loadTags() {
        // Fetch unique tags from Core Data Manager
        allTags = CoreDataManager.shared.getAllUniqueTags()
        tagsCollectionView.reloadData()
    }
    
    private func setNoteIndex(id: UUID, in list: [Note]) -> IndexPath {
        let row = Int(list.firstIndex(where: { $0.id == id }) ?? 0)
        return IndexPath(row: row, section: 0)
    }

    // MARK: - Actions
    @IBAction func createNoteTapped(_ sender: UIButton) {
        navigateToEdit(createNote())
    }
    
    private func navigateToEdit(_ note: Note) {
        let vc = storyboard?.instantiateViewController(identifier: EditNoteVC.identifier) as! EditNoteVC
        vc.note = note
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createNote() -> Note {
        let note = CoreDataManager.shared.createNote()
        // We add it to the array, but real filtering happens in viewWillAppear
        notes.insert(note, at: 0)
        return note
    }
    
    private func fetchNotes() {
        notes = CoreDataManager.shared.fetchNotes()
        // Default to showing all notes until filtered
        filteredNotes = notes
    }

    private func deleteNote(_ note: Note) {
        deleteNote(with: note.id)
        CoreDataManager.shared.deleteNote(note)
        // Refresh tags in case we deleted the last note with a specific tag
        loadTags()
    }
    
    private func searchNotes(_ text: String) {
        notes = CoreDataManager.shared.fetchNotes(text)
        search(text) // Use the main search logic
    }
}

// MARK: - Search Logic
extension NotesListVC: UISearchControllerDelegate, UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        search("")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchNotes(query)
    }
    
    func search(_ query: String) {
        var listToFilter = notes
        
        // 1. First, filter by the Selected Tag
        if let category = selectedTag {
            listToFilter = notes.filter { ($0.tags ?? "").contains(category) }
        }
        
        // 2. Then, filter by the Search Text
        if query.count >= 1 {
            filteredNotes = listToFilter.filter {
                let textMatch = $0.text?.lowercased().contains(query.lowercased()) ?? false
                let tagMatch = $0.tags?.lowercased().contains(query.lowercased()) ?? false
                return textMatch || tagMatch
            }
        } else {
            // If no text search, just show the tag-filtered list
            filteredNotes = listToFilter
        }
        
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource
extension NotesListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredNotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NotesListCell.identifier) as? NotesListCell else { return UITableViewCell ()}
        cell.setupCell(note: filteredNotes[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

// MARK: - TableView Delegate
extension NotesListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigateToEdit(filteredNotes[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteNote(filteredNotes[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - CollectionView (Tag Filter) Delegate & DataSource
extension NotesListVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // +1 because the first item is the "All" button
        return allTags.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagFilterCell", for: indexPath) as! TagFilterCell
        
        if indexPath.row == 0 {
            // The "All" Button
            cell.tagLabel.text = "All"
            cell.configure(selected: selectedTag == nil)
        } else {
            // Specific Tag Buttons
            let tag = allTags[indexPath.row - 1]
            cell.tagLabel.text = "#\(tag)"
            cell.configure(selected: selectedTag == tag)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            selectedTag = nil // User tapped "All"
        } else {
            selectedTag = allTags[indexPath.row - 1] // User tapped specific tag
        }
        
        // 1. Update the buttons (colors)
        collectionView.reloadData()
        
        // 2. Filter the Table View
        search(searchController.searchBar.text ?? "")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Fixed size for tags. You can make this dynamic later if you want.
        return CGSize(width: 100, height: 40)
    }
}

// MARK: - NotesList Delegate
extension NotesListVC: NotesListDelegate {
    func refreshNotes() {
        fetchNotes()
        loadTags()
        tableView.reloadData()
    }
    
    func deleteNote(with id: UUID) {
        let indexPath = setNoteIndex(id: id, in: filteredNotes)
        if indexPath.row < filteredNotes.count {
            filteredNotes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        // Also remove from master list
        let masterIndex = setNoteIndex(id: id, in: notes)
        if masterIndex.row < notes.count {
            notes.remove(at: masterIndex.row)
        }
        
        loadTags()
    }
}
