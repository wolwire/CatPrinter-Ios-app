import SwiftUI

/// Reusable slider component with value display and optional reset button
struct AppSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let defaultValue: Double?
    let label: String
    let color: Color
    let showValue: Bool
    let valueFormatter: (Double) -> String
    let onChange: (() -> Void)?
    
    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        defaultValue: Double? = nil,
        label: String,
        color: Color,
        showValue: Bool = true,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.2f", $0) },
        onChange: (() -> Void)? = nil
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.defaultValue = defaultValue
        self.label = label
        self.color = color
        self.showValue = showValue
        self.valueFormatter = valueFormatter
        self.onChange = onChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .bold()
                    .foregroundColor(AppDesignSystem.Colors.textSecondary)
                Spacer()
                
                if showValue {
                    Text(valueFormatter(value))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(color)
                }
                
                // Reset Button (if default value provided)
                if let defaultVal = defaultValue, abs(value - defaultVal) > 0.001 {
                    Button {
                        value = defaultVal
                        onChange?()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(AppDesignSystem.Colors.textSecondary)
                    }
                    .padding(.leading, AppDesignSystem.Spacing.sm)
                }
            }
            
            Slider(value: $value, in: range, step: step)
                .onChange(of: value) { _, _ in onChange?() }
                .tint(color)
        }
    }
}

/// Slider for integer values
struct AppIntSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    let color: Color
    let onChange: (() ->Void)?
    
    init(
        value: Binding<Int>,
        in range: ClosedRange<Int>,
        label: String,
        color: Color,
        onChange: (() -> Void)? = nil
    ) {
        self._value = value
        self.range = range
        self.label = label
        self.color = color
        self.onChange = onChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .bold()
                    .foregroundColor(AppDesignSystem.Colors.textSecondary)
                Spacer()
                
                Text("\(value)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .onChange(of: value) { _, _ in onChange?() }
            .tint(color)
        }
    }
}

/// Settings-style slider with label and value on same line
struct AppSettingsSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    let color: Color
    let valueFormatter: (Double) -> String
    
    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 0.5,
        label: String,
        color: Color,
        valueFormatter: @escaping (Double) -> String = { String(format: "%.1f", $0) }
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.color = color
        self.valueFormatter = valueFormatter
    }
    
    var body: some View {
        VStack(spacing: AppDesignSystem.Spacing.md) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text(valueFormatter(value))
                    .font(.subheadline)
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
    }
}
