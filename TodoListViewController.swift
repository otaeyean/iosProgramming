import UIKit

class TodoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    var selectedDate: Date = Date()
    var todoList: [Date: [TodoItem]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureArrowButton()
        updateDateLabel(with: Date())
        
        tableView.delegate = self
        tableView.dataSource = self
        
        configureAddButton()
    }
    
    // MARK: - 날짜 표시
    func updateDateLabel(with date: Date) {
        selectedDate = date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        let dateString = formatter.string(from: date)
        
        dateLabel.text = "📆 선택한 날짜: \(dateString)"
        dateLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        dateLabel.textColor = .systemIndigo
        tableView.reloadData()
    }
    
    // MARK: - ▼ 버튼
    private func configureArrowButton() {
        arrowButton.setTitle("▼", for: .normal)
        arrowButton.setTitleColor(.systemIndigo, for: .normal)
        arrowButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        arrowButton.addTarget(self, action: #selector(showDatePickerPopup), for: .touchUpInside)
    }

    @objc func showDatePickerPopup() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let popupVC = sb.instantiateViewController(withIdentifier: "DatePickerPopupViewController") as? DatePickerPopupViewController {
            popupVC.modalPresentationStyle = .overFullScreen
            popupVC.modalTransitionStyle = .crossDissolve
            popupVC.onDateSelected = { [weak self] selectedDate in
                self?.updateDateLabel(with: selectedDate)
            }
            present(popupVC, animated: true)
        }
    }
    
    // MARK: - + 버튼 디자인
    private func configureAddButton() {
        addButton.setTitle("+", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 30
    }
    
    // MARK: - + 버튼 눌렀을 때
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "새 할 일", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "할 일 제목을 입력하세요"
        }
        
        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            guard let self = self,
                  let title = alert.textFields?.first?.text,
                  !title.isEmpty else { return }
            
            let newTodo = TodoItem(title: title, isDone: false, memo: nil)
            self.todoList[self.selectedDate, default: []].append(newTodo)
            self.tableView.reloadData()
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoList[selectedDate, default: []].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as? TodoTableViewCell else {
            return UITableViewCell()
        }

        let todo = todoList[selectedDate]![indexPath.row]
        cell.configure(with: todo)

        cell.onCheckToggle = { [weak self] in
            self?.todoList[self!.selectedDate]?[indexPath.row].isDone.toggle()
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        return cell
    }

    // MARK: - 스와이프 삭제
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            todoList[selectedDate]?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "삭제"
    }
    
    // MARK: - 셀 클릭 → 커스텀 메모 팝업
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todo = todoList[selectedDate]![indexPath.row]
        
        let memoVC = CustomMemoViewController()
        memoVC.initialText = todo.memo
        memoVC.onSave = { [weak self] newMemo in
            self?.todoList[self!.selectedDate]?[indexPath.row].memo = newMemo
            tableView.deselectRow(at: indexPath, animated: true)
        }
        memoVC.modalPresentationStyle = .overFullScreen
        present(memoVC, animated: true)
    }
}

