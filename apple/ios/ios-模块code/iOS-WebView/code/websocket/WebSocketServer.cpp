#include "WebSocketServer.h"
#include "QtWebSockets/qwebsocket.h"

#include <QFile>
#include <QSsl>
#include <QSslKey>
#include <QSslCertificate>
#include <QWebChannel>

Q_LOGGING_CATEGORY(LOG_SFE_WEBSOCKETSERVER, "sfe-websocketserver", QtWarningMsg);

WebSocketServer::WebSocketServer(QObject *parent)
    : QObject{parent}
    , m_host(QHostAddress(QHostAddress::LocalHost).toString())
    , m_port(19527)
    , m_cert(":/cert/localhost.pem")
    , m_privateKey(":/cert/localhost.key")
{
}

WebSocketServer::~WebSocketServer()
{
}

void WebSocketServer::classBegin()
{
}

void WebSocketServer::componentComplete()
{
}

/*
 * 证书生成命令:
 * openssl req -newkey rsa:2048 -new -nodes -x509 -days 36500 -keyout localhost.key -out localhost.pem
 */
QSslConfiguration WebSocketServer::sslConfiguration()
{
    QSslConfiguration config;
    QFile certFile(m_cert);
    QFile keyFile(m_privateKey);
    certFile.open(QIODevice::ReadOnly);
    keyFile.open(QIODevice::ReadOnly);
    QSslCertificate certificate(&certFile, QSsl::Pem);
    QSslKey sslKey(&keyFile, QSsl::Rsa, QSsl::Pem);
    config.setPeerVerifyMode(QSslSocket::VerifyNone);
    config.setLocalCertificate(certificate);
    config.setPrivateKey(sslKey);
    return config;
}

void WebSocketServer::setPort(int newPort)
{
    if (m_port == newPort)
        return;
    if (newPort < 0 || newPort > 65535) {
        qCDebug(LOG_SFE_WEBSOCKETSERVER, "WebSocketServer newport invalid, It must be in the range 0-65535.");
        return;
    }
    m_port = newPort;
}

void WebSocketServer::start()
{
    if (!m_server) {
        return;
    }

    if (!m_server->isListening()) {
        m_server->close();
    }

    if (!m_server->listen(QHostAddress(m_host), m_port)) {
        return;
    }
}

void WebSocketServer::stop()
{
    m_server->close();
}

void WebSocketServer::init()
{
    // TODO: add support for wss, requires ssl configuration to be set from QML - realistic?
    QWebSocketServer *server = new QWebSocketServer("webpage-ws-server", QWebSocketServer::SecureMode);
    server->setSslConfiguration(sslConfiguration());
    m_server.reset(server);

    connect(m_server.data(), &QWebSocketServer::newConnection,
            this, [this]() {this->newConnection();});
}

void WebSocketServer::newConnection()
{
    QWebSocket *client = m_server->nextPendingConnection();
    if (!client) {
        return;
    }

    emit newConnect(client);
}
