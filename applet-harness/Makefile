# Builds the committed slime-harness.jar (end users have no compiler, so the
# jar ships prebuilt in each game payload). Authoring machine needs any JDK
# with --release 8 support; the runtime is the ari-flash-jre Temurin 17 JRE.
#
# Override the toolchain, e.g.:
#   make JAVAC=/path/to/jdk/bin/javac JAVA=/path/to/jre/bin/java verify
JAVAC ?= javac
JAVA  ?= java
JAR   ?= jar

GAMES = ../games/slime-soccer/game ../games/slime-volleyball-2p/game

.PHONY: all verify sync clean

all: slime-harness.jar

slime-harness.jar: SlimeRunner.java
	$(JAVAC) --release 8 SlimeRunner.java
	$(JAR) cfe slime-harness.jar SlimeRunner SlimeRunner*.class

# Headless checks only — never opens a window:
#  1. the shipped class file targets major version 52 (Java 8), and
#  2. each game's applet class resolves against the jar + payload dir.
verify: slime-harness.jar
	@major=$$(unzip -p slime-harness.jar SlimeRunner.class | od -An -j6 -N2 -tx1 | tr -d ' '); \
	if [ "$$major" != "0034" ]; then \
	  echo "FAIL: SlimeRunner.class major version $$major != 0034 (Java 8)"; exit 1; \
	fi; \
	echo "class file major version OK (52 / Java 8)"
	@for dir in $(GAMES); do \
	  cls=$$(sed -n 's/^class=//p' "$$dir/applet.conf"); \
	  if [ -z "$$cls" ]; then echo "FAIL: no class= in $$dir/applet.conf"; exit 1; fi; \
	  out=$$($(JAVA) -Djava.awt.headless=true -cp "slime-harness.jar:$$dir" \
	      SlimeRunner --mode resolve --class "$$cls") || exit 1; \
	  echo "$$out" | grep -q '^resolve OK' || { echo "FAIL: $$dir: $$out"; exit 1; }; \
	  echo "$$dir: $$out"; \
	done

# Copy the built jar into every game payload (the release tarballs ship the
# payload dirs, not applet-harness/).
sync: slime-harness.jar
	@for dir in $(GAMES); do \
	  cp slime-harness.jar "$$dir/slime-harness.jar"; \
	  echo "synced -> $$dir/slime-harness.jar"; \
	done

clean:
	rm -f SlimeRunner*.class
