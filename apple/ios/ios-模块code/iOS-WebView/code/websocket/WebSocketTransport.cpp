#include "WebSocketTransport.h"


WebSocketTransport::WebSocketTransport(QObject *parent)
{
}

WebSocketTransport::~WebSocketTransport()
{
}

void WebSocketTransport::sendMessage(const QJsonObject &message)
{
    QJsonDocument doc(message);
    emit WebSocketTransport::messageChanged(QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}

void WebSocketTransport::textMessageReceive(const QString &messageData)
{
    QJsonParseError error;
    QJsonDocument message = QJsonDocument::fromJson(messageData.toUtf8(), &error);
    if (error.error)
    {
        qWarning() << "Failed to parse text message as JSON object:" << messageData
                   << "Error is:" << error.errorString();
        return;
    }
    else if (!message.isObject())
    {
        qWarning() << "Received JSON message that is not an object: " << messageData;
        return;
    }

    emit WebSocketTransport::messageReceived(message.object(), this);
}
