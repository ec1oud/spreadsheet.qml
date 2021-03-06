#!/bin/env -S qml -apptype widget
/*
  Copyright (c) 2018 Shawn Rutledge <s@ecloud.org>
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.13
import QtQuick.Controls 2.5 // 2.13
import QtQuick.Layouts 1.13
import QtQuick.Window 2.13
import Qt.labs.qmlmodels 1.0
import QtQml.Models 2.13
import Qt.labs.platform 1.0 as Platform // requires -apptype widget

ApplicationWindow {
    id: window
    width: 640
    height: 480
    visible: true
    color: "#222"

    Row {
        id: header
        width: table.contentWidth
        height: 20
        spacing: table.columnSpacing
        x: table.originX - table.contentX + rowLabels.width + table.columnSpacing
        z: 1
        Repeater {
            id: headerRepeater
            model: table.model.columnCount
            Rectangle {
                color: "#88A"
                width: splitter.x + 6; height: 20

                Label {
                    anchors.fill: parent
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    property var label: table.model.header[index]
                    text: label !== undefined ? label + " (" + String.fromCharCode(65 + index) + ")" : String.fromCharCode(65 + index)
                }
                Item {
                    id: splitter
                    x: 94
                    width: 12
                    height: parent.height + 10
                    DragHandler {
                        yAxis.enabled: false
                        onActiveChanged: if (!active) table.forceLayout()
                    }
                }
            }
        }
    }

    Column {
        id: rowLabels
        width: 30
        height: table.contentHeight
        spacing: table.rowSpacing
        y: table.originY - table.contentY + header.height + table.rowSpacing
        z: 1
        // TableView ought to provide height of each row somehow, in case there is no rowHeightProvider function
        property real rowHeight: (table.contentHeight - table.rowSpacing * table.model.rowCount + 2) / table.model.rowCount
        Repeater {
            model: table.model.rowCount
            Rectangle {
                color: "#88A"
                width: rowLabels.width; height: rowLabels.rowHeight
                Text {
                    text: index
                    x: parent.width - width - 3
                    y: (parent.height - height) / 2
                }
            }
        }
    }

    function evaluateFormula(f, row) {
        // for use internally here
        function cellRangeRef(f, start = 0) {
            var pat = /([A-Z]+)([0-9]+)..([A-Z]+)([0-9]+)/g
            pat.lastIndex = start
            var match = null
            if (match = pat.exec(f)) {
                match.unshift(pat.lastIndex)
                return match
            }
            return null
        }
        function cellRef(f, start = 0) {
            var pat = /([A-Z]+)([0-9]+)/g
            pat.lastIndex = start
            var match = null
            if (match = pat.exec(f)) {
                match.unshift(pat.lastIndex)
                return match
            }
            return null
        }
        function rewriteCellRefs(f) {
            var fRewrite = f;
            var start = 0;
            var match = null;
            while (match = cellRangeRef(f, start)) {
                var fc1 = match[2].charCodeAt(0) - 65
                var fr1 = match[3]
                var fc2 = match[4].charCodeAt(0) - 65
                var fr2 = match[5]
                fRewrite = fRewrite.replace(match[1], "range(" + [fc1, fr1, fc2, fr2].join(",") + ")")
                start = match[0]
                print(start, f, fc, fr, JSON.stringify(match), fRewrite)
            }
            while (match = cellRef(f, start)) {
                var fc = match[2].charCodeAt(0) - 65
                var fr = match[3]
                fRewrite = fRewrite.replace(match[1], "v(" + fc + ", " + fr + ")")
                // evaluateFormula(table.model.data(table.model.index(fr, fc)), row))
                start = match[0]
//                print(start, f, fc, fr, JSON.stringify(match), fRewrite)
            }
            return fRewrite
        }
        // for use in cell formulas
        function v(c, r) {
            if (r === undefined)
                r = row
            return evaluateFormula(table.model.data(table.model.index(r, c)), r)
        }
        function range(c1, r1, c2, r2) {
            // for now, let's always stay in one column
            console.assert(c1 === c2)
            var ret = []
            var r = 0
            for (r = r1; r <= r2; ++r)
                ret.push(v(c1, r))
            print(c1, r1, r2, ret)
            return ret
        }
        function sum(v) {
            return v.reduce((acc, v) => acc + v)
        }
        var rf = rewriteCellRefs(f)
        var ret = eval(rf)
        print(row, f, rf, ret)
        return ret
    }

    TableView {
        id: table
        anchors.fill: parent
        anchors.topMargin: header.height + rowSpacing
        anchors.leftMargin: rowLabels.width + columnSpacing
        columnSpacing: 2; rowSpacing: 2

        ScrollBar.horizontal: ScrollBar {}
        ScrollBar.vertical: ScrollBar {}

        Layout.minimumHeight: window.height / 2
        Layout.fillWidth: true
        Layout.fillHeight: true

        columnWidthProvider: function(column) { return headerRepeater.itemAt(column).width }

        model: TableModel { }

        selectionModel: ItemSelectionModel {
            model: table.model
        }

        delegate: Rectangle {
            id: delegate
            // TableView ought to provide this via the index property already, instead of an int
            property var modelIndex: table.model.index(row, column)
            // TableView ought to provide a magic property (like column, row and index) called "selected", if a selectionModel is bound
//            color: selected ? "lightsteelblue" : "#EEE"
            color: table.selectionModel.isSelected(modelIndex) ? "lightsteelblue" : "#EEE" // doesn't update without patching
            onColorChanged: if (!table.selectionModel.isSelected(modelIndex)) state = ""
            implicitHeight: editor.implicitHeight
            implicitWidth: 100 // for now
            // a hack because I'm not sure which way to tell TableModel which role to edit
            // so maybe editRoleProvider should return a role rather than a display string,
            // then it can be used symmetrically both for data() and getData()
            property bool hasFormula: formula !== undefined
            states: [
                State {
                    name: "editing"
                    PropertyChanges { target: stringText; visible: false; text: model.display }
                    PropertyChanges { target: editor; visible: true }
                }
            ]
            Label {
                x: 2; y: (parent.height - height) / 2
                id: stringText
                text: model.display
                width: parent.width - 4
                elide: Text.ElideRight
                font.preferShaping: false
            }
            TextField {
                id: editor
                text: model.edit
                anchors.fill: parent
                visible: false
                onEditingFinished: {
                    if (hasFormula)
                        model.formula = text
                    else
                        model.edit = text
                    delegate.state = ""
                    table.forceLayout()
                }
            }
            TapHandler {
                onTapped: {
                    console.log("tapped " + index + " " + modelIndex + " was selected " + table.selectionModel.isSelected(modelIndex))
                    if (delegate.state !== "") {
                        delegate.state = ""
                    } else if (table.selectionModel.isSelected(modelIndex)) {
                        // clicking again after it's already selected goes into edit mode
                        delegate.state = "editing"
                    } else {
                        table.selectionModel.select(table.model.index(row, column), ItemSelectionModel.ClearAndSelect)
                    }
                }
            }
        }
    }

    Platform.FileDialog {
        id: loadDialog
        nameFilters: ["JSON files (*.json)", "CSV files (*.csv)", "MD files (*.md *.mkd)"]
        onAccepted: load(file)
    }

    Platform.FileDialog {
        id: saveDialog
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)", "CSV files (*.csv)", "MD files (*.md *.mkd)"]
        onAccepted: save(file)
    }

    TableSerializer {
        id: tableSerializer
    }

    Component {
        id: tableModelFactory
        TableModel {
            id: tm
            displayRoleProvider: function(row, column, v) {
                var vdata = JSON.parse(v)
                var ret = v
                var val = null
                if (val = vdata["formula"])
                    ret = evaluateFormula(val, row)
                else if (val = vdata["date"])
                    ret = val
                print("displayRoleProvider", row, column, v, ret)
                return ret
            }
            editRoleProvider: function(row, column, v) {
                var vdata = JSON.parse(v)
                var ret = v
                var val = null
                if (val = vdata["formula"])
                    ret = val
                else if (val = vdata["date"])
                    ret = val
                print("editRoleProvider", row, column, v, ret)
                return ret
            }
        }
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            Action { text: qsTr("&New..."); shortcut: StandardKey.New; onTriggered: table.model.clear() }
            Action { text: qsTr("&Open..."); shortcut: StandardKey.Open; onTriggered: loadDialog.open() }
            Action { text: qsTr("Save &As..."); shortcut: StandardKey.Save; onTriggered: saveDialog.open() }
            MenuSeparator { }
            Action { text: qsTr("&Quit"); shortcut: StandardKey.Quit; onTriggered: Qt.quit() }
        }
//        Menu {
//            title: qsTr("&Edit")
//            Action { text: qsTr("Cu&t") }
//            Action { text: qsTr("&Copy") }
//            Action { text: qsTr("&Paste") }
//        }
//        Menu {
//            title: qsTr("&Help")
//            Action { text: qsTr("&About") }
//        }
    }

    function load(file) {
        var parser = null;
        if (file.toString().endsWith(".json"))
            parser = JSON.parse
        else if (file.toString().endsWith(".csv"))
            parser = parseCSV
        else if (file.toString().endsWith(".md") || file.toString().endsWith(".mkd"))
            parser = tableSerializer.parseMarkdown
        if (parser) {
            var request = new XMLHttpRequest()
            request.open('GET', file)
            request.onreadystatechange = function(event) {
                if (request.readyState === XMLHttpRequest.DONE) {
                    var data = parser(request.responseText)
                    var header = data.shift()
                    table.model = tableModelFactory.createObject(table, {"rows": data, "header": header})
                }
            }
            request.send()
        }
    }

    function save(file) {
        var filename = file.toString()
        if (filename.endsWith(".json"))
            tableSerializer.saveJson(table.model, file);
            //tableSerializer.saveJson(table.model, file, TableSerializer.DisplayStringArrays);
            //tableSerializer.saveJson(table.model, file, TableSerializer.ObjectArrays);
        else if (filename.endsWith(".csv"))
            tableSerializer.saveCsv(table.model, file);
        else if (filename.endsWith(".md") || filename.endsWith(".mkd"))
            tableSerializer.saveMarkdown(table.model, file, TextEdit.MarkdownDialectGitHub);
    }

    function parseCSV(strData) {
        var strDelimiter = ",";
        var objPattern = new RegExp( (
                // Delimiters.
                "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +
                // Quoted fields.
                "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
                // Standard fields.
                "([^\"\\" + strDelimiter + "\\r\\n]*))"
            ), "gi" );
        var arrData = [[]];
        var arrMatches = null;
        while (arrMatches = objPattern.exec( strData )){
            var strMatchedDelimiter = arrMatches[ 1 ];
            if (strMatchedDelimiter.length && strMatchedDelimiter !== strDelimiter)
                arrData.push( [] );
            var strMatchedValue;
            if (arrMatches[ 2 ])
                strMatchedValue = arrMatches[ 2 ].replace(new RegExp( "\"\"", "g" ), "\"");
            else
                strMatchedValue = arrMatches[ 3 ];
            // The naive way: make a simple columnar table with no custom roles.
            arrData[ arrData.length - 1 ].push( strMatchedValue );
            // It would alternatively be possible to define roles based on column headings,
            // but TableView does not need it to be done that way (whereas ListView does).
        }
        // remove final row if it's all empty
        if (arrData[arrData.length-1].map(x => x == ""))
            arrData.pop();
        return( arrData );
    }

    Component.onCompleted: {
        if (Qt.application.arguments.length > 2)
            load(Qt.application.arguments[2])
    }
}
