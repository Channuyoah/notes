import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    ListView {
        id: listView
        width: parent.width
        height: parent.height
        topMargin: 20
        model: recordModel
        delegate: recordDelegate
        onCountChanged: emptyItem.visible = model.count === 0
    }

    ListModel {
        id: recordModel
    }

    Component {
        id: recordDelegate
        Item {
            width: parent.width
            height: 30

            Text {
                id: serviceType
                anchors.left: parent.left
                leftPadding: 20
                font.pixelSize: 12
                text: name
                color: "#303030"
            }

            Text {
                id: serviceFee
                anchors.left: serviceType.right
                leftPadding: 10
                font.pixelSize: 12
                text: pricy
                color: "#303030"
            }

            Text {
                id: serviceTime
                anchors.right: parent.right
                rightPadding: 20
                font.pixelSize: 12
                text: time
                color: "darkgrey"
            }
        }
    }

    Item {
        id: emptyItem
        width: parent.width
        height: parent.height

        Image {
            id: noData
            anchors.centerIn: parent
            source: $app.asset("images/NoData.png")
            fillMode: Image.PreserveAspectFit
            width: 80
            height: 80
        }

        Text {
            text: qsTr("No Data")
            anchors.top: noData.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 16
            color: "#303030"
        }
    }
}
