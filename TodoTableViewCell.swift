import UIKit

class TodoTableViewCell: UITableViewCell {
    
    // MARK: - 아웃렛
    @IBOutlet weak var memoIconView: UIImageView!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var colorDotView: UIView!
    
    // MARK: - 체크 상태 변경 핸들러
    var onCheckToggle: (() -> Void)?
    
    // MARK: - 셀 초기 설정
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 버튼 존재 여부 확인
        if checkButton == nil {
            print("🚨 checkButton is nil")
        } else {
            print("✅ checkButton exists")
            checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
        }
    }
    
    // MARK: - 제약 조건 및 뷰 스타일 설정
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if colorDotView.translatesAutoresizingMaskIntoConstraints {
            colorDotView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                colorDotView.widthAnchor.constraint(equalToConstant: 20),
                colorDotView.heightAnchor.constraint(equalTo: colorDotView.widthAnchor),
                colorDotView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                colorDotView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        }
        
        colorDotView.layer.cornerRadius = 10
        colorDotView.clipsToBounds = true
    }
    
    func configure(with todo: TodoItem) {
        titleLabel.text = todo.title
        colorDotView.backgroundColor = UIColor.systemGray
        updateCheckState(isDone: todo.isDone)
    }

    // MARK: - 체크 상태 UI 업데이트
    func updateCheckState(isDone: Bool) {
        if isDone {
            checkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            titleLabel.attributedText = NSAttributedString(
                string: titleLabel.text ?? "",
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
        } else {
            checkButton.setImage(UIImage(systemName: "circle"), for: .normal)
            titleLabel.attributedText = NSAttributedString(string: titleLabel.text ?? "")
        }
    }
    
    // MARK: - 체크 버튼 액션
    @objc func checkTapped() {
        onCheckToggle?()
    }
}

