import SwiftUI
import UniformTypeIdentifiers

// MARK: - Kanban Task Model

struct KanbanTask: Identifiable, Codable, Equatable, Transferable {
    let id: String
    let title: String
    let description: String?
    let tagLabel: String
    let tagAccentName: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }

    var accent: FabricAccent {
        switch tagAccentName {
        case "indigo": return .indigo
        case "madder": return .madder
        case "sage":   return .sage
        case "ochre":  return .ochre
        default:       return .indigo
        }
    }

    var fabricTags: [FabricTaskCard.Tag] {
        [.init(tagLabel, accent: accent, id: "\(id)-\(tagLabel)")]
    }

    init(
        _ title: String,
        description: String? = nil,
        tag: String,
        accent: String
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.tagLabel = tag
        self.tagAccentName = accent
    }
}

// MARK: - ShowcaseView

struct ShowcaseView: View {

    @State private var nameField = ""
    @State private var emailField = ""
    @State private var notesField = ""
    @State private var toggleNotifications = true
    @State private var toggleAutoSave = false
    @State private var toggleDarkMode = true
    @State private var currentStep: Int = 0
    @State private var progressValue: Double = 0.65
    @State private var ringValue: Double = 0.40
    @State private var errorBannerExpanded = false
    @State private var sliderValue: Double = 0.35
    @State private var volumeValue: Double = 0.65
    @State private var brightnessValue: Double = 0.50

    // Kanban state
    @State private var todoTasks: [KanbanTask] = [
        KanbanTask("Design navigation", tag: "Design", accent: "indigo"),
        KanbanTask("API endpoints", tag: "Dev", accent: "sage"),
        KanbanTask("Write tests", tag: "Dev", accent: "sage"),
    ]
    @State private var inProgressTasks: [KanbanTask] = [
        KanbanTask("Color system", tag: "Design", accent: "indigo"),
        KanbanTask("Database schema", description: "Finalize table structure", tag: "Dev", accent: "sage"),
    ]
    @State private var doneTasks: [KanbanTask] = [
        KanbanTask("Project brief", tag: "Planning", accent: "ochre"),
    ]
    @State private var todoTargeted = false
    @State private var inProgressTargeted = false
    @State private var doneTargeted = false
    /// Tracks which card is the active drop target by identity (not index).
    /// Live indices are computed from task arrays inside handlers.
    @State private var dropTarget: (column: String, taskID: String)? = nil

    private let allColumnNames = ["To Do", "In Progress", "Done"]

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                    .padding(.bottom, FabricSpacing.xxxl)

                contentGrid
                    .padding(.bottom, FabricSpacing.xxxl)

                fullWidthSections
                    .padding(.bottom, FabricSpacing.xxxl)

                kanbanDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                timelineDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                progressDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                pillsAndDotsDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                statCardDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                feedbackDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                loadingDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                sliderDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                radarDemo
            }
            .padding(.horizontal, FabricSpacing.xxl)
            .padding(.vertical, FabricSpacing.xxxl)
        }
        .scrollIndicators(.hidden)
        .fabricSurface(FabricColors.linen, textureIntensity: 0.045)
        .frame(minWidth: 860, minHeight: 680)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.md) {
            Text("Fabric")
                .fabricDisplay()
                .padding(.bottom, FabricSpacing.xs)

            Text("A design system that feels like cloth.\nSoft surfaces. Warm ink. Gentle interactions.")
                .fabricBody()
                .foregroundStyle(FabricColors.inkSecondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            // Subtle divider — like a fold in the cloth
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            FabricColors.inkTertiary.opacity(0.0),
                            FabricColors.inkTertiary.opacity(0.25),
                            FabricColors.inkTertiary.opacity(0.25),
                            FabricColors.inkTertiary.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .padding(.top, FabricSpacing.lg)
        }
    }

    // MARK: - Content Grid

    private var contentGrid: some View {
        HStack(alignment: .top, spacing: FabricSpacing.xl) {
            // Left column
            VStack(spacing: FabricSpacing.xl) {
                paletteCard
                formCard
            }
            .frame(maxWidth: .infinity, alignment: .top)

            // Right column
            VStack(spacing: FabricSpacing.xl) {
                typographyCard
                controlsCard
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    // MARK: - Palette

    private var paletteCard: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Palette").fabricHeading()

                // Surface swatches
                Text("Surfaces").fabricCaption()
                HStack(spacing: FabricSpacing.sm) {
                    swatch("Linen", FabricColors.linen)
                    swatch("Canvas", FabricColors.canvas)
                    swatch("Parchment", FabricColors.parchment)
                    swatch("Burlap", FabricColors.burlap)
                }

                // Accent swatches
                Text("Accents").fabricCaption()
                    .padding(.top, FabricSpacing.xs)
                HStack(spacing: FabricSpacing.sm) {
                    swatch("Indigo", FabricColors.indigo)
                    swatch("Madder", FabricColors.madder)
                    swatch("Sage", FabricColors.sage)
                    swatch("Ochre", FabricColors.ochre)
                }

                // Ink swatches
                Text("Ink").fabricCaption()
                    .padding(.top, FabricSpacing.xs)
                HStack(spacing: FabricSpacing.sm) {
                    swatch("Primary", FabricColors.inkPrimary)
                    swatch("Secondary", FabricColors.inkSecondary)
                    swatch("Tertiary", FabricColors.inkTertiary)
                }
            }
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: FabricSpacing.xs) {
            FabricSpacing.shape(radius: FabricSpacing.radiusXs)
                .fill(color)
                .frame(width: 52, height: 40)
                .overlay {
                    FabricSpacing.shape(radius: FabricSpacing.radiusXs)
                        .strokeBorder(
                            LinearGradient(
                                colors: [FabricColors.highlight, Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
                .shadow(color: FabricColors.shadow, radius: 4, x: 0, y: 2)

            Text(name)
                .font(.system(size: 10, weight: .medium, design: .default))
                .tracking(0.3)
                .foregroundStyle(FabricColors.inkTertiary)
        }
    }

    // MARK: - Typography

    private var typographyCard: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Typography").fabricHeading()

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Display").fabricCaption()
                        Text("Cloth & Thread").fabricDisplay()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Title").fabricCaption()
                        Text("Warm Surfaces").fabricTitle()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Heading").fabricCaption()
                        Text("Settled Into Material").fabricHeading()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Body").fabricCaption()
                        Text("Text that feels absorbed into the surface beneath it, like ink wicking gently into woven fibers.")
                            .fabricBody()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Caption").fabricCaption()
                        Text("Secondary information in a quieter voice")
                            .fabricCaption()
                    }
                }
            }
        }
    }

    // MARK: - Form

    private var formCard: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Form").fabricHeading()

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                        Text("Name").fabricCaption()
                        FabricTextField(label: "Name", placeholder: "Enter your name", text: $nameField, leadingIcon: "person")
                    }

                    VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                        Text("Email").fabricCaption()
                        FabricTextField(label: "Email", placeholder: "you@example.com", text: $emailField, leadingIcon: "envelope")
                    }

                    VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                        Text("Notes").fabricCaption()
                        FabricTextField(label: "Notes", placeholder: "Optional notes...", text: $notesField)
                    }
                }

                HStack(spacing: FabricSpacing.md) {
                    Button("Submit") { }
                        .buttonStyle(.fabric)
                    Button("Clear") { }
                        .buttonStyle(.fabricGhost)
                }
            }
        }
    }

    // MARK: - Controls

    private var controlsCard: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Controls").fabricHeading()

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Toggle("Notifications", isOn: $toggleNotifications)
                        .toggleStyle(.fabric)

                    Toggle("Auto-save drafts", isOn: $toggleAutoSave)
                        .toggleStyle(.fabric)

                    Toggle("Disabled control", isOn: $toggleDarkMode)
                        .toggleStyle(.fabric)
                        .disabled(true)
                }

                // Divider
                Rectangle()
                    .fill(FabricColors.inkTertiary.opacity(0.15))
                    .frame(height: 0.5)

                Text("Buttons").fabricHeading()
                    .padding(.top, FabricSpacing.xs)

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    HStack(spacing: FabricSpacing.md) {
                        Button("Primary") { }
                            .buttonStyle(.fabric)
                        Button("Secondary") { }
                            .buttonStyle(.fabricSecondary)
                        Button("Ghost") { }
                            .buttonStyle(.fabricGhost)
                    }

                    Text("Disabled").fabricCaption()
                    HStack(spacing: FabricSpacing.md) {
                        Button("Primary") { }
                            .buttonStyle(.fabric)
                            .disabled(true)
                        Button("Secondary") { }
                            .buttonStyle(.fabricSecondary)
                            .disabled(true)
                    }
                }
            }
        }
    }

    // MARK: - Full-Width

    private var fullWidthSections: some View {
        FabricCard {
            HStack(alignment: .top, spacing: FabricSpacing.xxl) {
                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Living Together").fabricTitle()

                    Text("Every element shares the same surface. Buttons settle into the weave. Text absorbs like ink. Toggles slide with the weight of cloth. Nothing floats above — everything belongs.")
                        .fabricBody()
                        .foregroundStyle(FabricColors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                    FabricTextField(label: "Note", placeholder: "Quick note...", text: $notesField)

                    Toggle("Remember me", isOn: $toggleNotifications)
                        .toggleStyle(.fabric)

                    HStack(spacing: FabricSpacing.md) {
                        Button("Save") { }
                            .buttonStyle(.fabric)
                        Button("Discard") { }
                            .buttonStyle(.fabricGhost)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    // MARK: - Kanban Demo

    private var kanbanDemo: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.lg) {
            Text("Kanban Board").fabricTitle()
            Text("Drag cards between columns — reorder within or move across")
                .fabricCaption()

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: FabricSpacing.md) {
                    kanbanColumn("To Do", tasks: $todoTasks, isTargeted: $todoTargeted)
                    kanbanColumn("In Progress", tasks: $inProgressTasks, isTargeted: $inProgressTargeted)
                    kanbanColumn("Done", tasks: $doneTasks, isTargeted: $doneTargeted)
                }
            }
        }
    }

    private func kanbanColumn(
        _ columnId: String,
        tasks: Binding<[KanbanTask]>,
        isTargeted: Binding<Bool>
    ) -> some View {
        FabricKanbanColumn(columnId, count: tasks.wrappedValue.count, isDropTarget: isTargeted.wrappedValue) {
            ForEach(tasks.wrappedValue) { task in
                VStack(spacing: FabricSpacing.sm) {
                    // Placeholder scoped with its own animation
                    if dropTarget?.column == columnId && dropTarget?.taskID == task.id {
                        FabricDropPlaceholder(accent: .indigo)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    FabricTaskCard(
                        task.title,
                        description: task.description,
                        tags: task.fabricTags,
                        // Always pass closures — they guard live index internally
                        onMoveUp: {
                            guard let idx = tasks.wrappedValue.firstIndex(where: { $0.id == task.id }),
                                  idx > 0 else { return }
                            withAnimation(FabricAnimation.reorder) {
                                tasks.wrappedValue.swapAt(idx, idx - 1)
                            }
                            announceMove(task, position: idx, column: columnId)
                        },
                        onMoveDown: {
                            guard let idx = tasks.wrappedValue.firstIndex(where: { $0.id == task.id }),
                                  idx < tasks.wrappedValue.count - 1 else { return }
                            withAnimation(FabricAnimation.reorder) {
                                tasks.wrappedValue.swapAt(idx, idx + 1)
                            }
                            announceMove(task, position: idx + 2, column: columnId)
                        },
                        onMoveToColumn: { target in moveToColumn(task, target: target) },
                        availableColumns: allColumnNames.filter { $0 != columnId }
                    )
                    .draggable(task) {
                        FabricTaskCard(
                            task.title,
                            description: task.description,
                            tags: task.fabricTags
                        )
                        .frame(width: FabricAnimation.dragPreviewWidth)
                        .opacity(FabricAnimation.dragPreviewOpacity)
                        .shadow(color: FabricColors.shadow, radius: 16, y: 8)
                    }
                }
                .dropDestination(for: KanbanTask.self) { droppedTasks, _ in
                    defer { clearDropState() }
                    guard droppedTasks.count == 1, let dropped = droppedTasks.first else { return false }
                    guard dropped.id != task.id else { return true }

                    guard let targetIndex = tasks.wrappedValue.firstIndex(where: { $0.id == task.id }) else { return false }
                    let sourceIndex = tasks.wrappedValue.firstIndex(where: { $0.id == dropped.id })

                    withAnimation(FabricAnimation.reorder) {
                        removeTask(dropped)
                        let adjusted = if let sourceIndex, sourceIndex < targetIndex {
                            targetIndex - 1
                        } else {
                            targetIndex
                        }
                        tasks.wrappedValue.insert(dropped, at: min(adjusted, tasks.wrappedValue.count))
                    }
                    let finalIndex = tasks.wrappedValue.firstIndex(where: { $0.id == dropped.id }) ?? 0
                    announceMove(dropped, position: finalIndex + 1, column: columnId)
                    return true
                } isTargeted: { targeted in
                    if targeted {
                        dropTarget = (column: columnId, taskID: task.id)
                    } else if dropTarget?.column == columnId && dropTarget?.taskID == task.id {
                        dropTarget = nil
                    }
                }
            }

            // End-of-column placeholder
            if isTargeted.wrappedValue && dropTarget?.column != columnId {
                FabricDropPlaceholder(accent: .indigo)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        // Animate the entire column content when tasks change order or placeholder appears
        .animation(FabricAnimation.reorder, value: tasks.wrappedValue.map(\.id))
        .animation(FabricAnimation.reorder, value: dropTarget?.column == columnId ? dropTarget?.taskID : nil)
        .dropDestination(for: KanbanTask.self) { droppedTasks, _ in
            defer { clearDropState() }
            guard droppedTasks.count == 1, let dropped = droppedTasks.first else { return false }

            // If a card-level insertion is active for this column, route to that position
            if let active = dropTarget, active.column == columnId,
               let targetIndex = tasks.wrappedValue.firstIndex(where: { $0.id == active.taskID }) {
                let sourceIndex = tasks.wrappedValue.firstIndex(where: { $0.id == dropped.id })
                withAnimation(FabricAnimation.reorder) {
                    removeTask(dropped)
                    let adjusted = if let sourceIndex, sourceIndex < targetIndex {
                        targetIndex - 1
                    } else {
                        targetIndex
                    }
                    tasks.wrappedValue.insert(dropped, at: min(adjusted, tasks.wrappedValue.count))
                }
                let finalIndex = tasks.wrappedValue.firstIndex(where: { $0.id == dropped.id }) ?? 0
                announceMove(dropped, position: finalIndex + 1, column: columnId)
                return true
            }

            // Same-column: move to end
            if let sourceIndex = tasks.wrappedValue.firstIndex(where: { $0.id == dropped.id }) {
                guard sourceIndex < tasks.wrappedValue.count - 1 else { return true }
                withAnimation(FabricAnimation.reorder) {
                    tasks.wrappedValue.move(
                        fromOffsets: IndexSet(integer: sourceIndex),
                        toOffset: tasks.wrappedValue.count
                    )
                }
                announceMove(dropped, position: tasks.wrappedValue.count, column: columnId)
                return true
            }

            // Cross-column: remove from source, append to target
            withAnimation(FabricAnimation.reorder) {
                removeTask(dropped)
                tasks.wrappedValue.append(dropped)
            }
            announceMove(dropped, position: tasks.wrappedValue.count, column: columnId)
            return true
        } isTargeted: { targeted in
            isTargeted.wrappedValue = targeted && dropTarget?.column != columnId
        }
        .animation(FabricAnimation.press, value: isTargeted.wrappedValue)
    }

    // MARK: - Kanban Helpers

    private func removeTask(_ task: KanbanTask) {
        todoTasks.removeAll { $0.id == task.id }
        inProgressTasks.removeAll { $0.id == task.id }
        doneTasks.removeAll { $0.id == task.id }
    }

    private func clearDropState() {
        dropTarget = nil
    }

    private func moveToColumn(_ task: KanbanTask, target: String) {
        withAnimation(FabricAnimation.reorder) {
            removeTask(task)
            switch target {
            case "To Do": todoTasks.append(task)
            case "In Progress": inProgressTasks.append(task)
            case "Done": doneTasks.append(task)
            default: break
            }
        }
        announceMove(task, position: nil, column: target)
    }

    private func announceMove(_ task: KanbanTask?, position: Int?, column: String) {
        guard let task else { return }
        let message = if let position {
            "Moved \(task.title) to position \(position) in \(column)"
        } else {
            "Moved \(task.title) to \(column)"
        }
        guard let window = NSApp.mainWindow else { return }
        NSAccessibility.post(
            element: window,
            notification: .announcementRequested,
            userInfo: [
                .announcement: message,
                .priority: NSAccessibilityPriorityLevel.high
            ]
        )
    }

    // MARK: - Timeline Demo

    private var timelineDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Timeline").fabricTitle()

                FabricTimeline(items: [
                    .init(
                        timestamp: "Jan 15",
                        title: "Project kickoff",
                        style: .milestone(accent: .sage)
                    ),
                    .init(
                        timestamp: "Jan 22",
                        title: "Design explorations complete",
                        description: "Settled on warm textile direction"
                    ),
                    .init(
                        timestamp: "Feb 3",
                        title: "Component library started"
                    ),
                    .init(
                        timestamp: "Feb 14",
                        title: "Design review",
                        description: "Stakeholder sign-off on all tokens",
                        style: .milestone(accent: .indigo)
                    ),
                    .init(
                        timestamp: "Mar 1",
                        title: "Development sprint begins"
                    ),
                ])
                .padding(.horizontal, FabricSpacing.lg)
            }
        }
    }

    // MARK: - Pills & Dots Demo

    private var pillsAndDotsDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Pills & Dots").fabricTitle()

                Text("Pills").fabricCaption()
                FabricFlowLayout(spacing: FabricSpacing.sm) {
                    FabricPill("Neutral")
                    FabricPill("Indigo", accent: .indigo)
                    FabricPill("Sage", accent: .sage)
                    FabricPill("Ochre", accent: .ochre)
                    FabricPill("Madder", accent: .madder)
                }

                Text("Status Dots").fabricCaption()
                    .padding(.top, FabricSpacing.xs)
                HStack(spacing: FabricSpacing.md) {
                    HStack(spacing: FabricSpacing.xs) {
                        FabricStatusDot(label: "Neutral")
                        Text("Neutral").fabricCaption()
                    }
                    HStack(spacing: FabricSpacing.xs) {
                        FabricStatusDot(accent: .sage, label: "Online")
                        Text("Online").fabricCaption()
                    }
                    HStack(spacing: FabricSpacing.xs) {
                        FabricStatusDot(accent: .madder, label: "Error")
                        Text("Error").fabricCaption()
                    }
                    HStack(spacing: FabricSpacing.xs) {
                        FabricStatusDot(accent: .ochre, label: "Warning")
                        Text("Warning").fabricCaption()
                    }
                    HStack(spacing: FabricSpacing.xs) {
                        FabricStatusDot()
                        Text("Decorative").fabricCaption()
                    }
                }
            }
        }
    }

    // MARK: - Stat Card Demo

    private var statCardDemo: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.lg) {
            Text("Stat Cards").fabricTitle()

            HStack(spacing: FabricSpacing.md) {
                FabricStatCard(value: "2,847", label: "Total Users", accent: .indigo)
                FabricStatCard(value: "98.5%", label: "Uptime", accent: .sage)
                FabricStatCard(value: "12", label: "Open Issues", accent: .madder, tinted: true)
                FabricStatCard(value: "$4.2K", label: "Revenue", accent: .ochre)
            }
        }
    }

    // MARK: - Feedback Demo

    private var feedbackDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Feedback").fabricTitle()

                Text("Empty State").fabricCaption()
                FabricEmptyState(
                    systemImage: "doc.text.magnifyingglass",
                    title: "No Results Found",
                    subtitle: "Try adjusting your search or filters.",
                    action: .init(title: "Clear Filters") { }
                )

                Rectangle()
                    .fill(FabricColors.inkTertiary.opacity(0.15))
                    .frame(height: 0.5)

                Text("Error Banner").fabricCaption()
                FabricErrorBanner(
                    "Build Warnings",
                    warnings: [
                        .init(id: "1", title: "AppDelegate.swift", subtitle: "Unused variable 'config'"),
                        .init(id: "2", title: "ViewModel.swift", subtitle: "Expression implicitly coerced"),
                        .init(id: "3", title: "Network.swift", subtitle: "Deprecated API usage"),
                    ],
                    isExpanded: $errorBannerExpanded
                )

                Rectangle()
                    .fill(FabricColors.inkTertiary.opacity(0.15))
                    .frame(height: 0.5)

                Text("Skeleton").fabricCaption()
                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    FabricSkeleton(.line, height: 16)
                    FabricSkeleton(.block(lines: 3), height: 12)
                }
                .frame(maxWidth: 400)
            }
        }
    }

    // MARK: - Slider Demo

    private var sliderDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Sliders").fabricTitle()

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Volume").fabricCaption()
                    FabricSlider(
                        value: $volumeValue,
                        label: "Volume",
                        accent: .indigo,
                        leadingIcon: "speaker.fill",
                        trailingIcon: "speaker.wave.3.fill"
                    )

                    Text("Brightness").fabricCaption()
                    FabricSlider(
                        value: $brightnessValue,
                        label: "Brightness",
                        accent: .ochre,
                        leadingIcon: "sun.min",
                        trailingIcon: "sun.max"
                    )

                    Text("With Ticks").fabricCaption()
                    FabricSlider(
                        value: $sliderValue,
                        accent: .sage,
                        ticks: 5
                    )

                    Text("Plain").fabricCaption()
                    FabricSlider(value: $sliderValue, accent: .madder)
                }
            }
        }
    }

    // MARK: - Loading Demo

    private var loadingDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Loading").fabricTitle()

                HStack(spacing: FabricSpacing.xxl) {
                    VStack(spacing: FabricSpacing.md) {
                        Text("Dots").fabricCaption()
                        FabricLoadingIndicator(.dots, accent: .indigo, label: "Processing")
                    }

                    VStack(spacing: FabricSpacing.md) {
                        Text("Ring").fabricCaption()
                        FabricLoadingIndicator(.ring, accent: .sage, label: "Syncing")
                    }

                    VStack(spacing: FabricSpacing.md) {
                        Text("Ochre Dots").fabricCaption()
                        FabricLoadingIndicator(.dots, accent: .ochre)
                    }

                    VStack(spacing: FabricSpacing.md) {
                        Text("Madder Ring").fabricCaption()
                        FabricLoadingIndicator(.ring, accent: .madder)
                    }
                }
            }
        }
    }

    // MARK: - Radar Demo

    private var radarDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Radar Scanner").fabricTitle()

                HStack(spacing: FabricSpacing.xl) {
                    FabricRadarScanner(accent: .sage)
                        .frame(width: 120, height: 120)

                    FabricRadarScanner(accent: .indigo)
                        .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                        Text("Monitoring").fabricHeading()
                        Text("Active scanning for changes across monitored endpoints. Each blip represents a detected signal.")
                            .fabricBody()
                            .foregroundStyle(FabricColors.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Progress Demo

    private var progressDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.xl) {
                Text("Progress").fabricTitle()

                // Step indicator
                VStack(spacing: FabricSpacing.md) {
                    FabricStepIndicator(
                        steps: ["Brief", "Design", "Review", "Ship"],
                        currentStep: currentStep,
                        onStepTapped: { step in currentStep = step }
                    )
                    HStack(spacing: FabricSpacing.md) {
                        Button("Back") { currentStep = max(0, currentStep - 1) }
                            .buttonStyle(.fabricGhost)
                        Button("Next") { currentStep = min(3, currentStep + 1) }
                            .buttonStyle(.fabricGhost)
                    }
                }

                // Divider
                Rectangle()
                    .fill(FabricColors.inkTertiary.opacity(0.15))
                    .frame(height: 0.5)

                // Progress bar
                FabricProgressBar(
                    value: progressValue,
                    label: "Upload progress",
                    showPercentage: true,
                    accent: .indigo
                )

                // Progress ring
                HStack(spacing: FabricSpacing.xl) {
                    FabricProgressRing(value: ringValue, accent: .sage) {
                        Text("40%").fabricCaption()
                    }
                    .frame(width: 80, height: 80)

                    FabricProgressRing(value: 0.75, accent: .indigo) {
                        Text("75%").fabricCaption()
                    }
                    .frame(width: 80, height: 80)

                    FabricProgressRing(value: 1.0, accent: .ochre) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FabricColors.ochre)
                    }
                    .frame(width: 80, height: 80)
                }
            }
        }
    }
}

#Preview {
    ShowcaseView()
}
