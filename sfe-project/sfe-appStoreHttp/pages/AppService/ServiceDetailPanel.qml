import QtQuick 2.15
import QtQuick.Controls 2.15

Flickable {
    property string detail: ""
    contentHeight: detailsTxt.height
    clip: true

    Text {
        id: detailsTxt
        width: parent.width - 40
        font.pixelSize: 12
        font.letterSpacing: 1
        lineHeight: 1.5
        wrapMode: Text.Wrap
        text: detail
        textFormat: Text.RichText
        color: "#303030"
        leftPadding: 15
        topPadding: 10
    }
}
