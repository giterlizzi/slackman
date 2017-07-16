all:
	echo "Nothing to do"

clean:
	echo "Nothing to do"

install:
	mkdir -p $(DESTDIR)/usr/share/dbus-1/system-services
	mkdir -p $(DESTDIR)/etc/dbus-1/system.d
	mkdir -p $(DESTDIR)/usr/libexec/slackman
	mkdir -p $(DESTDIR)/usr/share/applications
	install -m 644 org.lotarproject.slackman.service $(DESTDIR)/usr/share/dbus-1/system-services/org.lotarproject.slackman.service
	install -m 644 org.lotarproject.slackman.conf $(DESTDIR)/etc/dbus-1/system.d/org.lotarproject.slackman.conf
	install -m 755 slackman-service $(DESTDIR)/usr/libexec/slackman/slackman-service
	install -m 755 slackman-notifier $(DESTDIR)/usr/libexec/slackman/slackman-notifier
	install -m 644 slackman-notifier.desktop $(DESTDIR)/usr/share/applications
