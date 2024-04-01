import QtQuick 2.15
import QtGraphicalEffects 1.0

import UI 1.0 as UI
import Api 1.0 as Api

Rectangle {
    height: 120
    property string icon: ""
    property string serviceName: ""
    property string price: ""
    property string discount: ""
    property string btnColor: ""
    property string btnTxt: ""
    property string btnTextColor: ""
    property string intro: ""
    property bool discountVisible: false

    signal detailsBtnClicked()
    signal buyBtnClicked()

    Item {
        id: serviceImage
        width: 50
        height: 50
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 14

        OpacityMask {
            anchors.fill: parent
            anchors.left: parent.left
            source: Image {
                anchors.fill: parent
                sourceSize: Qt.size(40, 40)
                source: icon
            }
            maskSource: Rectangle {
                width: serviceImage.width
                height: serviceImage.height
                radius: serviceImage.height / 2
                color: "lightgreen"
            }
        }
    }

    Text {
        id: serviceNameText
        anchors.top: serviceImage.top
        anchors.topMargin: 8
        anchors.left: serviceImage.right
        anchors.leftMargin: 10
        width: parent.width - serviceImage.width
        elide: Text.ElideRight
        font.pixelSize: 14
        text: serviceName
    }

    Text {
        id: servicePrice
        anchors.left: serviceNameText.left
        anchors.top: serviceNameText.bottom
        anchors.topMargin: 10
        width: serviceNameText.width
        height: 11
        elide: Text.ElideRight
        font.pixelSize: 12
        color: "blue"
        text: price
    }

    Text {
        id: discountText
        anchors.top: serviceNameText.bottom
        anchors.topMargin: 11
        anchors.left: servicePrice.left
        anchors.leftMargin: 70
        font.pixelSize: 12
        color: "#777"
        visible: discountVisible
        text: qsTr("Red envelopes can be deducted ¥") + discount
    }

    Rectangle {
        id: btnText
        anchors.top: serviceImage.top
        anchors.topMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 16
        width: 60
        height: 30
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: btnColor
            radius: width / 2
            border.width: 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 12
                text: btnTxt
                color: btnTextColor
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: {
                detailsBtnClicked()
                buyBtnClicked()
            }
        }
    }

    Text {
        id: introductionMsg
        anchors.top: btnText.bottom
        anchors.topMargin: 30
        anchors.left: parent.left
        anchors.leftMargin: 15
        width: parent.width - 30
        height: 30
        color: "#777"
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        font.pixelSize: 12
        text: intro
    }
}
