class QtApp : public QObject
{
    Q_OBJECT

public:
    explicit QtApp(QObject *parent = nullptr);
    ~QtApp();

public slots:
    void popPage();
    void afterInit();

signals:
    void goBack();
    void callPopPage();
    void closeWebPage();
};
