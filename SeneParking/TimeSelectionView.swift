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
    @Binding var selectedDuration: Int
    @State private var showCustomTime = false
    @State private var customEndTime = Date()
    @State private var timeError: String? = nil
    let parkingLot: ParkingLot
    
    private let availableHours = Duration.allCases.map { $0.rawValue }
    
    // Helper function to get today's date at a specific time
    private func getTimeForToday(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        
        guard let time = formatter.date(from: timeString.lowercased()) else { return nil }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedStartTime)
        
        var finalComponents = DateComponents()
        finalComponents.year = selectedDateComponents.year
        finalComponents.month = selectedDateComponents.month
        finalComponents.day = selectedDateComponents.day
        finalComponents.hour = timeComponents.hour
        finalComponents.minute = timeComponents.minute
        
        return calendar.date(from: finalComponents)
    }
    
    private var isValidStartTime: Bool {
        guard let openTime = getTimeForToday(parkingLot.openTime) else { return false }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: selectedStartTime)
        let openComponents = calendar.dateComponents([.hour, .minute], from: openTime)
        
        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let openHour = openComponents.hour,
              let openMinute = openComponents.minute else {
            return false
        }
        
        if startHour < openHour || (startHour == openHour && startMinute < openMinute) {
            return false
        }
        
        return true
    }
    
    private var isOvernightReservation: Bool {
        guard let closeTime = getTimeForToday(parkingLot.closeTime) else { return false }
        guard let openTime = getTimeForToday(parkingLot.openTime) else { return false }
        let endTime = selectedStartTime.addingTimeInterval(Double(selectedDuration) * 3600)
        
        return endTime > closeTime || endTime < openTime
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Start Time Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting Time")
                        .font(.headline)
                    
                    let currentDate = Calendar.current.startOfDay(for: Date())
                    
                    DatePicker("",
                               selection: $selectedStartTime,
                               in: currentDate...,
                               displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    
                    if let error = timeError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
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
                            DatePicker("End Time",
                                       selection: $customEndTime,
                                       in: selectedStartTime...,
                                       displayedComponents: [.hourAndMinute])
                            .onChange(of: customEndTime) { newValue in
                                let hours = Calendar.current.dateComponents([.hour],
                                                                            from: selectedStartTime,
                                                                            to: newValue).hour ?? 0
                                selectedDuration = max(1, hours)
                            }
                        } else {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12) {
                                    ForEach(availableHours, id: \.self) { hours in
                                        Button(action: {
                                            selectedDuration = hours
                                        }) {
                                            Text("\(hours)h")
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedDuration == hours ? Color.blue : Color.gray.opacity(0.2))
                                                .foregroundColor(selectedDuration == hours ? .white : .primary)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Summary (only show if start time is valid)
                    if let endTime = Calendar.current.date(byAdding: .hour, value: selectedDuration, to: selectedStartTime) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Summary")
                                .font(.headline)
                            
                            Text("\(TimeSummary.from.rawValue): \(formatDate(selectedStartTime))")
                            Text("\(TimeSummary.to.rawValue): \(formatDate(endTime))")
                            Text("\(TimeSummary.duration.rawValue): \(selectedDuration) hours")

                            if isOvernightReservation {
                                Text("⚠️ This reservation extends beyond closing time (\(parkingLot.closeTime)). Additional overnight fees will apply.")
                                    .foregroundColor(.orange)
                                    .font(.callout)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                
                
                
            }
            .padding()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
