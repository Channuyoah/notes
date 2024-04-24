import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import UI 1.0 as UI
import Api 1.0 as Api

Page {
    visible: true

    header: UI.HeadBar{
        title: qsTr("Service")
        enableBack: true
        onClickBack: popStackPage()
    }

    background: Rectangle {
        color: "#f4f4f4"
    }


    ListModel {
        id: serviceModel
        Component.onCompleted: {
            function success(resp) {
                let response = resp.result.data[0].appstore_data

                for (var i = 0; i < response.length; i++) {
                    serviceModel.append({
                        icon: response[i].logo_url,
                        serviceName: response[i].app_name,
                        price: "",
                        discountVisible: false,
                        btnColor: "#f4f4f4",
                        btnTxt: qsTr("details"),
                        btnTextColor: "blue",
                        intro: response[i].intro,
                        id: response[i].id,
                        version_id: response[i].version_id
                    })
                }
            }

            function failure() {
                console.log("getServiceMsg Error")
            }

            Api.AppStore.getServiceMsg(success, failure)
        }
    }

    ListView {
        model: serviceModel
        anchors.fill: parent
        spacing: 5

        delegate: Component {
            ServiceListItem {
                width: ListView.view.width
                icon: model.icon
                serviceName: model.serviceName
                price: model.price
                btnColor: model.btnColor
                btnTxt: model.btnTxt
                btnTextColor: model.btnTextColor
                intro: model.intro
                discountVisible: false

                onDetailsBtnClicked: {
                    goServiceDetails(model.id, model.version_id)
                }
            }
        }
    }
}
