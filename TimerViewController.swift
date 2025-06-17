import UIKit
import CoreMotion

class TimerViewController: UIViewController {

    @IBOutlet weak var outerStackView: UIStackView!
    @IBOutlet weak var totalTitleLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var normalButton: UIButton!
    @IBOutlet weak var focusButton: UIButton!

    enum TimerMode {
        case normal
        case focus
    }

    var selectedMode: TimerMode = .normal
    var normalTimers: [String: Int] = [:]
    var focusTimers: [String: Int] = [:]
    var currentRunningSubject: String?
    var mainTimer: Timer?
    let motionManager = CMMotionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        updateModeButtons()
        updateTotalTime()
        loadTimersFromUserDefaults()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        if selectedMode == .focus && currentRunningSubject != nil {
            startMotionDetection()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
        if selectedMode == .focus && currentRunningSubject != nil {
            stopFocusModeWithAlert(reason: "다른 화면으로 이동했습니다.")
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    @objc func appDidEnterBackground() {
        if selectedMode == .focus && currentRunningSubject != nil {
            stopFocusModeWithAlert(reason: "앱이 백그라운드로 전환되었습니다.")
        }
    }

    func startMotionDetection() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 0.5
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }

            let pitch = motion.attitude.pitch
            let roll = motion.attitude.roll
            let userAccel = motion.userAcceleration

            if abs(pitch) > 0.7 || abs(roll) > 0.7 ||
                abs(userAccel.x) > 0.3 || abs(userAccel.y) > 0.3 || abs(userAccel.z) > 0.3 {
                self.stopFocusModeWithAlert(reason: "기기가 움직였습니다.")
            }
        }
    }

    func stopMotionDetection() {
        motionManager.stopDeviceMotionUpdates()
    }

    func stopFocusModeWithAlert(reason: String) {
        mainTimer?.invalidate()
        mainTimer = nil
        currentRunningSubject = nil
        stopMotionDetection()

        let alert = UIAlertController(
            title: "집중모드 중단",
            message: "\(reason)\n타이머가 자동으로 정지되었습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @IBAction func normalButtonTapped(_ sender: UIButton) {
        selectedMode = .normal
        stopMotionDetection()
        updateModeButtons()
        updateTimersDisplay()
    }

    @IBAction func focusButtonTapped(_ sender: UIButton) {
        selectedMode = .focus
        if currentRunningSubject != nil {
            startMotionDetection()
        }
        updateModeButtons()
        updateTimersDisplay()
    }

    func updateModeButtons() {
        let selectedBg = UIColor(white: 0.9, alpha: 1)
        let unselectedBg = UIColor.clear
        let selectedText = UIColor.black
        let unselectedText = UIColor.lightGray

        [normalButton, focusButton].forEach {
            $0?.layer.cornerRadius = 8
            $0?.clipsToBounds = true
            $0?.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            $0?.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.lightGray.cgColor
        }

        normalButton.backgroundColor = selectedMode == .normal ? selectedBg : unselectedBg
        normalButton.setTitleColor(selectedMode == .normal ? selectedText : unselectedText, for: .normal)
        focusButton.backgroundColor = selectedMode == .focus ? selectedBg : unselectedBg
        focusButton.setTitleColor(selectedMode == .focus ? selectedText : unselectedText, for: .normal)
    }

    @IBAction func addSubjectTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "과목 추가", message: "과목 이름을 입력하세요", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "예: 수학, 영어" }

        let add = UIAlertAction(title: "추가", style: .default) { _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self.normalTimers[name] = 0
                self.focusTimers[name] = 0
                self.addSubjectRow(subject: name)
                self.updateTimersDisplay()
                self.saveTimersToUserDefaults()
            }
        }

        alert.addAction(add)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    func addSubjectRow(subject: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.distribution = .fill

        let label = UILabel()
        label.text = subject
        label.font = .systemFont(ofSize: 16)
        label.widthAnchor.constraint(equalToConstant: 60).isActive = true

        let button = UIButton(type: .system)
        button.setTitle("▶", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let timeLabel = UILabel()
        timeLabel.text = "00:00:00"
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        timeLabel.textColor = .darkGray

        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("🗑", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 16)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.widthAnchor.constraint(equalToConstant: 30).isActive = true

        button.addAction(UIAction { _ in
            self.handlePlayButton(subject: subject, labelToUpdate: timeLabel)
        }, for: .touchUpInside)

        deleteButton.addAction(UIAction { _ in
            self.normalTimers.removeValue(forKey: subject)
            self.focusTimers.removeValue(forKey: subject)
            if self.currentRunningSubject == subject {
                self.mainTimer?.invalidate()
                self.currentRunningSubject = nil
            }
            self.outerStackView.removeArrangedSubview(row)
            row.removeFromSuperview()
            self.updateTotalTime()
            self.saveTimersToUserDefaults()
        }, for: .touchUpInside)

        row.addArrangedSubview(label)
        row.addArrangedSubview(button)
        row.addArrangedSubview(timeLabel)
        row.addArrangedSubview(deleteButton)

        let index = outerStackView.arrangedSubviews.count - 1
        outerStackView.insertArrangedSubview(row, at: index)
    }

    func handlePlayButton(subject: String, labelToUpdate: UILabel) {
        if currentRunningSubject == subject {
            mainTimer?.invalidate()
            currentRunningSubject = nil
        } else {
            mainTimer?.invalidate()
            currentRunningSubject = subject

            if selectedMode == .focus {
                startMotionDetection()
            }

            mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if self.selectedMode == .normal {
                    self.normalTimers[subject, default: 0] += 1
                } else {
                    self.focusTimers[subject, default: 0] += 1
                }
                let seconds = (self.selectedMode == .normal ? self.normalTimers[subject] : self.focusTimers[subject]) ?? 0
                let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
                labelToUpdate.text = String(format: "%02d:%02d:%02d", h, m, s)
                self.updateTotalTime()
                self.saveTimeForToday(subject: subject, seconds: 1, mode: self.selectedMode)
                self.saveTimersToUserDefaults()
            }
        }
    }

    func updateTotalTime() {
        let totalSeconds = normalTimers.values.reduce(0, +) + focusTimers.values.reduce(0, +)
        let h = totalSeconds / 3600, m = (totalSeconds % 3600) / 60, s = totalSeconds % 60
        totalTimeLabel.text = String(format: "%02d:%02d:%02d", h, m, s)
    }

    func updateTimersDisplay() {
        for view in outerStackView.arrangedSubviews {
            guard let row = view as? UIStackView, row.arrangedSubviews.count >= 3 else { continue }
            let subjectLabel = row.arrangedSubviews[0] as? UILabel
            let timeLabel = row.arrangedSubviews[2] as? UILabel
            guard let subject = subjectLabel?.text else { continue }
            let seconds = (selectedMode == .normal ? normalTimers[subject] : focusTimers[subject]) ?? 0
            let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
            timeLabel?.text = String(format: "%02d:%02d:%02d", h, m, s)
        }
    }

    func saveTimeForToday(subject: String, seconds: Int, mode: TimerMode) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        let today = getTodayString()

        // 전체 저장 구조 불러오기
        var fullData = UserDefaults.standard.dictionary(forKey: "studyData") as? [String: Any] ?? [:]
        var userData = fullData[userId] as? [String: Any] ?? [:]

        // 1️⃣ 모드별 시간 저장 (기존 코드)
        var modeData = userData[mode == .normal ? "normal" : "focus"] as? [String: [String: NSNumber]] ?? [:]
        var dateData = modeData[today] ?? [:]
        let previous = dateData[subject]?.intValue ?? 0
        dateData[subject] = NSNumber(value: previous + seconds)
        modeData[today] = dateData
        userData[mode == .normal ? "normal" : "focus"] = modeData

        // 2️⃣ 📍 시간대별 기록 추가 (0~23시 기준)
        let hour = Calendar.current.component(.hour, from: Date())
        var hourlyData = userData["hourly"] as? [String: [String: NSNumber]] ?? [:]
        var todayHourly = hourlyData[today] ?? [:]
        let prevHourSeconds = todayHourly["\(hour)"]?.intValue ?? 0
        todayHourly["\(hour)"] = NSNumber(value: prevHourSeconds + seconds)
        hourlyData[today] = todayHourly
        userData["hourly"] = hourlyData

        // 최종 저장
        fullData[userId] = userData
        UserDefaults.standard.set(fullData, forKey: "studyData")
    }

    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func saveTimersToUserDefaults() {
        let data: [String: Any] = [
            "normal": normalTimers,
            "focus": focusTimers
        ]
        UserDefaults.standard.set(data, forKey: "persistentTimers")
    }

    func loadTimersFromUserDefaults() {
        guard let data = UserDefaults.standard.dictionary(forKey: "persistentTimers") else { return }
        if let normal = data["normal"] as? [String: Int] {
            normalTimers = normal
        }
        if let focus = data["focus"] as? [String: Int] {
            focusTimers = focus
        }
        for subject in Set(normalTimers.keys).union(focusTimers.keys) {
            addSubjectRow(subject: subject)
        }
    }
}

