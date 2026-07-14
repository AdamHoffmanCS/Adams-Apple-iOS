import SwiftUI

struct FastingHistoryView: View {
    @EnvironmentObject var store: Store
    @State private var editingRecord: FastRecord?

    private let tf: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .full; f.timeStyle = .none; return f
    }()
    private let timeF: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()

    var body: some View {
        ScrollView {
            if store.fastHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.muted)
                    Text("No fasting history yet.")
                        .font(.title3.weight(.semibold))
                    Text("Complete a fast to see it here.")
                        .font(.subheadline).foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(store.fastHistory) { record in
                        historyCard(record)
                    }
                }
                .padding(20)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Fasting History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $editingRecord) { record in
            EditNoteSheet(record: record) { updated in
                store.updateFastRecord(updated)
            }
        }
    }

    private func historyCard(_ record: FastRecord) -> some View {
        let hours = record.durationHours
        let hrs = Int(hours)
        let mins = Int((hours - Double(hrs)) * 60)
        let durationText = mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tf.string(from: record.start))
                        .font(.system(size: 16, weight: .bold))
                    Text("\(timeF.string(from: record.start)) → \(timeF.string(from: record.end))")
                        .font(.subheadline).foregroundColor(Theme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(durationText)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(record.completed ? Theme.green : Theme.text)
                    HStack(spacing: 4) {
                        Text(record.protocolLabel)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(record.completed ? Theme.green.opacity(0.15) : Theme.inset)
                            .foregroundColor(record.completed ? Theme.green : Theme.muted)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        if record.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.green)
                                .font(.caption)
                        }
                    }
                }
            }

            Divider().background(Theme.border)

            if record.note.isEmpty {
                Button {
                    editingRecord = record
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 13))
                        Text("Add a note")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Theme.muted)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.muted)
                        .padding(.top, 2)
                    Text(record.note)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        editingRecord = record
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.muted)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deleteFastRecord(record)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Edit note sheet (for history view)

struct EditNoteSheet: View {
    var record: FastRecord
    var onSave: (FastRecord) -> Void

    @State private var note: String
    @Environment(\.dismiss) private var dismiss

    init(record: FastRecord, onSave: @escaping (FastRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        _note = State(initialValue: record.note)
    }

    private let tf: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(tf.string(from: record.start))
                    .font(.subheadline).foregroundColor(Theme.muted)
                    .padding(.horizontal, 20).padding(.top, 8)
                TextEditor(text: $note)
                    .frame(minHeight: 160)
                    .padding(12)
                    .background(Theme.inset)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border))
                    .padding(.horizontal, 20)
                Spacer()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var r = record
                        r.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(r)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.green)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.muted)
                }
            }
        }
    }
}
