#ifndef WEBSOCKETSERVER_H
#define WEBSOCKETSERVER_H

#include "../native/Native_iOS.h"

#include <QObject>
#include <QQmlParserStatus>
#include <QtWebSockets/QWebSocketServer>
#include <QQmlEngine>

class WebSocketServer : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    QML_ELEMENT
    Q_DISABLE_COPY(WebSocketServer)
    Q_INTERFACES(QQmlParserStatus)

public:
    explicit WebSocketServer(QObject *parent = nullptr);
    WebSocketServer(WebSocketServer &&) = delete;
    WebSocketServer &operator=(WebSocketServer &&) = delete;
    ~WebSocketServer() override;

    void classBegin() override;
    void componentComplete() override;

    void init();
    void setPort(int newPort);
    void start();
    void stop();
    void newConnection();

signals:
    void newConnect(QWebSocket *client);

private:
    QSslConfiguration sslConfiguration();
    void updateListening();

private:
    QScopedPointer<QWebSocketServer> m_server;
    QString m_host;
    int m_port;
    QString m_cert;
    QString m_privateKey;
};

#endif // WEBSOCKETSERVER_H
