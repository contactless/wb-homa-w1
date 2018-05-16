ifeq ($(DEB_TARGET_ARCH),armel)
CROSS_COMPILE=arm-linux-gnueabi-
endif

CXX=$(CROSS_COMPILE)g++
CXX_PATH := $(shell which $(CROSS_COMPILE)g++-4.7)

CC=$(CROSS_COMPILE)gcc
CC_PATH := $(shell which $(CROSS_COMPILE)gcc-4.7)

ifneq ($(CXX_PATH),)
	CXX=$(CROSS_COMPILE)g++-4.7
endif

ifneq ($(CC_PATH),)
	CC=$(CROSS_COMPILE)gcc-4.7
endif

CFLAGS=-Wall -std=c++0x -Os -I.

W1_SOURCES= 					\
			sysfs_w1.cpp		\
			onewire_driver.cpp 	\
			exceptions.cpp		\
			log.cpp				\

W1_OBJECTS=$(W1_SOURCES:.cpp=.o)
W1_BIN=wb-homa-w1
W1_LIBS= -lwbmqtt1 -lpthread

W1_TEST_SOURCES= 							\
			$(TEST_DIR)/test_main.cpp		\
			$(TEST_DIR)/sysfs_w1_test.cpp	\
    		$(TEST_DIR)/onewire_driver_test.cpp	\
			
TEST_DIR=test
export TEST_DIR_ABS = $(shell pwd)/$(TEST_DIR)

W1_TEST_OBJECTS=$(W1_TEST_SOURCES:.cpp=.o)
TEST_BIN=wb-homa-w1-test
TEST_LIBS=-lgtest -lwbmqtt_test_utils



all : $(W1_BIN)

# W1
%.o : %.cpp
	${CXX} -c $< -o $@ ${CFLAGS}

$(W1_BIN) : main.o $(W1_OBJECTS)
	${CXX} $^ ${W1_LIBS} -o $@

$(TEST_DIR)/$(TEST_BIN): $(W1_OBJECTS) $(W1_TEST_OBJECTS)
	${CXX} $^ $(W1_LIBS) $(TEST_LIBS) -o $@

test: $(TEST_DIR)/$(TEST_BIN)

	rm -f $(TEST_DIR)/*.dat.out
	if [ "$(shell arch)" = "armv7l" ]; then \
          $(TEST_DIR)/$(TEST_BIN) $(TEST_ARGS) || $(TEST_DIR)/abt.sh show; \
        else \
          valgrind --error-exitcode=180 -q $(TEST_DIR)/$(TEST_BIN) $(TEST_ARGS) || \
            if [ $$? = 180 ]; then \
              echo "*** VALGRIND DETECTED ERRORS ***" 1>& 2; \
              exit 1; \
            else $(TEST_DIR)/abt.sh show; exit 1; fi; \
        fi
clean :
	-rm -f *.o $(W1_BIN)
	-rm -f $(TEST_DIR)/*.o $(TEST_DIR)/$(TEST_BIN)


install: all
	install -d $(DESTDIR)
	install -d $(DESTDIR)/etc
	install -d $(DESTDIR)/usr/bin
	install -d $(DESTDIR)/usr/lib
	install -d $(DESTDIR)/var/lib/wb-homa-w1

	install -m 0755  $(W1_BIN) $(DESTDIR)/usr/bin/$(W1_BIN)
