import SwiftUI

enum Duration: Int, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case six = 6
    case eight = 8
    case twelve = 12
}

enum TimeSummary: String {
    case from = "From"
    case to = "To"
    case duration = "Duration"
}

struct TimeSelectionView: View {
    @Binding var selectedStartTime: Date
    @Binding var selectedDuration: Int // Duration in hours
    @State private var showCustomTime = false
    @State private var customEndTime = Date()
    
    private let availableHours = Duration.allCases.map(\.rawValue)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Start Time Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Starting Time")
                    .font(.headline)
                
                DatePicker("", selection: $selectedStartTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }
            
            // Duration Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.headline)
                
                HStack {
                    Button(action: { showCustomTime.toggle() }) {
                        HStack {
                            Image(systemName: showCustomTime ? "checkmark.circle.fill" : "circle")
                            Text("Custom End Time")
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                if showCustomTime {
                    DatePicker("End Time", selection: $customEndTime, in: selectedStartTime..., displayedComponents: [.hourAndMinute])
                        .onChange(of: customEndTime) { newValue in
                            let hours = Calendar.current.dateComponents([.hour], from: selectedStartTime, to: newValue).hour ?? 0
                            selectedDuration = max(1, hours)
                        }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Duration.allCases, id: \.self) { duration in
                                Button(action: {
                                    selectedDuration = duration.rawValue
                                }) {
                                    Text("\(duration.rawValue)h")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedDuration == duration.rawValue ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedDuration == duration.rawValue ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            
            // Summary
            if let endTime = Calendar.current.date(byAdding: .hour, value: selectedDuration, to: selectedStartTime) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summary")
                        .font(.headline)
                    
                    Text("\(TimeSummary.from.rawValue): \(formatDate(selectedStartTime))")
                    Text("\(TimeSummary.to.rawValue): \(formatDate(endTime))")
                    Text("\(TimeSummary.duration.rawValue): \(selectedDuration) hours")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
