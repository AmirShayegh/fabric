import SwiftUI

struct ShowcaseView: View {

    @State private var nameField = ""
    @State private var emailField = ""
    @State private var notesField = ""
    @State private var toggleNotifications = true
    @State private var toggleAutoSave = false
    @State private var toggleDarkMode = true

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                    .padding(.bottom, FabricSpacing.xxxl)

                contentGrid
                    .padding(.bottom, FabricSpacing.xxxl)

                fullWidthSections
            }
            .padding(.horizontal, FabricSpacing.xxl)
            .padding(.vertical, FabricSpacing.xxxl)
        }
        .fabricSurface(FabricColors.linen, textureIntensity: 0.035)
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 52, height: 40)
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
                        FabricTextField(label: "Name", placeholder: "Enter your name", text: $nameField)
                    }

                    VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                        Text("Email").fabricCaption()
                        FabricTextField(label: "Email", placeholder: "you@example.com", text: $emailField)
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
}

#Preview {
    ShowcaseView()
}
