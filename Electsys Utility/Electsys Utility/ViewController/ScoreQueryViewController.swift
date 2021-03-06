//
//  ScoreQueryViewController.swift
//  Electsys Utility
//
//  Created by 法好 on 2019/9/15.
//  Copyright © 2019 yuxiqian. All rights reserved.
//

import Cocoa
import CSV

@available(OSX 10.12.2, *)
class ScoreQueryViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, YearAndTermSelectionDelegate, ExportFormatDecisionDelegate {
    var scoreList: [NGScore] = []
    var openedWindow: NSWindow?
    
    @IBAction func TBButtonTapped(_ sender: NSButton) {
        restartAnalyse(sender)
    }
    
    @IBOutlet weak var TBButton: NSButton!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var promptTextField: NSTextField!
    @IBOutlet var blurredView: RMBlurredView!

    @IBAction func restartAnalyse(_ sender: NSButton) {
        scoreList.removeAll()
        tableView.reloadData()
        updateTableViewContents()
        openYearTermSelectionPanel()
    }

    @IBAction func calculateGpa(_ sender: NSButton) {
        if scoreList.count == 0 {
            return
        }
        let gpaResult = GPAKits.calculateGpa(scores: scoreList)
        if gpaResult == nil {
            showErrorMessageNormal(errorMsg: "未能成功计算您的平均绩点（GPA）。")
        } else {
            showGpaMessage(infoMsg: "根据「\(GPAKits.GpaStrategies[PreferenceKits.gpaStrategy.rawValue])」计算，\n您的平均绩点（GPA）为 \(String(format: "%.2f", gpaResult!))。")
        }
    }

    override func viewDidLoad() {
        updateTableViewContents()

        let sortByName = NSSortDescriptor(key: "sortByName", ascending: true)
        let sortByCode = NSSortDescriptor(key: "sortByCode", ascending: true)
        let sortByTeacher = NSSortDescriptor(key: "sortByTeacher", ascending: true)
        let sortByScore = NSSortDescriptor(key: "sortByScore", ascending: true)
        let sortByPoint = NSSortDescriptor(key: "sortByPoint", ascending: true)

        tableView.tableColumns[0].sortDescriptorPrototype = sortByName
        tableView.tableColumns[1].sortDescriptorPrototype = sortByCode
        tableView.tableColumns[2].sortDescriptorPrototype = sortByTeacher
        tableView.tableColumns[3].sortDescriptorPrototype = sortByScore
        tableView.tableColumns[4].sortDescriptorPrototype = sortByPoint

        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))

        super.viewDidLoad()
    }

    override func viewDidAppear() {
        if scoreList.count == 0 {
            openYearTermSelectionPanel()
        }
        updateTableViewContents()
        super.viewDidAppear()
    }

    lazy var sheetViewController: TermSelectingViewController = {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        return storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("YearAndTermViewController"))
            as! TermSelectingViewController
    }()

    func successCourseDataTransfer(data: [NGCourse]) {
        ESLog.error("bad request type")
        dismiss(sheetViewController)
    }

    func successExamDataTransfer(data: [NGExam]) {
        ESLog.error("bad request type")
        dismiss(sheetViewController)
    }

    func successScoreDataTransfer(data: [NGScore]) {
        scoreList = data
        updateTableViewContents()
        dismiss(sheetViewController)
    }

    func shutWindow() {
        dismiss(sheetViewController)
    }

    func updateTableViewContents() {
        if scoreList.count == 0 {
            promptTextField.stringValue = "目前没有任何科目的考试成绩。"
            view.window?.makeFirstResponder(blurredView)
            blurredView.blurRadius = 3.0
            blurredView.isHidden = false
            if TBButton != nil {
                TBButton.isHidden = true
            }
            return
        }

        blurredView.isHidden = true
        if TBButton != nil {
            TBButton.isHidden = false
        }
        blurredView.blurRadius = 0.0

        promptTextField.isEnabled = true
        promptTextField.stringValue = "现有 \(scoreList.count) 门科目的考试成绩。"
        tableView.reloadData()
    }

    func openYearTermSelectionPanel() {
        sheetViewController.successDelegate = self
        sheetViewController.requestType = .score
        presentAsSheet(sheetViewController)
        sheetViewController.enableUI()
    }

    func showErrorMessageNormal(errorMsg: String) {
        let errorAlert: NSAlert = NSAlert()
        errorAlert.informativeText = errorMsg
        errorAlert.messageText = "出错啦"
        errorAlert.addButton(withTitle: "嗯")
        errorAlert.alertStyle = NSAlert.Style.critical
        errorAlert.beginSheetModal(for: view.window!)
        
        ESLog.error("error occurred. message: ", errorMsg)
    }

    func showInformativeMessage(infoMsg: String) {
        let infoAlert: NSAlert = NSAlert()
        infoAlert.informativeText = infoMsg
        infoAlert.messageText = "提醒"
        infoAlert.addButton(withTitle: "嗯")
        infoAlert.alertStyle = NSAlert.Style.informational
        infoAlert.beginSheetModal(for: view.window!)
        
        ESLog.info("informative message: ", infoMsg)
    }

    func showGpaMessage(infoMsg: String) {
        let gpaAlert: NSAlert = NSAlert()
        gpaAlert.informativeText = infoMsg
        gpaAlert.messageText = "平均绩点计算结果"
        gpaAlert.addButton(withTitle: "嗯")
        gpaAlert.addButton(withTitle: "了解更多…")
        gpaAlert.alertStyle = NSAlert.Style.informational
        gpaAlert.beginSheetModal(for: view.window!) { returnCode in
            if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                if let url = URL(string: "https://apps.chasedream.com/gpa/#"), NSWorkspace.shared.open(url) {
                    // successfully opened
                }
            }
        }
    }

    fileprivate enum CellIdentifiers {
        static let NameCell = "CourseNameCellID"
        static let CodeCell = "CourseCodeCellID"
        static let TeacherCell = "TeacherNameCellID"
        static let ScoreCell = "FinalScoreCellID"
        static let PointCell = "PointCellID"
    }

//
//    let sortByName = NSSortDescriptor(key: "sortByName", ascending: true)
//    let sortByCode = NSSortDescriptor(key: "sortByCode", ascending: true)
//    let sortByTeacher = NSSortDescriptor(key: "sortByTeacher", ascending: true)
//    let sortByScore = NSSortDescriptor(key: "sortByScore", ascending: true)
//    let sortByPoint = NSSortDescriptor(key: "sortByPoint", ascending: true)

    func sortArray(_ sortKey: String, _ isAscend: Bool) {
        if scoreList.count <= 1 {
            return
        }
        switch sortKey {
        case "sortByName":
            func titleSorter(p1: NGScore?, p2: NGScore?) -> Bool {
                if p1?.courseName == nil {
                    return p2?.courseName == nil
                }
                if p2?.courseName == nil {
                    return p1?.courseName != nil
                }
                return (p1?.courseName!.compare(p2!.courseName!) == ComparisonResult.orderedAscending) == isAscend
            }
            scoreList.sort(by: titleSorter)
            tableView.reloadData()
            break
        case "sortByCode":
            func codeSorter(p1: NGScore?, p2: NGScore?) -> Bool {
                if p1?.courseCode == nil {
                    return p2?.courseCode == nil
                }
                if p2?.courseCode == nil {
                    return p1?.courseCode != nil
                }
                return (p1?.courseCode!.compare(p2!.courseCode!) == ComparisonResult.orderedDescending) == isAscend
            }
            scoreList.sort(by: codeSorter)
            tableView.reloadData()
            break
        case "sortByTeacher":
            func teacherSorter(p1: NGScore?, p2: NGScore?) -> Bool {
                if p1?.teacher == nil {
                    return p2?.teacher == nil
                }
                if p2?.teacher == nil {
                    return p1?.teacher != nil
                }
                return (p1?.teacher!.compare(p2!.teacher!) == ComparisonResult.orderedAscending) == isAscend
            }
            scoreList.sort(by: teacherSorter)
            tableView.reloadData()
            break
        case "sortByScore":
            func scoreSorter(p1: NGScore?, p2: NGScore?) -> Bool {
                if p1?.finalScore == nil {
                    return p2?.finalScore == nil
                }
                if p2?.finalScore == nil {
                    return p1?.finalScore != nil
                }
                return ((p1?.finalScore ?? 0) > (p2?.finalScore ?? 0)) == isAscend
            }
            scoreList.sort(by: scoreSorter)
            tableView.reloadData()
            break
        case "sortByPoint":
            func pointSorter(p1: NGScore?, p2: NGScore?) -> Bool {
                if p1?.scorePoint == nil {
                    return p2?.scorePoint == nil
                }
                if p2?.scorePoint == nil {
                    return p1?.scorePoint != nil
                }
                return (p1?.scorePoint ?? 0.0 > p2?.scorePoint ?? 0.0) == isAscend
            }
            scoreList.sort(by: pointSorter)
            tableView.reloadData()
            break
        case "badSortArgument":
            showErrorMessageNormal(errorMsg: "排序参数出错。")
            break
        default:
            break
        }
    }

    @objc func tableViewDoubleClick(_ sender: AnyObject) {
        if tableView.selectedRow < 0 || tableView.selectedRow >= scoreList.count {
            return
        }
        let scoreObject = scoreList[tableView.selectedRow]
        InspectorKits.showProperties(properties: [
            Property(name: "课程代码", value: scoreObject.courseCode ?? "N/A"),
            Property(name: "课程名称", value: scoreObject.courseName ?? "N/A"),
            Property(name: "课程教师", value: scoreObject.teacher ?? "N/A"),
            Property(name: "学分", value: String(format: "%.1f", scoreObject.credit ?? 0.0)),
            Property(name: "最终成绩", value: "\(scoreObject.finalScore ?? 0)"),
            Property(name: "绩点", value: String(format: "%.1f", scoreObject.scorePoint ?? 0.0)),
            Property(name: "考试性质", value: scoreObject.status ?? "N/A"),
        ])
    }

    // MARK: - NSTableViewDelegate and NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return scoreList.count
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        //        NSLog(sortDescriptor.key ?? "badSortArgument")
        //        NSLog("now ascending == \(sortDescriptor.ascending)")
        sortArray(sortDescriptor.key ?? "badSortArgument", !sortDescriptor.ascending)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row >= scoreList.count {
            return nil
        }

        var text: String = ""
        var cellIdentifier: String = ""

        let item = scoreList[row]

        if tableColumn == tableView.tableColumns[0] {
            text = item.courseName ?? "课程名称"
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.courseCode ?? "课号"
            cellIdentifier = CellIdentifiers.CodeCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = item.teacher ?? "教师"
            cellIdentifier = CellIdentifiers.TeacherCell
        } else if tableColumn == tableView.tableColumns[3] {
            text = "\(item.finalScore ?? 0)"
            cellIdentifier = CellIdentifiers.ScoreCell
        } else if tableColumn == tableView.tableColumns[4] {
            text = String(format: "%.1f", item.scorePoint ?? "0.0")
            cellIdentifier = CellIdentifiers.PointCell
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }

    let addMyPopover = NSPopover()

    @IBAction func clickExportButton(_ sender: NSButton) {
        if scoreList.count == 0 {
            return
        }

        let popOverController = ExportFormatSelector()
        popOverController.delegate = self
        addMyPopover.behavior = .transient
        addMyPopover.contentViewController = popOverController
        addMyPopover.contentSize = CGSize(width: 250, height: 140)
        addMyPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.minY)
    }

    func exportPlainText() {
        let csv = try! CSVWriter(stream: .toMemory())

        try! csv.write(row: ["绩点", "教师", "课程代码", "课程名称", "考试状态", "最终成绩", "学分"])

        for score in scoreList {
            try! csv.write(row: [String(format: "%.1f", score.scorePoint ?? 0.0),
                                 (score.teacher ?? "N/A").replacingOccurrences(of: "、", with: " "),
                                 score.courseCode ?? "N/A",
                                 score.courseName ?? "N/A",
                                 score.status ?? "N/A",
                                 "\(score.finalScore ?? 0)",
                                 String(format: "%.1f", score.credit ?? 0.0)])
        }
        csv.stream.close()
        let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
        let textString = String(data: csvData, encoding: .utf8)!

        let panel = NSSavePanel()
        panel.title = "保存 CSV 格式成绩单"
        panel.message = "请选择 CSV 格式成绩单的保存路径。"

        panel.nameFieldStringValue = "Transcript"
        panel.allowsOtherFileTypes = false
        panel.allowedFileTypes = ["csv", "txt"]
        panel.isExtensionHidden = false
        panel.canCreateDirectories = true

        panel.beginSheetModal(for: view.window!, completionHandler: { result in
            do {
                if result == NSApplication.ModalResponse.OK {
                    if let path = panel.url?.path {
                        try textString.write(toFile: path, atomically: true, encoding: .utf8)
                        self.showInformativeMessage(infoMsg: "已经成功导出 CSV 格式成绩单。")
                    } else {
                        return
                    }
                }
            } catch {
                self.showErrorMessageNormal(errorMsg: "无法导出 CSV 格式成绩单。")
            }
        })
    }

    func exportJSONFormat() {
        addMyPopover.performClose(self)
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(scoreList)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            let panel = NSSavePanel()
            panel.title = "保存 JSON"
            panel.message = "请选择 JSON 文稿的保存路径。"

            panel.nameFieldStringValue = "Transcript"
            panel.allowsOtherFileTypes = false
            panel.allowedFileTypes = ["json"]
            panel.isExtensionHidden = false
            panel.canCreateDirectories = true

            panel.beginSheetModal(for: view.window!, completionHandler: { result in
                do {
                    if result == NSApplication.ModalResponse.OK {
                        if let path = panel.url?.path {
                            try jsonString?.write(toFile: path, atomically: true, encoding: .utf8)
                            self.showInformativeMessage(infoMsg: "已经成功导出 JSON 格式成绩单。")
                        } else {
                            return
                        }
                    }
                } catch {
                    self.showErrorMessageNormal(errorMsg: "无法导出 JSON 表示的成绩单。")
                }
            })
        } catch {
            showErrorMessageNormal(errorMsg: "无法导出 JSON 表示的成绩单。")
        }
    }
}
