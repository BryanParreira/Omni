import Foundation
import SwiftUI

// MARK: - Models
struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isActive: Bool
    var files: [LibraryFile]
    var createdAt: Date
    
    // --- 1. ADD THIS NEW PROPERTY ---
    var systemPrompt: String

    init(id: UUID = UUID(), name: String, isActive: Bool = false, files: [LibraryFile] = [], systemPrompt: String = "") { // Add to init
        self.id = id
        self.name = name
        self.isActive = isActive
        self.files = files
        self.createdAt = Date()
        self.systemPrompt = systemPrompt // Add to init
    }
    
    // --- 2. UPDATE CODABLE CONFORMANCE ---
    enum CodingKeys: String, CodingKey {
        case id, name, isActive, files, createdAt, systemPrompt // Add new key
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        files = try container.decode([LibraryFile].self, forKey: .files)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        // This safely decodes the new prompt, defaulting to "" if it's missing (for old data)
        systemPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(files, forKey: .files)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(systemPrompt, forKey: .systemPrompt) // Add new key
    }
    // --- END OF CODABLE UPDATES ---
}

struct LibraryFile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: URL
    var content: String
    var addedAt: Date
    
    init(id: UUID = UUID(), name: String, url: URL, content: String) {
        self.id = id
        self.name = name
        self.url = url
        self.content = content
        self.addedAt = Date()
    }
}

// MARK: - Library Manager
@MainActor
class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    
    @Published var projects: [Project] = []
    
    private let projectsKey = "com.omni.library.projects"
    private let fileManager = FileManager.default
    
    init() {
        loadProjects()
    }
    
    // MARK: - Chat-Specific Helpers
    
    /// Finds and returns a project by its unique ID.
    func getProject(by id: UUID) -> Project? {
        return projects.first(where: { $0.id == id })
    }
    
    /// Generates the full-text context for a *specific* project.
    func getContext(for project: Project) -> String {
        let files = project.files
        guard !files.isEmpty else { return "" }
        
        var context = "# Reference Library Context: \(project.name)\n(This chat is using \(project.files.count) file(s) as a source of truth.)\n\n---\n\n"
        
        for file in files {
            context += "## File: \(file.name)\n\n"
            context += "\(file.content)\n\n"
            context += "---\n\n"
        }
        return context
    }
    
    // MARK: - Project Management
    
    func createProject(name: String) {
        let newProject = Project(name: name)
        projects.append(newProject)
        saveProjects()
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveProjects()
    }
    
    func renameProject(_ project: Project, newName: String) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].name = newName
            saveProjects()
        }
    }
    
    // This logic is now "legacy" but we leave it so the Settings view doesn't break
    func setActiveProject(_ project: Project) {
        for index in projects.indices {
            projects[index].isActive = false
        }
        
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isActive = true
            saveProjects()
        }
    }
    
    // This logic is now "legacy" but we leave it so the Settings view doesn't break
    func toggleProjectActive(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            if projects[index].isActive {
                projects[index].isActive = false
            } else {
                for i in projects.indices {
                    projects[i].isActive = false
                }
                projects[index].isActive = true
            }
            saveProjects()
        }
    }
    
    // This logic is now "legacy"
    var activeProject: Project? {
        projects.first { $0.isActive }
    }
    
    // MARK: - File Management
    func addFile(to project: Project, url: URL) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        
        guard url.startAccessingSecurityScopedResource() else {
            print("Couldn't access security scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let newFile = LibraryFile(name: url.lastPathComponent, url: url, content: content)
            
            if !projects[index].files.contains(where: { $0.url == url }) {
                projects[index].files.append(newFile)
                saveProjects()
            }
        } catch {
            print("Error reading file: \(error.localizedDescription)")
        }
    }
    
    func removeFile(_ file: LibraryFile, from project: Project) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[projectIndex].files.removeAll { $0.id == file.id }
        saveProjects()
    }
    
    // This logic is now "legacy"
    func getActiveProjectFiles() -> [LibraryFile] {
        guard let active = activeProject else { return [] }
        return active.files
    }
    
    // This logic is now "legacy"
    func getActiveProjectContext() -> String {
        let files = getActiveProjectFiles()
        guard !files.isEmpty else { return "" }
        
        var context = "# Reference Library Context\n\n"
        for file in files {
            context += "## File: \(file.name)\n\n"
            context += "\(file.content)\n\n"
            context += "---\n\n"
        }
        return context
    }
    
    // MARK: - Persistence
    // --- 3. RENAMED saveProjects() TO BE PUBLIC ---
    // We need to call this from the TextEditor in LibrarySettingsView
    func saveProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            UserDefaults.standard.set(data, forKey: projectsKey)
        } catch {
            print("Error saving projects: \(error.localizedDescription)")
        }
    }
    
    private func loadProjects() {
        guard let data = UserDefaults.standard.data(forKey: projectsKey) else {
            projects = [Project(name: "Default Project", isActive: false)]
            saveProjects()
            return
        }
        
        do {
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            print("Error loading projects: \(error.localizedDescription)")
            projects = [Project(name: "Default Project", isActive: false)]
        }
    }
}
