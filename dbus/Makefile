INSTALLMAN1DIR = /usr/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLMAN3DIR = /usr/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLMAN5DIR = /usr/man/man5
DESTINSTALLMAN5DIR = $(DESTDIR)$(INSTALLMAN5DIR)
INSTALLMAN7DIR = /usr/man/man7
DESTINSTALLMAN7DIR = $(DESTDIR)$(INSTALLMAN7DIR)
INSTALLMAN8DIR = /usr/man/man8
DESTINSTALLMAN8DIR = $(DESTDIR)$(INSTALLMAN8DIR)

PERM_RW = 644
PERLRUN = /usr/bin/perl
POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)
NOECHO = @

all:
	echo "Nothing to do"

clean:
	echo "Nothing to do"

install:
	mkdir -p $(DESTINSTALLMAN1DIR)
	mkdir -p $(DESTINSTALLMAN7DIR)
	mkdir -p $(DESTDIR)/usr/share/dbus-1/system-services
	mkdir -p $(DESTDIR)/usr/share/polkit-1/actions
	mkdir -p $(DESTDIR)/etc/dbus-1/system.d
	mkdir -p $(DESTDIR)/usr/libexec/slackman
	mkdir -p $(DESTDIR)/usr/share/applications
	mkdir -p $(DESTDIR)/usr/share/slackman
	$(POD2MAN) --section 1 --perm_rw=$(PERM_RW) -u \
	  slackman-notifier $(DESTINSTALLMAN1DIR)/slackman-notifier.1
	$(POD2MAN) --section 1 --perm_rw=$(PERM_RW) -u \
	  slackman-service $(DESTINSTALLMAN1DIR)/slackman-service.1
	$(POD2MAN) --section 7 --perm_rw=$(PERM_RW) -u \
	  org.lotarproject.SlackMan.7.pod $(DESTINSTALLMAN7DIR)/org.lotarproject.SlackMan.7
	install -m 644 org.lotarproject.SlackMan.service $(DESTDIR)/usr/share/dbus-1/system-services
	install -m 644 org.lotarproject.SlackMan.conf $(DESTDIR)/etc/dbus-1/system.d
	install -m 644 org.lotarproject.SlackMan.policy $(DESTDIR)/usr/share/polkit-1/actions
	install -m 755 slackman-service $(DESTDIR)/usr/libexec/slackman
	install -m 755 slackman-notifier $(DESTDIR)/usr/libexec/slackman
	install -m 644 slackman-notifier.desktop $(DESTDIR)/usr/share/applications
	install -m 644 slackware.png $(DESTDIR)/usr/share/slackman
	install -m 755 dbus-pkgtools $(DESTDIR)/usr/share/slackman

