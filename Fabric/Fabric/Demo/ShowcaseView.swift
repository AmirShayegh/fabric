import SwiftUI
import UniformTypeIdentifiers
import Fabric

// MARK: - Kanban Task Model

struct KanbanTask: Identifiable, Codable, Equatable, Transferable {
    let id: String
    let title: String
    let description: String?
    let ticketNumber: String
    let tagLabel: String
    let tagAccentName: String
    let isBlocked: Bool

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
        ticketNumber: String,
        description: String? = nil,
        tag: String,
        accent: String,
        isBlocked: Bool = false
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.ticketNumber = ticketNumber
        self.description = description
        self.tagLabel = tag
        self.tagAccentName = accent
        self.isBlocked = isBlocked
    }
}

// MARK: - Timeline Reorder Drop Delegate

struct TimelineReorderDropDelegate: DropDelegate {
    let targetID: String
    @Binding var items: [FabricTimelineItem]

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        _ = provider.loadObject(ofClass: NSString.self) { reading, _ in
            guard let sourceID = reading as? String else { return }
            DispatchQueue.main.async {
                guard sourceID != targetID,
                      let srcIdx = items.firstIndex(where: { $0.id == sourceID }),
                      let dstIdx = items.firstIndex(where: { $0.id == targetID })
                else { return }
                withAnimation(FabricAnimation.reorder) {
                    items.move(
                        fromOffsets: IndexSet(integer: srcIdx),
                        toOffset: dstIdx > srcIdx ? dstIdx + 1 : dstIdx
                    )
                }
            }
        }
        return true
    }
}

// MARK: - ShowcaseView

struct ShowcaseView: View {

    @State private var nameField = ""
    @State private var emailField = ""
    @State private var notesField = ""
    @State private var errorField = "bad-email"
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
    @State private var editorText = ""
    @State private var editorErrorText = "Invalid content"
    @State private var segmentSelection = "Day"
    @State private var segmentAccentSelection = "Overview"

    // New component demos
    @State private var searchText = ""
    @State private var filterSafe = true
    @State private var filterWarning = false
    @State private var filterThreat = false
    @State private var breadcrumbItems: [FabricBreadcrumb.Item] = [
        .init(label: "Home"),
        .init(label: "Documents"),
        .init(label: "Projects"),
    ]
    @State private var disclosureExpanded = false
    @State private var disclosureExpanded2 = true
    @State private var checkA = true
    @State private var checkB = false
    @State private var checkC = false
    @State private var scoreValue: Double = 0.72
    @State private var tabSelection = "Overview"
    @State private var tabSelection2 = "System"

    // Kanban state
    @State private var todoTasks: [KanbanTask] = [
        KanbanTask("Design system refresh: core palette", ticketNumber: "T-042", tag: "feature", accent: "indigo", isBlocked: true),
        KanbanTask("Add keyboard shortcuts for kanban navigation", ticketNumber: "T-048", tag: "feature", accent: "indigo"),
        KanbanTask("Memory leak in dashboard render", ticketNumber: "ISS-007", tag: "high", accent: "madder"),
        KanbanTask("API integration: Stripe Connect", ticketNumber: "T-045", tag: "task", accent: "ochre"),
        KanbanTask("Write snapshot tests for card variants", ticketNumber: "T-051", tag: "chore", accent: "sage"),
    ]
    @State private var inProgressTasks: [KanbanTask] = [
        KanbanTask("Color system: dark mode tokens", ticketNumber: "T-043", tag: "feature", accent: "indigo"),
        KanbanTask("Update documentation: auth flow", ticketNumber: "T-046", tag: "chore", accent: "sage"),
        KanbanTask("Slow file watcher on large projects", ticketNumber: "ISS-012", tag: "medium", accent: "ochre", isBlocked: true),
    ]
    @State private var doneTasks: [KanbanTask] = [
        KanbanTask("Project brief and roadmap", ticketNumber: "T-039", tag: "chore", accent: "sage"),
        KanbanTask("Setup CI pipeline", ticketNumber: "T-036", tag: "task", accent: "ochre"),
        KanbanTask("Multi-window foundation", ticketNumber: "T-064", tag: "feature", accent: "indigo"),
        KanbanTask("Terminal embedding: PTY subprocess", ticketNumber: "T-028", tag: "feature", accent: "indigo"),
    ]
    @State private var todoTargeted = false
    @State private var inProgressTargeted = false
    @State private var doneTargeted = false
    /// Tracks which card is the active drop target by identity (not index).
    /// Live indices are computed from task arrays inside handlers.
    @State private var dropTarget: (column: String, taskID: String)? = nil
    @State private var selectedTimelineItem: String? = nil
    @State private var overlayDemoItems: [FabricTimelineItem] = [
        .init(id: "ov-plan", timestamp: "Phase 1", title: "Planning",
              kind: .milestone(accent: .sage)),
        .init(id: "ov-build", timestamp: "Phase 2", title: "Development",
              description: "Core feature build"),
        .init(id: "ov-test", timestamp: "Phase 3", title: "Testing"),
        .init(id: "ov-ship", timestamp: "Phase 4", title: "Shipping",
              kind: .milestone(accent: .ochre)),
    ]
    @State private var overlayDemoCounter = 5
    @State private var renamingItemID: String? = nil
    @State private var renameText = ""

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

                compactCardDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                inspectorPrimitivesDemo
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
                    .padding(.bottom, FabricSpacing.xxxl)

                segmentedControlDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                textEditorDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                searchFieldDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                filterPillDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                breadcrumbDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                disclosureGroupDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                checkboxDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                scoreGaugeDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                tabBarDemo
                    .padding(.bottom, FabricSpacing.xxxl)

                messageBubbleDemo
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

                    Divider()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mono Small").fabricCaption()
                        Text("T-048 · ISS-001").fabricMonoSmall()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mono Caption").fabricCaption()
                        Text("12 / 48 completed").fabricMonoCaption()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mono").fabricCaption()
                        Text("let status = .complete").fabricMono()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mono Large").fabricCaption()
                        Text("143").fabricMonoLarge()
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

                    VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                        Text("Error State").fabricCaption()
                        FabricTextField(label: "Email", placeholder: "you@example.com", text: $errorField, leadingIcon: "envelope", error: "Please enter a valid email address")
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
                        .toggleStyle(.fabric(accent: .sage))

                    Toggle("Dark mode", isOn: $toggleDarkMode)
                        .toggleStyle(.fabric(accent: .ochre))

                    Toggle("Disabled control", isOn: .constant(true))
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

                    Text("Accent Colors").fabricCaption()
                    HStack(spacing: FabricSpacing.md) {
                        Button("Sage") { }
                            .buttonStyle(.fabric(accent: .sage))
                        Button("Ochre") { }
                            .buttonStyle(.fabric(accent: .ochre))
                        Button("Madder") { }
                            .buttonStyle(.fabric(accent: .madder))
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
                    kanbanColumn("To Do", tasks: $todoTasks, isTargeted: $todoTargeted, onAdd: {
                        todoTasks.append(KanbanTask("New task", ticketNumber: "T-\(Int.random(in: 50...99))", tag: "task", accent: "ochre"))
                    })
                    kanbanColumn("In Progress", tasks: $inProgressTasks, isTargeted: $inProgressTargeted)
                    kanbanColumn("Done", tasks: $doneTasks, isTargeted: $doneTargeted)
                }
            }
        }
    }

    // MARK: - Compact Card Demo

    private var compactCardDemo: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.lg) {
            Text("Compact Cards").fabricTitle()
            Text("Ticket ID top-left, pills top-right, status indicators bottom")
                .fabricCaption()

            HStack(alignment: .top, spacing: FabricSpacing.md) {
                // Ticket with blocked indicator
                FabricTaskCard(
                    "Design System Refresh: Core Palette",
                    ticketNumber: "T-042",
                    tags: [
                        .init("feature", accent: .indigo),
                        .init("P6", accent: .indigo),
                    ],
                    layout: .compact,
                    statusIndicator: .blocked(),
                    avatar: .initials("JD")
                )
                .frame(maxWidth: 240)

                // Issue card with severity badge
                FabricTaskCard(
                    "Memory Leak in Dashboard Render",
                    ticketNumber: "ISS-007",
                    tags: [
                        .init("high-severity", accent: .madder),
                    ],
                    accent: .madder,
                    layout: .compact
                )
                .frame(maxWidth: 240)

                // Task card (no blocked, with avatar)
                FabricTaskCard(
                    "Update Documentation: Auth Flow",
                    ticketNumber: "T-043",
                    tags: [
                        .init("chore", accent: .sage),
                        .init("P6", accent: .indigo),
                    ],
                    layout: .compact,
                    avatar: .icon("person.fill")
                )
                .frame(maxWidth: 240)

                // Selected compact card
                FabricTaskCard(
                    "API Integration: Stripe Connect",
                    ticketNumber: "T-045",
                    tags: [
                        .init("task", accent: .ochre),
                        .init("P6", accent: .indigo),
                    ],
                    isSelected: true,
                    layout: .compact,
                    avatar: .initials("SK")
                )
                .frame(maxWidth: 240)
            }
        }
    }

    // MARK: - Inspector Primitives Demo

    private var inspectorPrimitivesDemo: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.lg) {
            Text("Inspector Primitives").fabricTitle()
            Text("Section labels, linked item rows, and activity entries for inspector panels")
                .fabricCaption()

            HStack(alignment: .top, spacing: FabricSpacing.xl) {
                // Section labels + linked items
                VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                    VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                        Text("Related Issues").fabricSectionLabel()
                        FabricLinkedItemRow("IPC Bridge implementation", id: "T-061", accent: .indigo) {}
                        FabricLinkedItemRow("Memory leak in render", id: "ISS-012", accent: .madder) {}
                        FabricLinkedItemRow("Window resizing hooks", id: "T-072", accent: .sage) {}
                    }

                    VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                        Text("Blocked By").fabricSectionLabel()
                        FabricLinkedItemRow("Auth flow refactor", id: "T-039")
                    }
                }
                .frame(maxWidth: 280)

                // Activity feed
                VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                    Text("Activity").fabricSectionLabel()
                    VStack(spacing: FabricSpacing.md) {
                        FabricActivityEntry(
                            "Claude edited window_manager.rs",
                            timestamp: "2m ago",
                            accent: .indigo
                        )
                        FabricActivityEntry(
                            "Status changed to In Progress",
                            timestamp: "1h ago",
                            accent: .sage
                        )
                        FabricActivityEntry(
                            "Blocked by ISS-012 added",
                            timestamp: "3h ago",
                            accent: .madder
                        )
                        FabricActivityEntry(
                            "Ticket created",
                            timestamp: "Mar 12"
                        )
                    }
                }
                .frame(maxWidth: 280)
            }
        }
    }

    private func kanbanColumn(
        _ columnId: String,
        tasks: Binding<[KanbanTask]>,
        isTargeted: Binding<Bool>,
        onAdd: (() -> Void)? = nil
    ) -> some View {
        FabricKanbanColumn(columnId, count: tasks.wrappedValue.count, isDropTarget: isTargeted.wrappedValue, columnWidth: 280, onAdd: onAdd) {
            ForEach(tasks.wrappedValue) { task in
                VStack(spacing: FabricSpacing.sm) {
                    // Placeholder scoped with its own animation
                    if dropTarget?.column == columnId && dropTarget?.taskID == task.id {
                        FabricDropPlaceholder(accent: .indigo)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    FabricTaskCard(
                        task.title,
                        ticketNumber: task.ticketNumber,
                        tags: task.fabricTags,
                        layout: .compact,
                        statusIndicator: task.isBlocked ? .blocked() : nil,
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
                            ticketNumber: task.ticketNumber,
                            tags: task.fabricTags,
                            layout: .compact
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

                // Vertical — project phases
                VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                    Text("Vertical — Project Phases").fabricCaption()

                    FabricTimeline(
                        items: [
                            .init(id: "v-kickoff", timestamp: "Jan 15", title: "Kickoff",
                                  kind: .milestone(accent: .sage)),
                            .init(id: "v-design", timestamp: "Jan 22", title: "Design",
                                  description: "Settled on warm textile direction"),
                            .init(id: "v-components", timestamp: "Feb 3", title: "Components",
                                  description: "Core library with design tokens"),
                            .init(id: "v-review", timestamp: "Feb 14", title: "Review",
                                  kind: .milestone(accent: .indigo)),
                            .init(id: "v-dev", timestamp: "Mar 1", title: "Dev Sprint"),
                        ],
                        selection: $selectedTimelineItem,
                        currentItemID: "v-components"
                    )
                }
                .padding(.horizontal, FabricSpacing.lg)

                // Vertical — non-interactive
                VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                    Text("Vertical — Non-interactive").fabricCaption()

                    FabricTimeline(items: [
                        .init(timestamp: "Q1", title: "Planning"),
                        .init(timestamp: "Q2", title: "Build"),
                        .init(timestamp: "Q3", title: "Launch"),
                    ])
                }
                .padding(.horizontal, FabricSpacing.lg)

                // Horizontal — release pipeline
                VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                    Text("Horizontal — Release Pipeline").fabricCaption()

                    FabricTimeline(
                        items: [
                            .init(id: "h-spec", timestamp: "Week 1", title: "Requirements Gathering"),
                            .init(id: "h-impl", timestamp: "Week 2–3", title: "Feature Development",
                                  description: "Core feature development across all modules"),
                            .init(id: "h-qa", timestamp: "Week 4", title: "Quality Assurance",
                                  description: "Manual and automated testing pass"),
                            .init(id: "h-staging", timestamp: "Week 5", title: "Staging Deploy",
                                  kind: .milestone(accent: .ochre)),
                            .init(id: "h-release", timestamp: "Week 6", title: "Production Release",
                                  description: "Production deploy with monitoring",
                                  kind: .milestone(accent: .sage)),
                        ],
                        selection: $selectedTimelineItem,
                        currentItemID: "h-qa",
                        accent: .ochre,
                        axis: .horizontal
                    )
                }
                .padding(.horizontal, FabricSpacing.lg)

                // Horizontal — onboarding flow
                VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                    Text("Horizontal — Onboarding").fabricCaption()

                    FabricTimeline(
                        items: [
                            .init(id: "ob-signup", timestamp: "Step 1", title: "Create Account"),
                            .init(id: "ob-profile", timestamp: "Step 2", title: "Complete Profile",
                                  description: "Add your name, avatar, and preferences"),
                            .init(id: "ob-team", timestamp: "Step 3", title: "Join Your Team",
                                  description: "Accept invite or create a new workspace"),
                            .init(id: "ob-done", timestamp: "Step 4", title: "Ready to Go",
                                  kind: .milestone(accent: .sage)),
                        ],
                        selection: $selectedTimelineItem,
                        currentItemID: "ob-profile",
                        accent: .indigo,
                        axis: .horizontal
                    )
                }
                .padding(.horizontal, FabricSpacing.lg)

                // Horizontal — interactive overlay demo (add, reorder, rename, delete)
                VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                    Text("Horizontal — Item Overlay + Trailing (interactive)").fabricCaption()
                    Text("Right-click to rename/delete. Drag to reorder. Tap + to add.")
                        .fabricTypography(.caption)
                        .foregroundStyle(FabricColors.inkTertiary)

                    FabricTimeline(
                        items: overlayDemoItems,
                        selection: $selectedTimelineItem,
                        currentItemID: overlayDemoItems.count > 1 ? overlayDemoItems[1].id : nil,
                        accent: .indigo,
                        axis: .horizontal,
                        itemOverlay: { item in
                            Color.clear
                                .contentShape(Rectangle())
                                .contextMenu {
                                    Button("Rename \(item.title)...") {
                                        renameText = item.title
                                        renamingItemID = item.id
                                    }
                                    Divider()
                                    Button("Delete \(item.title)...", role: .destructive) {
                                        withAnimation(FabricAnimation.press) {
                                            overlayDemoItems.removeAll { $0.id == item.id }
                                            if selectedTimelineItem == item.id {
                                                selectedTimelineItem = nil
                                            }
                                        }
                                    }
                                }
                                .onDrag {
                                    NSItemProvider(object: item.id as NSString)
                                } preview: {
                                    Text(item.title)
                                        .fabricTypography(.label)
                                        .fabricInk(.primary)
                                        .padding(.horizontal, FabricSpacing.md)
                                        .padding(.vertical, FabricSpacing.sm)
                                        .background(FabricColors.canvas)
                                        .clipShape(Capsule())
                                        .fabricShadow(.drag)
                                }
                                .onDrop(of: [.text], delegate: TimelineReorderDropDelegate(
                                    targetID: item.id,
                                    items: $overlayDemoItems
                                ))
                        },
                        trailingContent: {
                            Button {
                                let n = overlayDemoCounter
                                overlayDemoCounter += 1
                                let newItem = FabricTimelineItem(
                                    id: "ov-new-\(n)",
                                    timestamp: "Phase \(n)",
                                    title: "New Phase \(n)"
                                )
                                withAnimation(FabricAnimation.press) {
                                    overlayDemoItems.append(newItem)
                                }
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(FabricColors.inkTertiary)
                            }
                            .buttonStyle(.plain)
                            .help("Add phase")
                        }
                    )
                    .alert("Rename Phase", isPresented: Binding(
                        get: { renamingItemID != nil },
                        set: { if !$0 { renamingItemID = nil } }
                    )) {
                        TextField("Name", text: $renameText)
                        Button("Cancel", role: .cancel) { renamingItemID = nil }
                        Button("Rename") {
                            guard let id = renamingItemID,
                                  let idx = overlayDemoItems.firstIndex(where: { $0.id == id })
                            else { return }
                            let old = overlayDemoItems[idx]
                            overlayDemoItems[idx] = FabricTimelineItem(
                                id: old.id,
                                timestamp: old.timestamp,
                                title: renameText,
                                description: old.description,
                                kind: old.kind
                            )
                            renamingItemID = nil
                        }
                    }
                }
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

    // MARK: - Segmented Control Demo

    private var segmentedControlDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.xl) {
                Text("Segmented Control").fabricTitle()

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Default (Indigo)").fabricLabel()
                    FabricSegmentedControl(
                        selection: $segmentSelection,
                        segments: ["Day", "Week", "Month"]
                    )
                }

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Sage Accent").fabricLabel()
                    FabricSegmentedControl(
                        selection: $segmentAccentSelection,
                        segments: ["Overview", "Details", "History", "Settings"],
                        accent: .sage
                    )
                }

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Disabled").fabricLabel()
                    FabricSegmentedControl(
                        selection: .constant("Active"),
                        segments: ["Active", "Inactive"]
                    )
                    .disabled(true)
                }
            }
        }
    }

    // MARK: - Text Editor Demo

    private var textEditorDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.xl) {
                Text("Text Editor").fabricTitle()

                VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                    Text("Notes").fabricCaption()
                    FabricTextEditor(
                        placeholder: "Write your notes here…",
                        text: $editorText
                    )
                }

                VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                    Text("Error State").fabricCaption()
                    FabricTextEditor(
                        label: "Description",
                        placeholder: "Describe the issue…",
                        text: $editorErrorText,
                        error: "Description must be at least 20 characters"
                    )
                }

                VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                    Text("Disabled").fabricCaption()
                    FabricTextEditor(
                        placeholder: "Read-only content…",
                        text: .constant("This editor is disabled and cannot be edited.")
                    )
                    .disabled(true)
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

    // MARK: - Search Field Demo

    private var searchFieldDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Search Field").fabricTitle()

                FabricSearchField(placeholder: "Search components\u{2026}", text: $searchText)

                FabricSearchField(placeholder: "Disabled search", text: .constant(""))
                    .disabled(true)
            }
        }
    }

    // MARK: - Filter Pill Demo

    private var filterPillDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Filter Pills").fabricTitle()

                Text("Risk Levels").fabricCaption()
                HStack(spacing: FabricSpacing.sm) {
                    FabricFilterPill("Safe", icon: "checkmark.shield", accent: .sage, isSelected: filterSafe) {
                        filterSafe.toggle()
                    }
                    FabricFilterPill("Warning", icon: "exclamationmark.triangle", accent: .ochre, isSelected: filterWarning) {
                        filterWarning.toggle()
                    }
                    FabricFilterPill("Threat", icon: "xmark.shield", accent: .madder, isSelected: filterThreat) {
                        filterThreat.toggle()
                    }
                }

                Text("Disabled").fabricCaption()
                HStack(spacing: FabricSpacing.sm) {
                    FabricFilterPill("Locked", accent: .indigo, isSelected: true) { }
                        .disabled(true)
                    FabricFilterPill("Locked", accent: .indigo, isSelected: false) { }
                        .disabled(true)
                }
            }
        }
    }

    // MARK: - Breadcrumb Demo

    private var breadcrumbDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Breadcrumb").fabricTitle()

                FabricBreadcrumb(items: breadcrumbItems) { item in
                    if let index = breadcrumbItems.firstIndex(where: { $0.id == item.id }) {
                        breadcrumbItems = Array(breadcrumbItems.prefix(through: index))
                    }
                }

                HStack(spacing: FabricSpacing.sm) {
                    Button("Add Level") {
                        breadcrumbItems.append(.init(label: "Folder \(breadcrumbItems.count + 1)"))
                    }
                    .buttonStyle(.fabricSecondary)

                    Button("Reset") {
                        breadcrumbItems = [.init(label: "Home")]
                    }
                    .buttonStyle(.fabricGhost)
                }
            }
        }
    }

    // MARK: - Disclosure Group Demo

    private var disclosureGroupDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Disclosure Group").fabricTitle()

                FabricDisclosureGroup("Build Settings", count: 5, accent: .indigo, isExpanded: $disclosureExpanded) {
                    VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                        Text("Optimization Level: -O2").fabricBody()
                        Text("Architecture: arm64").fabricBody()
                        Text("Swift Version: 6.0").fabricBody()
                        Text("Deployment Target: macOS 14").fabricBody()
                        Text("Code Signing: Automatic").fabricBody()
                    }
                }

                FabricDisclosureGroup("Warnings", count: 3, accent: .madder, isExpanded: $disclosureExpanded2) {
                    VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                        Text("Unused variable 'config'").fabricCaption()
                        Text("Deprecated API usage").fabricCaption()
                        Text("Expression implicitly coerced").fabricCaption()
                    }
                }

                FabricDisclosureGroup("Disabled Section", isExpanded: .constant(false)) {
                    Text("Hidden content")
                }
                .disabled(true)
            }
        }
    }

    // MARK: - Checkbox Demo

    private var checkboxDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Checkbox").fabricTitle()

                let allChecked = checkA && checkB && checkC
                let noneChecked = !checkA && !checkB && !checkC

                Toggle("Select All", isOn: Binding(
                    get: { allChecked },
                    set: { newValue in checkA = newValue; checkB = newValue; checkC = newValue }
                ))
                .toggleStyle(.fabricCheckbox(
                    checkState: allChecked || noneChecked ? .standard : .indeterminate
                ))

                VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                    Toggle("Enable notifications", isOn: $checkA)
                        .toggleStyle(.fabricCheckbox)

                    Toggle("Auto-save drafts", isOn: $checkB)
                        .toggleStyle(.fabricCheckbox(accent: .sage))

                    Toggle("Send analytics", isOn: $checkC)
                        .toggleStyle(.fabricCheckbox(accent: .ochre))
                }
                .padding(.leading, FabricSpacing.lg)

                Toggle("Disabled checkbox", isOn: .constant(true))
                    .toggleStyle(.fabricCheckbox)
                    .disabled(true)
            }
        }
    }

    // MARK: - Score Gauge Demo

    private var scoreGaugeDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Score Gauge").fabricTitle()

                HStack(spacing: FabricSpacing.xl) {
                    FabricScoreGauge(value: scoreValue) {
                        VStack(spacing: 2) {
                            Text("\(Int(scoreValue * 100))").fabricMonoLarge()
                            Text("Score").fabricCaption()
                        }
                    }
                    .frame(width: 100, height: 100)

                    FabricScoreGauge(value: 0.25) {
                        VStack(spacing: 2) {
                            Text("25").fabricMonoLarge()
                            Text("Low").fabricCaption()
                        }
                    }
                    .frame(width: 100, height: 100)

                    FabricScoreGauge(value: 0.55) {
                        VStack(spacing: 2) {
                            Text("55").fabricMonoLarge()
                            Text("Mid").fabricCaption()
                        }
                    }
                    .frame(width: 100, height: 100)

                    FabricScoreGauge(value: 0.92, lineWidth: 10) {
                        VStack(spacing: 2) {
                            Text("92").fabricMonoLarge()
                            Text("High").fabricCaption()
                        }
                    }
                    .frame(width: 100, height: 100)
                }

                FabricSlider(value: $scoreValue, label: "Score", accent: .indigo)
            }
        }
    }

    // MARK: - Tab Bar Demo

    private var tabBarDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Tab Bar").fabricTitle()

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Default").fabricCaption()
                    FabricTabBar(
                        selection: $tabSelection,
                        tabs: ["Overview", "Details", "History"]
                    )
                    Text("Selected: \(tabSelection)").fabricCaption()
                }

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Sage Accent").fabricCaption()
                    FabricTabBar(
                        selection: $tabSelection2,
                        tabs: ["System", "Network", "Storage", "Memory"],
                        accent: .sage
                    )
                }

                VStack(alignment: .leading, spacing: FabricSpacing.md) {
                    Text("Disabled").fabricCaption()
                    FabricTabBar(
                        selection: .constant("Active"),
                        tabs: ["Active", "Archived"]
                    )
                    .disabled(true)
                }
            }
        }
    }

    // MARK: - Message Bubble Demo

    private var messageBubbleDemo: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.lg) {
                Text("Message Bubbles").fabricTitle()

                VStack(spacing: FabricSpacing.md) {
                    FabricMessageBubble(
                        role: .user,
                        avatar: .initials("AS"),
                        timestamp: "2:34 PM"
                    ) {
                        Text("Can you analyze the system health and show me what needs attention?")
                            .fabricBody()
                    }

                    FabricMessageBubble(
                        role: .assistant,
                        avatar: .icon("sparkles"),
                        timestamp: "2:34 PM"
                    ) {
                        Text("I've scanned your system. Here's what I found: 3 large cache directories totaling 4.2 GB, and 2 unused Xcode simulators. Would you like me to clean them up?")
                            .fabricBody()
                    }

                    FabricMessageBubble(
                        role: .assistant,
                        avatar: .icon("sparkles"),
                        isStreaming: true
                    ) {
                        Text("Analyzing disk usage patterns")
                            .fabricBody()
                            .foregroundStyle(FabricColors.inkSecondary)
                    }
                }
            }
        }
    }
}

#Preview {
    ShowcaseView()
}
