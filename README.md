SmartNotes 🧠

A Native iOS Zettelkasten System with On-Device Intelligence.

SmartNotes is a knowledge management application designed to implement the Zettelkasten method. Unlike traditional note-taking apps that force linear folder structures, SmartNotes utilizes atomic notes, fluid tagging, and on-device AI to create a connected "Second Brain."

Built entirely with Swift and UIKit, it leverages Core Data for robust local persistence and Core ML (NaturalLanguage) for offline sentiment analysis and entity recognition.

🚀 Features

🧠 AI-Powered Intelligence (Core ML)

Sentiment Analysis: Analyzes the emotional tone of your notes in real-time.

🔥 Positive: Success, excitement, motivation.

🌧️ Negative: Errors, problems, blockers.

🧠 Neutral: Factual data, meeting notes.

Smart Auto-Tagging: Uses Named Entity Recognition (NER) to scan text for People, Places, and Organizations (e.g., "Apple", "London", "Steve Jobs") and automatically generates relevant hashtags.

📝 Seamless Editing Experience

Split-Input Interface: Visual separation of Title (Bold) and Body (Regular) that saves efficiently to a single database field.

Intelligent Auto-Save: Never lose data. The app saves automatically on exit (viewWillDisappear) and cleans up empty notes to prevent database clutter.

Tag Autocomplete: An integrated dropdown suggests existing tags while you type to prevent duplicates (e.g., preventing #work vs #Work).

🔍 Discovery & Organization

Tag Cloud Filter: Instant horizontal filtering of the main note list by tag.

Hybrid Search: Custom logic that filters results by matching both text content and tags simultaneously.

Serendipity Engine: A "Random Review" screen that resurfaces forgotten notes to spark new connections between ideas.

Insights Dashboard: Tracks your progress with statistics on Total Notes and Top Tags.

🛠 Tech Stack

Language: Swift 5

UI Framework: UIKit (Storyboards & Auto Layout)

Architecture: MVC (Model-View-Controller)

Persistence: Core Data

AI/ML: NaturalLanguage Framework (On-Device)

Minimum Target: iOS 16.0

🏗 Architecture & Data Model

The app follows a strict MVC pattern to ensure separation of concerns.

Core Data Model (Note Entity)

Instead of complex relationships, the app uses a streamlined schema for performance:

id (UUID): Unique identifier.

text (String): Stores the full content. The app logic splits the first line as Title and the rest as Body during runtime.

tags (String): Space-separated string of hashtags.

lastUpdated (Date): For sorting.

Smart Logic

SentimentAnalyzer: A singleton service that wraps the NLTagger to score text from -1.0 to 1.0 and map it to specific emojis. Includes fallback logic for Simulator environments.

SmartTagger: Uses NLTagger schemes .nameType and .lexicalClass to extract keywords and entities for auto-tagging.

📸 Screenshots

Main List & Sentiment

Smart Editing & Auto-Tag

Tag Filtering

(Place Screenshot Here)

(Place Screenshot Here)

(Place Screenshot Here)

🔧 Installation

Clone the repository:

git clone [https://github.com/yourusername/SmartNotes.git](https://github.com/yourusername/SmartNotes.git)



Open NotesApp.xcodeproj in Xcode 14+.

Wait for Swift Package dependencies (if any) to resolve.

Build and Run (Cmd + R) on the iPhone 14 Pro Simulator.

Note on Simulator Testing:
The NaturalLanguage framework behaves differently on the iOS Simulator compared to a physical device. A "Simulator Polyfill" has been implemented in SentimentAnalyzer.swift to ensure features work for demonstration purposes even without the full Neural Engine hardware.

🔮 Future Roadmap

$$$$

 iCloud Sync: Migrate Core Data to CloudKit for multi-device support.

$$$$

 Graph View: Visual node-link diagram to explore connections.

$$$$

 Rich Text (Markdown): Support for bold, italics, and code blocks within the body text.

$$$$

 Share Extension: Create notes directly from Safari.

👤 Author

$$Your Name$$

GitHub: @yourusername

LinkedIn: 

$$Your Profile$$

License: MIT
