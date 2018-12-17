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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13
import QtQuick.Window 2.13
import Qt.labs.qmlmodels 1.0
import QtQml.Models 2.13

ApplicationWindow {
    id: window
    width: 800
    height: 800
    visible: true
    color: "#222"

    TableView {
        id: tableView
        anchors.fill: parent
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

        delegate: Rectangle {
//            color: selectionModel.isSelected(modelIndex) ? "lightsteelblue" : "#EEE" // doesn't update
//            color: selectionModel.selectedIndexes.includes(modelIndex) ? "lightsteelblue" : "#EEE"
            function updateColor() {
                color = selectionModel.isSelected(modelIndex) ? "lightsteelblue" : "#EEE"
            }
            implicitHeight: stringText.implicitHeight
            implicitWidth: 100 // for now
            // TableView ought to provide this via the index property already, instead of an int
            property var modelIndex: tableModel.index(row, column)
            Text {
                x: 2
                id: stringText
                text: model.display
                width: parent.width
                elide: Text.ElideRight
                font.preferShaping: false
            }
            TapHandler {
                onTapped: {
                    console.log("tapped " + index + " " + modelIndex)
                    selectionModel.select(tableModel.index(row, column), ItemSelectionModel.ClearAndSelect)
                    updateColor()
                }
            }
        }
    }

    ItemSelectionModel {
        id: selectionModel
        model: tableModel
        onSelectionChanged: {
            console.log("selected " + selected)
            console.log("deselected " + deselected)
            for (var i in selected) {
                console.log("selected " + i) // i is always zero
                for (var j in i)
                    console.log("   selected " + j) // j is always zero
                tableView.itemAtCell(i.column, i.row).updateColor()
            }
            for (var i in deselected)
                console.log("deselected " + i)
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
