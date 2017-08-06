INSTALLMAN1DIR = /usr/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLMAN3DIR = /usr/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLMAN5DIR = /usr/man/man5
DESTINSTALLMAN5DIR = $(DESTDIR)$(INSTALLMAN5DIR)
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
	mkdir -p $(DESTINSTALLMAN5DIR)
	mkdir -p $(DESTINSTALLMAN8DIR)
	$(POD2MAN) --section 5 --perm_rw=$(PERM_RW) -u \
	  slackman.conf.5.pod $(DESTINSTALLMAN5DIR)/slackman.conf.5 \
	  slackman.repo.5.pod $(DESTINSTALLMAN5DIR)/slackman.repo.5
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u \
	  ../bin/slackman $(DESTINSTALLMAN8DIR)/slackman.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-clean" \
	  ../lib/Slackware/SlackMan/Command/Clean.pm $(DESTINSTALLMAN8DIR)/slackman-clean.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-config" \
	  ../lib/Slackware/SlackMan/Command/Config.pm $(DESTINSTALLMAN8DIR)/slackman-config.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-db" \
	  ../lib/Slackware/SlackMan/Command/DB.pm $(DESTINSTALLMAN8DIR)/slackman-db.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-list" \
	  ../lib/Slackware/SlackMan/Command/List.pm $(DESTINSTALLMAN8DIR)/slackman-list.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-log" \
	  ../lib/Slackware/SlackMan/Command/Log.pm $(DESTINSTALLMAN8DIR)/slackman-log.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-package" \
	  ../lib/Slackware/SlackMan/Command/Package.pm $(DESTINSTALLMAN8DIR)/slackman-package.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-repo" \
	  ../lib/Slackware/SlackMan/Command/Repo.pm $(DESTINSTALLMAN8DIR)/slackman-repo.8
	$(POD2MAN) --section 8 --perm_rw=$(PERM_RW) -u --name="slackman-update" \
	  ../lib/Slackware/SlackMan/Command/Update.pm $(DESTINSTALLMAN8DIR)/slackman-update.8
	( cd $(DESTINSTALLMAN8DIR) ; ln -s slackman-package.8 slackman-install.8   )
	( cd $(DESTINSTALLMAN8DIR) ; ln -s slackman-package.8 slackman-remove.8    )
	( cd $(DESTINSTALLMAN8DIR) ; ln -s slackman-package.8 slackman-upgrade.8   )
	( cd $(DESTINSTALLMAN8DIR) ; ln -s slackman-package.8 slackman-reinstall.8 )
	( cd $(DESTINSTALLMAN8DIR) ; ln -s slackman-package.8 slackman-info.8      )
	( cd $(DESTINSTALLMAN8DIR) ; ln -s slackman-package.8 slackman-changelog.8 )
	( cd $(DESTINSTALLMAN8DIR) ; ln -s slackman-package.8 slackman-history.8   )

