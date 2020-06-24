#pragma once

#include <QObject>
#include <QDebug>
#include <QProcess>

class VolumePeaks : public QObject {
	Q_OBJECT

	Q_PROPERTY(bool peaking READ peaking WRITE setPeaking NOTIFY peakingChanged)
	Q_PROPERTY(int defaultSinkPeak READ defaultSinkPeak WRITE setDefaultSinkPeak NOTIFY defaultSinkPeakChanged)
	Q_PROPERTY(QString peakCommand READ peakCommand WRITE setPeakCommand NOTIFY peakCommandChanged)
	Q_PROPERTY(QStringList peakCommandArgs READ peakCommandArgs WRITE setPeakCommandArgs NOTIFY peakCommandArgsChanged)

public:
	explicit VolumePeaks(QObject *parent = nullptr);
	~VolumePeaks();

	bool peaking() const;
	void setPeaking(bool b);

	int defaultSinkPeak() const;
	void setDefaultSinkPeak(int peak);

	QString peakCommand() const;
	void setPeakCommand(const QString &command);

	QStringList peakCommandArgs() const;
	void setPeakCommandArgs(const QStringList &args);

Q_SIGNALS:
	void peakingChanged() const;
	void defaultSinkPeakChanged() const;
	void peakCommandChanged() const;
	void peakCommandArgsChanged() const;

public slots:
	void readyReadStandardOutput();

private:
	void run();
	void stop();
	void restart();

	QProcess* m_process;

	bool m_peaking;
	int m_defaultSinkPeak;
	QString m_peakCommand;
	QStringList m_peakCommandArgs;
};
