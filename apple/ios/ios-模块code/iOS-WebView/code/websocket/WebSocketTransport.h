#ifndef WEBSOCKETTRANSPORT_H
#define WEBSOCKETTRANSPORT_H

#include <QJsonDocument>
#include <QJsonObject>
#include <QWebChannelAbstractTransport>

class WebSocketTransport : public QWebChannelAbstractTransport
{
    Q_OBJECT

public:
    explicit WebSocketTransport(QObject *parent = nullptr);
    ~WebSocketTransport();
    Q_INVOKABLE void sendMessage(const QJsonObject &message) override;
    Q_INVOKABLE void textMessageReceive(const QString &messageData);

signals:
    void messageChanged(const QString & message);
};

#endif // WEBSOCKETTRANSPORT_H
