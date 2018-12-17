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
            model: table.model.columnCount()
            Rectangle {
                color: "#88A"
                width: 100; height: 20

                Text {
                    anchors.centerIn: parent
                    text: String.fromCharCode(65 + index)
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
            model: table.model.rowCount()
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

        model: TableModel {
            id: tableModel
            rows: [
                [
                    // Each object (line) is one cell/column,
                    // and each property in that object is a role.
                    { text: "Flytoget" },
                    { date: "2018/11/05" },
                    { currency: 190 },
                    { text: "NOK" },
                    { number: 1 },
                    { formula: "* C0 E0" }
                ],
                [
                    { text: "Flight (Berlin)" },
                    { date: "2018/11/05" },
                    { currency: 2350 },
                    { text: "NOK" },
                    { number: 1 },
                    { formula: "* C1 E1" }
                ],
                [
                    { text: "Lunch" },
                    { date: "2018/11/05" },
                    { currency: 14 },
                    { text: "EUR" },
                    { number: 9.79 },
                    { formula: "* C2 E2" }
                ],
                [
                    { text: "Taxi" },
                    { date: "2018/11/05" },
                    { currency: 30 },
                    { text: "EUR" },
                    { number: 9.79 },
                    { formula: "* C3 E3" }
                ],
                [
                    { text: "Hotel" },
                    { date: "2018/11/05" },
                    { currency: 1500 },
                    { text: "EUR" },
                    { number: 9.79 },
                    { formula: "* C4 E4" }
                ],
                [
                    { text: "Flight (Boston)" },
                    { date: "2018/11/12" },
                    { currency: 800 },
                    { text: "EUR" },
                    { number: 1 },
                    { formula: "* C5 E5" }
                ],
                [
                    { text: "Hotel" },
                    { date: "2018/11/12" },
                    { currency: 500 },
                    { text: "USD" },
                    { number: 8 },
                    { formula: "* C6 E6" }
                ],
                [
                    { text: "Flight (Oslo)" },
                    { date: "2018/11/15" },
                    { currency: 1700 },
                    { text: "NOK" },
                    { number: 1 },
                    { formula: "* C7 E7" }
                ],
            ]
        }

        selectionModel: ItemSelectionModel {
            model: tableModel
//            onSelectionChanged: {
//                console.log("selected " + selected)
//                console.log("deselected " + deselected)
//            }
        }

        delegate: Rectangle {
            id: delegate
            // TableView ought to provide this via the index property already, instead of an int
            property var modelIndex: tableModel.index(row, column)
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
                text: model.formula !== undefined ? "formula" : model.display // TODO calculate the formula
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
                        table.selectionModel.select(tableModel.index(row, column), ItemSelectionModel.ClearAndSelect)
                    }
                }
            }
        }
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            Action { text: qsTr("&New...") }
            Action { text: qsTr("&Open...") }
            Action { text: qsTr("&Save") }
            Action { text: qsTr("Save &As...") }
            MenuSeparator { }
            Action { text: qsTr("&Quit") }
        }
        Menu {
            title: qsTr("&Edit")
            Action { text: qsTr("Cu&t") }
            Action { text: qsTr("&Copy") }
            Action { text: qsTr("&Paste") }
        }
        Menu {
            title: qsTr("&Help")
            Action { text: qsTr("&About") }
        }
    }
}
