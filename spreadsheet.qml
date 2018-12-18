#!/usr/bin/env -S qml -apptype widget
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
            model: table.model.width
            Rectangle {
                color: "#88A"
                width: splitter.x + 6; height: 20

                Text {
                    anchors.centerIn: parent
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
        property real rowHeight: (table.contentHeight - table.rowSpacing * table.model.rowCount() + 2) / table.model.rowCount()
        Repeater {
            model: table.model.height
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

        model: TableModel {
            /*
            // Some demo data
            // In real life we don't hard-code this in QML, but rather load a file of some sort.
            rows: [
                [
                    // Each object (line) is one cell/column,
                    // and each property in that object is a role.
                    // Alternatively, there can be simply a value (for DisplayRole) in some cells.
                    "Flytoget",
                    { date: "2018/11/05" },
                    { display: 190, format: "currency" },
                    "NOK",
                    1,
                    { formula: "* C0 E0" }
                ],
                [
                    "Flight (Berlin)",
                    { date: "2018/11/05" },
                    { currency: 2350 },
                    "NOK",
                    1,
                    { formula: "* C1 E1" }
                ],
                [
                    "Lunch",
                    { date: "2018/11/05" },
                    { currency: 14 },
                    "EUR",
                    9.79,
                    { formula: "* C2 E2" }
                ],
                [
                    "Taxi",
                    { date: "2018/11/05" },
                    { currency: 30 },
                    "EUR",
                    9.79,
                    { formula: "* C3 E3" }
                ],
                [
                    "Hotel",
                    { date: "2018/11/05" },
                    { currency: 1500 },
                    "EUR",
                    9.79,
                    { formula: "* C4 E4" }
                ],
                [
                    "Flight (Boston)",
                    { date: "2018/11/12" },
                    { currency: 800 },
                    "EUR",
                    1,
                    { formula: "* C5 E5" }
                ],
                [
                    "Hotel",
                    { date: "2018/11/12" },
                    { currency: 500 },
                    "USD",
                    8,
                    { formula: "* C6 E6" }
                ],
                [
                    "Flight (Oslo)",
                    { date: "2018/11/15" },
                    { currency: 1700 },
                    "NOK",
                    1,
                    { formula: "* C7 E7" }
                ],
            ]
            */
        }

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
            states: [
                State {
                    name: "editing"
                    PropertyChanges { target: stringText; visible: false }
                    PropertyChanges { target: editor; visible: true }
                }
            ]
            Text {
                x: 2; y: (parent.height - height) / 2
                id: stringText
//                text: model.formula !== undefined ? "formula" : model.display // TODO calculate the formula
                text: model.display
                width: parent.width - 4
                elide: Text.ElideRight
                font.preferShaping: false
            }
            TextField {
                id: editor
                text: model.display
                anchors.fill: parent
                visible: false
                onEditingFinished: {
                    model.display = text
                    delegate.state = ""
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
        nameFilters: ["CSV files (*.csv)", "MD files (*.md *.mkd)"]
        onAccepted: load(file)
    }

    Platform.FileDialog {
        id: saveDialog
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["CSV files (*.csv)", "JSON files (*.json)", "MD files (*.md *.mkd)"]
        onAccepted: save(file)
    }

    TableSerializer {
        id: tableSerializer
    }

    Component {
        id: tableModelFactory
        TableModel { }
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
        if (file.toString().endsWith(".csv"))
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
        if (filename.endsWith(".csv"))
            tableSerializer.saveCsv(table.model, file);
        else if (filename.endsWith(".json"))
            tableSerializer.saveJson(table.model, file);
            //tableSerializer.saveJson(table.model, file, TableSerializer.DisplayStringArrays);
            //tableSerializer.saveJson(table.model, file, TableSerializer.ObjectArrays);
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
}
