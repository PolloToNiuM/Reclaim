import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var viewModel: ReclaimViewModel
    @State private var editedBlock: ScheduledBlock?
    @State private var isCreating = false

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ReclaimScreenHeader(
                        title: "Planifiés",
                        subtitle: "\(viewModel.scheduledBlocks.count)/\(viewModel.maximumScheduledBlocks) blocages. Tu peux modifier ou supprimer chaque horaire."
                    )

                    if viewModel.scheduledBlocks.isEmpty {
                        emptyCard
                    } else {
                        ForEach(viewModel.scheduledBlocks.sorted(by: startsBefore)) { block in
                            Button {
                                editedBlock = block
                            } label: {
                                scheduledBlockRow(block)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ReclaimButton(
                        title: viewModel.scheduledBlocks.count >= viewModel.maximumScheduledBlocks ? "Maximum atteint" : "Ajouter un blocage",
                        symbol: "plus",
                        isPrimary: viewModel.scheduledBlocks.count < viewModel.maximumScheduledBlocks
                    ) {
                        guard viewModel.scheduledBlocks.count < viewModel.maximumScheduledBlocks else { return }
                        isCreating = true
                    }
                    .disabled(viewModel.scheduledBlocks.count >= viewModel.maximumScheduledBlocks)
                }
                .padding(20)
            }
        }
        .navigationTitle("Planifiés")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isCreating) {
            NavigationStack {
                ScheduledBlockEditor(block: nil) { block in
                    viewModel.upsertScheduledBlock(block)
                    isCreating = false
                } onDelete: { _ in
                    isCreating = false
                }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $editedBlock) { block in
            NavigationStack {
                ScheduledBlockEditor(block: block) { updatedBlock in
                    viewModel.upsertScheduledBlock(updatedBlock)
                    editedBlock = nil
                } onDelete: { deletedBlock in
                    viewModel.deleteScheduledBlock(deletedBlock)
                    editedBlock = nil
                }
            }
            .presentationDetents([.large])
        }
    }

    private var emptyCard: some View {
        ReclaimCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Aucun blocage planifié")
                    .font(ReclaimTypography.section)
                    .foregroundStyle(ReclaimColors.text)
                Text("Ajoute par exemple sommeil, travail ou déconnexion du soir.")
                    .font(.subheadline)
                    .foregroundStyle(ReclaimColors.muted)
            }
        }
    }

    private func scheduledBlockRow(_ block: ScheduledBlock) -> some View {
        ReclaimCard {
            HStack(spacing: 14) {
                Image(systemName: block.usesStrictMode ? "lock.shield.fill" : "calendar")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(block.usesStrictMode ? ReclaimColors.primary : ReclaimColors.secondary)
                    .frame(width: 52, height: 52)
                    .background((block.usesStrictMode ? ReclaimColors.primary : ReclaimColors.secondary).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(block.name)
                        .font(ReclaimTypography.cardTitle)
                        .foregroundStyle(ReclaimColors.text)
                    Text(block.scheduleSummary)
                        .font(.subheadline)
                        .foregroundStyle(ReclaimColors.muted)
                }

                Spacer()

                Image(systemName: "pencil")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(ReclaimColors.primary)
                    .clipShape(Circle())
            }
        }
    }

    private func startsBefore(_ lhs: ScheduledBlock, _ rhs: ScheduledBlock) -> Bool {
        let calendar = Calendar.current
        return calendar.dateComponents([.hour, .minute], from: lhs.start).minutesOfDay < calendar.dateComponents([.hour, .minute], from: rhs.start).minutesOfDay
    }
}

private struct ScheduledBlockEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var block: ScheduledBlock
    let isNew: Bool
    let onSave: (ScheduledBlock) -> Void
    let onDelete: (ScheduledBlock) -> Void

    init(block: ScheduledBlock?, onSave: @escaping (ScheduledBlock) -> Void, onDelete: @escaping (ScheduledBlock) -> Void) {
        _block = State(initialValue: block ?? ScheduledBlock(
            name: "Nouveau blocage",
            start: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(),
            end: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday],
            usesStrictMode: false
        ))
        isNew = block == nil
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            ReclaimBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ReclaimScreenHeader(title: isNew ? "Nouveau blocage" : "Modifier")

                    ReclaimCard {
                        VStack(alignment: .leading, spacing: 18) {
                            TextField("Nom", text: $block.name)
                                .font(ReclaimTypography.cardTitle)
                                .padding(14)
                                .background(ReclaimColors.cream)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                            DatePicker("Début", selection: $block.start, displayedComponents: .hourAndMinute)
                            DatePicker("Fin", selection: $block.end, displayedComponents: .hourAndMinute)

                            weekdayPicker

                            Toggle("Mode strict", isOn: $block.usesStrictMode)
                                .tint(ReclaimColors.primary)
                        }
                        .foregroundStyle(ReclaimColors.text)
                    }

                    ReclaimButton(title: isNew ? "Ajouter" : "Enregistrer", symbol: "checkmark") {
                        onSave(block)
                    }

                    if !isNew {
                        ReclaimButton(title: "Supprimer", symbol: "trash", isPrimary: false) {
                            onDelete(block)
                        }
                    }
                }
                .padding(20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(ReclaimColors.primary)
                        .clipShape(Circle())
                }
            }
        }
    }

    private var weekdayPicker: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.allCases) { day in
                Button {
                    if block.days.contains(day) {
                        block.days.remove(day)
                    } else {
                        block.days.insert(day)
                    }
                } label: {
                    Text(day.shortLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(block.days.contains(day) ? ReclaimColors.primary : ReclaimColors.cream)
                        .foregroundStyle(block.days.contains(day) ? .white : ReclaimColors.text)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
