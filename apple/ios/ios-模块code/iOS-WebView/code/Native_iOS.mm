#import "Native_iOS.h"

QtApp::QtApp(QObject *parent) : QObject(parent)
{
    connect(this, &QtApp::callPopPage, this, &QtApp::closeWebPage, Qt::QueuedConnection);
}

QtApp::~QtApp()
{
}

void QtApp::popPage()
{
    emit callPopPage();
}

void QtApp::afterInit()
{
}
