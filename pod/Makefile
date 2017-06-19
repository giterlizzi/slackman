all:
	echo "Nothing to do"

clean:
	rm -f slackman.conf.5
	rm -r slackman.8

install:
	mkdir -p $(DESTDIR)/usr/man/man5
	mkdir -p $(DESTDIR)/usr/man/man8
	pod2man --section 5 slackman.conf.5.pod > slackman.conf.5
	pod2man --section 8 ../blib/script/slackman > slackman.8
	install -m 644 slackman.8 $(DESTDIR)/usr/man/man8/slackman.8
	install -m 644 slackman.conf.5 $(DESTDIR)/usr/man/man5/slackman.conf.5
