import UIKit
import DGCharts

class StatsViewController: UIViewController {

    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var selectDateButton: UIButton!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var focusTimeLabel: UILabel!
    @IBOutlet weak var normalTimeLabel: UILabel!
    @IBOutlet weak var pieChartView: PieChartView!

    var selectedDate: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        let today = getTodayString()
        selectedDate = today
        dateLabel.text = today

        updateStudySummary(for: today)
        updatePieChart(for: today)
        updateLineChart(for: today) // ✅ 꺾은선그래프도 초기 표시
    }

    @IBAction func selectDateTapped(_ sender: UIButton) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ko_KR")
        datePicker.preferredDatePickerStyle = .wheels

        let alert = UIAlertController(title: "날짜 선택", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        datePicker.frame = CGRect(x: 10, y: 30, width: alert.view.bounds.width - 40, height: 200)

        alert.addAction(UIAlertAction(title: "선택", style: .default, handler: { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let pickedDate = formatter.string(from: datePicker.date)
            self.selectedDate = pickedDate
            self.dateLabel.text = pickedDate
            self.updateStudySummary(for: pickedDate)
            self.updatePieChart(for: pickedDate)
            self.updateLineChart(for: pickedDate) // ✅ 선택 날짜 기준 꺾은선그래프 갱신
        }))

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    func updateStudySummary(for date: String) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let fullData = UserDefaults.standard.dictionary(forKey: "studyData") as? [String: Any],
              let userData = fullData[userId] as? [String: Any] else { return }

        let normalData = (userData["normal"] as? [String: [String: NSNumber]])?[date] ?? [:]
        let focusData = (userData["focus"] as? [String: [String: NSNumber]])?[date] ?? [:]

        let normalSeconds = normalData.values.reduce(0) { $0 + $1.intValue }
        let focusSeconds = focusData.values.reduce(0) { $0 + $1.intValue }
        let totalSeconds = normalSeconds + focusSeconds

        totalTimeLabel.text = "총 공부 시간: \(formatTime(totalSeconds))"
        focusTimeLabel.text = "집중 시간: \(formatTime(focusSeconds))"
        normalTimeLabel.text = "일반 시간: \(formatTime(normalSeconds))"
    }

    func updatePieChart(for date: String) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let fullData = UserDefaults.standard.dictionary(forKey: "studyData") as? [String: Any],
              let userData = fullData[userId] as? [String: Any] else { return }

        let normalData = (userData["normal"] as? [String: [String: NSNumber]])?[date] ?? [:]
        let focusData = (userData["focus"] as? [String: [String: NSNumber]])?[date] ?? [:]

        var subjectTotals: [String: Int] = [:]
        for (subject, value) in normalData {
            subjectTotals[subject, default: 0] += value.intValue
        }
        for (subject, value) in focusData {
            subjectTotals[subject, default: 0] += value.intValue
        }

        let totalSeconds = subjectTotals.values.reduce(0, +)
        guard totalSeconds > 0 else {
            pieChartView.data = nil
            pieChartView.centerText = "공부 데이터 없음"
            return
        }

        let entries = subjectTotals.map { subject, seconds in
            let percentage = Double(seconds) / Double(totalSeconds)
            return PieChartDataEntry(value: percentage, label: subject)
        }

        let dataSet = PieChartDataSet(entries: entries, label: "과목별 공부 비중")
        dataSet.colors = ChartColorTemplates.material()
        dataSet.valueFormatter = DefaultValueFormatter(formatter: percentFormatter)
        dataSet.entryLabelFont = .systemFont(ofSize: 12)
        dataSet.valueFont = .systemFont(ofSize: 13, weight: .bold)

        let data = PieChartData(dataSet: dataSet)
        pieChartView.data = data

        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawEntryLabelsEnabled = false
        pieChartView.legend.enabled = true
        pieChartView.legend.orientation = .horizontal
        pieChartView.legend.horizontalAlignment = .center
        pieChartView.chartDescription.enabled = false
        pieChartView.holeRadiusPercent = 0.45
        pieChartView.animate(xAxisDuration: 1.0, easingOption: .easeOutBack)
    }

    func updateLineChart(for date: String) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let fullData = UserDefaults.standard.dictionary(forKey: "studyData") as? [String: Any],
              let userData = fullData[userId] as? [String: Any],
              let hourlyData = userData["hourly"] as? [String: [String: NSNumber]],
              let todayData = hourlyData[date] else {
            lineChartView.data = nil
            lineChartView.noDataText = "공부 데이터 없음"
            return
        }

        // 총합 계산
        let totalSeconds = todayData.values.reduce(0) { $0 + $1.doubleValue }
        let maxSeconds = todayData.values.map { $0.doubleValue }.max() ?? 0

        // ✅ 단위 설정 (시/분/초)
        var divisor: Double = 3600.0
        var suffix = "시간"
        if maxSeconds < 60 {
            divisor = 1
            suffix = "초"
        } else if maxSeconds < 3600 {
            divisor = 60
            suffix = "분"
        }

        // 데이터 엔트리 구성
        var entries: [ChartDataEntry] = []
        for hour in 0..<24 {
            let seconds = todayData["\(hour)"]?.doubleValue ?? 0
            let value = seconds / divisor
            entries.append(ChartDataEntry(x: Double(hour), y: value))
        }

        let dataSet = LineChartDataSet(entries: entries, label: "시간대별 공부량 (\(suffix))")
        dataSet.colors = [.systemBlue]
        dataSet.circleRadius = 3
        dataSet.circleColors = [.systemBlue]
        dataSet.lineWidth = 2
        dataSet.valueFont = .systemFont(ofSize: 9)
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.positiveSuffix = suffix
        dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)

        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data

        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.granularity = 1
        lineChartView.xAxis.labelCount = 6
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.rightAxis.enabled = false
        lineChartView.legend.enabled = true
        lineChartView.chartDescription.enabled = false
        lineChartView.animate(xAxisDuration: 1.0)
    }

    let percentFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 1
        f.multiplier = 100
        return f
    }()

    let hourFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.maximumFractionDigits = 1
        f.positiveSuffix = "시간"
        return f
    }()

    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60
        return String(format: "%02d시간 %02d분", h, m)
    }
}

