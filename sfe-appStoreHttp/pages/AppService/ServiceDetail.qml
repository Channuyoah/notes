import QtQuick 2.15
import QtQuick.Controls 2.15

import UI 1.0 as UI
import ChatEngine 1.0 as CE
import Api 1.0 as Api

Page {
    property string appStoreId: ""
    property string versionId: ""
    property var detailsMsg: ({})

    header: UI.HeadBar{
        id: headBar
        title: qsTr("Service Detials")
        enableBack: true
        onClickBack: popStackPage()
    }

    Component.onCompleted: {
        function success(resp) {
            detailsMsg = resp.result.appstore_detail
            detailTabPage.setDetailIntro(detailsMsg.details)
        }

        function failure() {
            console.log("getServiceDetails Error")
        }

        Api.AppStore.getServiceDetails(appStoreId, versionId, success, failure)
    }

    Rectangle {
        id: serviceType
        width: parent.width
        height: 124

        ServiceListItem {
            width: parent.width
            icon : detailsMsg.logo_url || ""
            serviceName : detailsMsg.app_name || ""
            price : detailsMsg.charge_price || ""
            discount : ""
            btnColor : "blue"
            btnTxt : qsTr("buy")
            btnTextColor : "white"
            intro : detailsMsg.intro || ""
            discountVisible : false

        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                onBuyBtnClicked: {
                    // TODO 调用购买接口
                    $user.appStoreToken = ""
                }
            }
        }
    }

    Rectangle {
        id: divider
        width: parent.width
        height: 10
        anchors.top: serviceType.bottom
        color: "lightgrey"
    }

    Item  {
        id: contentItem
        width: parent.width
        anchors.top: divider.bottom
        anchors.bottom: parent.bottom

        UI.TabPage {
            id: detailTabPage
            anchors.fill: parent
            Component.onCompleted: {
                model.append({
                    label: qsTr("Detials"),
                    badge: CE.ChatEngineQml.seeyard.wait.unread,
                    pageUrl: "qrc:///pages/AppService/ServiceDetailPanel.qml"
                })
                model.append({
                    label: qsTr("BuyRecord"),
                    badge: CE.ChatEngineQml.seeyard.process.unread,
                    pageUrl: "qrc:///pages/AppService/BuyRecord.qml"
                })
            }

            function setDetailIntro(details) {
                if (tabBar.currentIndex !== 0 || !details) {
                    return
                }

                loader.item.detail = details
            }

            onIndexLoaded: setDetailIntro(detailsMsg.details)
        }
    }
}
