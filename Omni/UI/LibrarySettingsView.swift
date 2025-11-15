import SwiftUI

struct LibrarySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var libraryManager = LibraryManager.shared
    
    @Binding var noteContent: String
    @Binding var isShowingNotebook: Bool
    
    @State private var showingNewProjectSheet = false
    @State private var newProjectName = ""
    @State private var selectedProject: Project?
    @State private var showingRenameAlert = false
    @State private var renameText = ""
    
    @State private var generatedQuiz: Quiz?
    @State private var isShowingQuiz = false
    @State private var isGenerating: Bool = false
    @State private var generationStatus: String = "Generating..."

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Header card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Library Projects")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Organize files for AI context")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "777777"))
                        }
                        
                        Spacer()
                        
                        Button(action: { showingNewProjectSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("New Project")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(Color(hex: "222222"))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "2A2A2A"), lineWidth: 1)
                    )
                    
                    // Projects List
                    if libraryManager.projects.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "FF6B6B"))
                            
                            VStack(spacing: 6) {
                                Text("No projects yet")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "EAEAEA"))
                                Text("Create a project to organize your files")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "888888"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color(hex: "222222"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "2A2A2A"), lineWidth: 1)
                        )
                    } else {
                        VStack(spacing: 10) {
                            ForEach(libraryManager.projects) { project in
                                ProjectRow(
                                    project: project,
                                    onToggle: {
                                        libraryManager.toggleProjectActive(project)
                                    },
                                    onRename: {
                                        selectedProject = project
                                        renameText = project.name
                                        showingRenameAlert = true
                                    },
                                    onDelete: {
                                        libraryManager.deleteProject(project)
                                    },
                                    onAddFiles: {
                                        selectFiles(for: project)
                                    },
                                    onRemoveFile: { file in
                                        libraryManager.removeFile(file, from: project)
                                    },
                                    onGenerateQuiz: {
                                        Task { await handleGenerateQuiz(for: project) }
                                    },
                                    onGenerateTimeline: {
                                        Task { await handleGenerateTimeline(for: project) }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(24)
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet(
                    projectName: $newProjectName,
                    onCreate: {
                        libraryManager.createProject(name: newProjectName)
                        newProjectName = ""
                        showingNewProjectSheet = false
                    },
                    onCancel: {
                        newProjectName = ""
                        showingNewProjectSheet = false
                    }
                )
            }
            .alert("Rename Project", isPresented: $showingRenameAlert) {
                TextField("Project Name", text: $renameText)
                Button("Cancel", role: .cancel) {
                    selectedProject = nil
                    renameText = ""
                }
                Button("Rename") {
                    if let project = selectedProject, !renameText.isEmpty {
                        libraryManager.renameProject(project, newName: renameText)
                    }
                    selectedProject = nil
                    renameText = ""
                }
            }
            .sheet(item: $generatedQuiz) { quiz in
                QuizView(quiz: quiz)
            }
            
            if isGenerating {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(generationStatus)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "AAAAAA"))
                }
                .padding(30)
                .background(Color(hex: "1A1A1A").opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 10)
                .transition(.opacity.animation(.easeInOut))
            }
        }
        .animation(.easeInOut, value: isGenerating)
    }
    
    private func selectFiles(for project: Project) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Files"
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.text, .plainText, .pdf, .data]
        
        guard let window = NSApp.keyWindow else { return }
        
        openPanel.beginSheetModal(for: window) { response in
            if response == .OK {
                for url in openPanel.urls {
                    libraryManager.addFile(to: project, url: url)
                }
            }
        }
    }
    
    private func handleGenerateQuiz(for project: Project) async {
        isGenerating = true
        generationStatus = "Generating quiz..."
        do {
            let quiz = try await LLMManager.shared.generateExam(from: project, modelContext: modelContext)
            self.generatedQuiz = quiz
        } catch {
            print("Error generating quiz: \(error)")
        }
        isGenerating = false
    }
    
    private func handleGenerateTimeline(for project: Project) async {
        isGenerating = true
        generationStatus = "Generating timeline..."
        do {
            let timelineMarkdown = try await LLMManager.shared.generateTimeline(from: project)
            self.noteContent = timelineMarkdown
            self.isShowingNotebook = true
        } catch {
            print("Error generating timeline: \(error)")
        }
        isGenerating = false
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: Project
    let onToggle: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onAddFiles: () -> Void
    let onRemoveFile: (LibraryFile) -> Void
    let onGenerateQuiz: () -> Void
    let onGenerateTimeline: () -> Void
    
    @State private var isExpanded = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project Header
            HStack(spacing: 10) {
                Button(action: { withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "666666"))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 16)
                }
                .buttonStyle(.plain)
                
                Image(systemName: project.isActive ? "folder.fill" : "folder")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(project.isActive ? Color(hex: "FF6B6B") : Color(hex: "777777"))
                
                Text(project.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "EAEAEA"))
                
                if project.isActive {
                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FF6B6B").opacity(0.15))
                        .cornerRadius(3)
                }
                
                Text("\(project.files.count)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "666666"))
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 6) {
                    Button(action: onAddFiles) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "777777"))
                    }
                    .buttonStyle(.plain)
                    .help("Add files")
                    
                    Button(action: onRename) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "777777"))
                    }
                    .buttonStyle(.plain)
                    .help("Rename")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "777777"))
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
            }
            .padding(12)
            .background(
                project.isActive
                    ? Color(hex: "FF6B6B").opacity(0.08)
                    : Color(hex: "252525")
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        project.isActive
                            ? Color(hex: "FF6B6B").opacity(0.3)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
            .contextMenu {
                Button(action: onAddFiles) {
                    Label("Add Files...", systemImage: "plus")
                }
                
                Divider()
                
                Button(action: onGenerateQuiz) {
                    Label("Generate Practice Exam", systemImage: "questionmark.diamond")
                }
                .disabled(project.files.isEmpty)
                
                Button(action: onGenerateTimeline) {
                    Label("Generate Project Timeline", systemImage: "calendar.day.timeline.leading")
                }
                .disabled(project.files.isEmpty)
                
                Divider()
                
                Button(action: onRename) {
                    Label("Rename Project", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Project", systemImage: "trash")
                }
            }
            
            // Files List (when expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if project.files.isEmpty {
                        Text("No files yet. Click + to add files.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "666666"))
                            .padding(.leading, 36)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(project.files) { file in
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "FF6B6B"))
                                
                                Text(file.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: { onRemoveFile(file) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color(hex: "666666"))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "222222"))
                            .cornerRadius(5)
                        }
                    }
                }
                .padding(.leading, 36)
                .padding(.trailing, 12)
                .padding(.top, 6)
                .padding(.bottom, 8)
            }
        }
        .animation(.easeOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - New Project Sheet
struct NewProjectSheet: View {
    @Binding var projectName: String
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("New Project")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            
                Text("Create a project to organize files")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "888888"))
            }
            
            TextField("Project Name", text: $projectName)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(10)
                .background(Color(hex: "252525"))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex:"2A2A2A"), lineWidth: 1)
                )
                .frame(width: 300)
            
            HStack(spacing: 10) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "252525"))
                .foregroundColor(Color(hex: "EAEAEA"))
                .cornerRadius(6)
                .buttonStyle(.plain)
                
                Button("Create") {
                    onCreate()
                }
                .keyboardShortcut(.return)
                .disabled(projectName.isEmpty)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if projectName.isEmpty {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "333333"))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                )
                .foregroundColor(.white)
                .buttonStyle(.plain)
                .opacity(projectName.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(30)
        .frame(width: 400)
        .background(Color(hex: "1A1A1A"))
    }
}
