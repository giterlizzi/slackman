all:
	echo "Nothing to do"

clean:
	echo "Nothing to do"

install :: bash_completion config cron logrotate repos
	$(NOECHO) $(NOOP)

bash_completion:
	mkdir -p $(DESTDIR)/etc/bash_completion.d
	install -m 644 slackman.bash $(DESTDIR)/etc/bash_completion.d/slackman.bash

cron:
	mkdir -p $(DESTDIR)/etc/cron.daily
	install -m 755 slackman.cron $(DESTDIR)/etc/cron.daily/slackman

config:
	mkdir -p $(DESTDIR)/etc/slackman
	install -m 644 slackman.conf $(DESTDIR)/etc/slackman/slackman.conf
	install -m 644 slackman-cron.conf $(DESTDIR)/etc/slackman/slackman-cron.conf

logrotate:
	mkdir -p $(DESTDIR)/etc/logrotate.d
	install -m 644 slackman.logrotate $(DESTDIR)/etc/logrotate.d/slackman

repos:
	mkdir -p $(DESTDIR)/etc/slackman/repos.d
	cp -a repos.d/* $(DESTDIR)/etc/slackman/repos.d
