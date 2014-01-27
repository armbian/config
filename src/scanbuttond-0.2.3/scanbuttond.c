// scanbuttond.c: the actual daemon ("frontend")
// This file is part of scanbuttond.
// Copyleft )c( 2004-2006 by Bernhard Stiftner
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; either version 2 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#include <sys/stat.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <syslog.h>
#include <errno.h>
#include <getopt.h>
#include "scanbuttond/config.h"
#include "scanbuttond/common.h"
#include "scanbuttond/scanbuttond.h"
#include "scanbuttond/loader.h"

#define DEF_BACKEND_FILENAME		STRINGIFY(LIB_DIR) "/libscanbtnd-backend_meta.so"
#define DEF_BUTTONPRESSED_SCRIPT	STRINGIFY(CFG_DIR) "/buttonpressed.sh"
#define DEF_INITSCANNER_SCRIPT		STRINGIFY(CFG_DIR) "/initscanner.sh"
#define DEF_POLL_DELAY			333000L
#define MIN_POLL_DELAY			1000L
#define DEF_RETRY_DELAY			2000000L
#define MIN_RETRY_DELAY			10000L
#define BUF_SIZE			256

static char* connection_names[NUM_CONNECTIONS] =
{ "none", "libusb" };


static struct option const long_opts[] = {
	{"foreground", no_argument, NULL, 'f'},
	{"backend", required_argument, NULL, 'b'},
	{"buttonscript", required_argument, NULL, 's'},
	{"initscript", required_argument, NULL, 'S'},
	{"pollingdelay", required_argument, NULL, 'p'},
	{"retrydelay", required_argument, NULL, 'r'},
	{"help", no_argument, NULL, 'h'},
	{"version", no_argument, NULL, 'v'},
	{NULL, 0, NULL, 0}
};


char* buttonpressed_script;
char* initscanner_script;
char* backend_filename;
backend_t* backend;
long poll_delay;
long retry_delay;
int daemonize;
int killed = 0;
char* path;


char* scanbtnd_get_connection_name(int connection)
{
	return connection_names[connection];
}


void shutdown(void)
{
	syslog(LOG_INFO, "shutting down...");
	backend->scanbtnd_exit();
	unload_backend(backend);
	syslog(LOG_DEBUG, "shutdown complete");
	closelog();
}


// Ensures a graceful exit on SIGHUP/SIGTERM/SIGINT/SIGSEGV
void sighandler(int i)
{
	killed = 1;
	syslog(LOG_INFO, "received signal %d", i);
	shutdown();
	exit(i == SIGTERM ? EXIT_SUCCESS : EXIT_FAILURE);
}


// Executes an external program and wait until it terminates
void execute_and_wait(const char* program)
{
	system(program);
}


void list_devices(scanner_t* devices)
{
	scanner_t* dev = devices;
	while (dev != NULL) {
		syslog(LOG_INFO, "found scanner: vendor=\"%s\", product=\"%s\", connection=\"%s\", sane_name=\"%s\"",
			   dev->vendor, dev->product, scanbtnd_get_connection_name(dev->connection),
			   backend->scanbtnd_get_sane_device_descriptor(dev));
		dev = dev->next;
	}
}


void show_version(void)
{
	printf("This is scanbuttond, version %s\n", VERSION);
	printf("Copyleft )c( 2004-2006 by Bernhard Stiftner and contributors.\n");
	printf("Scanbuttond comes with ABSOLUTELY NO WARRANTY!\n");
	printf("This is free software, and you are welcome to redistribute it\n");
	printf("under certain conditions; see the file COPYING for details.\n");
}


void show_usage(void)
{
	printf("Usage: scanbuttond [OPTION]...\n\n");
	printf("Starts a script when a button on a scanner has been pressed.\n\n");
	printf("Options:\n");
	printf("  -f, --foreground            Run in foreground instead of background\n");
	printf("  -b, --backend=FILE          Use the specified backend library file\n");
	printf("                              default: %s\n", DEF_BACKEND_FILENAME);
	printf("  -s, --buttonscript=SCRIPT   The name of the script to be run when a button has been pressed\n");
	printf("                              default: %s\n", DEF_BUTTONPRESSED_SCRIPT);
	printf("  -S, --initscript=SCRIPT     The name of the script to be run to initialize the scanners\n");
	printf("                              default: %s\n", DEF_INITSCANNER_SCRIPT);
	printf("  -p, --pollingdelay=DELAY    The polling delay (ms), default: %ld\n", DEF_POLL_DELAY);
	printf("  -r, --retrydelay=DELAY      The retry delay (ms), default: %ld\n", DEF_RETRY_DELAY);
	printf("  -h, --help                  Shows this screen\n");
	printf("  -v, --version               Shows the version\n");
}


void process_options(int argc, char** argv)
{
	int c;

	buttonpressed_script = NULL;
	initscanner_script = NULL;
	poll_delay = -1;
	retry_delay = -1;
	daemonize = 1;

	while ((c = getopt_long (argc, argv, "fb:s:S:p:r:hv", long_opts, NULL)) != -1) {
		switch (c) {
			case 'f':
				daemonize = 0;
				break;
			case 'b':
				backend_filename = optarg;
				break;
			case 's':
				buttonpressed_script = optarg;
				break;
			case 'S':
				initscanner_script = optarg;
				break;
			case 'p':
				poll_delay = atol(optarg);
				if (poll_delay < MIN_POLL_DELAY) {
					printf("Invalid polling delay (%ld). Must be at least %ld.\n",
						   poll_delay, MIN_POLL_DELAY);
					exit(EXIT_FAILURE);
				}
				break;
			case 'r':
				retry_delay = atol(optarg);
				if (retry_delay < MIN_RETRY_DELAY) {
					printf("Invalid retry delay (%ld). Must be at least %ld.\n",
						   retry_delay, MIN_RETRY_DELAY);
					exit(EXIT_FAILURE);
				}
				break;
			case 'h':
				show_usage();
				exit(EXIT_SUCCESS);
				break;
			case 'v':
				show_version();
				exit(EXIT_SUCCESS);
				break;
		}
	}

	if (backend_filename == NULL)
		backend_filename = DEF_BACKEND_FILENAME;
	if (buttonpressed_script == NULL)
		buttonpressed_script = DEF_BUTTONPRESSED_SCRIPT;
	if (initscanner_script == NULL)
		initscanner_script = DEF_INITSCANNER_SCRIPT;
	if (poll_delay == -1)
		poll_delay = DEF_POLL_DELAY;
	if (retry_delay == -1)
		retry_delay = DEF_RETRY_DELAY;
}


int main(int argc, char** argv)
{
	int button;
	int result;
	pid_t pid, sid;
	scanner_t* scanners;
	scanner_t* scanner;

	process_options(argc, argv);

	backend = load_backend(backend_filename);
	if (!backend) {
		printf("Unable to load backend library \"%s\"!\n", backend_filename);
		exit(EXIT_FAILURE);
	}

	// daemonize
	if (daemonize) {
		pid = fork();
		if (pid < 0) {
			printf("Can't fork!\n");
			exit(EXIT_FAILURE);
		} else if (pid > 0) {
			exit(EXIT_SUCCESS);
		}
	}

	umask(0);

	openlog(NULL, 0, LOG_DAEMON);

	// create a new session for the child process
	if (daemonize) {
		sid = setsid();
		if (sid < 0) {
			syslog(LOG_ERR, "Could not create a new SID! Terminating.");
			exit(EXIT_FAILURE);
		}
	}

	// Change the current working directory
	if ((chdir("/")) < 0) {
		syslog(LOG_WARNING, "Could not chdir to /. Hmmm, strange... "\
				"Trying to continue.");
	}

	// close standard file descriptors
	if (daemonize) {
		close(STDIN_FILENO);
		close(STDOUT_FILENO);
		close(STDERR_FILENO);
	}

	// setup the environment
	char* oldpath = getenv("PATH");
	char* dir = dirname(argv[0]);
	path = (char*)malloc(strlen(oldpath) + strlen(dir) + 1);
	strcpy(path, oldpath);
	strcat(path, ":");
	strcat(path, dir);
	setenv("PATH", path, 1);
	free(path);

	syslog(LOG_DEBUG, "running scanner initialization script...");
	execute_and_wait(initscanner_script);
	syslog(LOG_DEBUG, "initialization script executed.");

	if (backend->scanbtnd_init() != 0) {
		syslog(LOG_ERR, "Error initializing backend. Terminating.");
		exit(EXIT_FAILURE);
	}

	scanners = backend->scanbtnd_get_supported_devices();

	if (scanners == NULL) {
		syslog(LOG_WARNING, "no known scanner found yet, " \
				"waiting for device to be attached");
	}

	list_devices(scanners);

	signal(SIGTERM, &sighandler);
	signal(SIGHUP, &sighandler);
	signal(SIGINT, &sighandler);
	signal(SIGSEGV, &sighandler);
	signal(SIGCLD, SIG_IGN);

	syslog(LOG_INFO, "scanbuttond started");

	// main loop
	while (killed == 0) {

		if (scanners == NULL) {
			syslog(LOG_DEBUG, "rescanning devices...");
			backend->scanbtnd_rescan();
			scanners = backend->scanbtnd_get_supported_devices();
			if (scanners == NULL) {
				syslog(LOG_DEBUG, "no supported devices found. rescanning in a few seconds...");
				usleep(retry_delay);
				continue;
			}
			syslog(LOG_DEBUG, "found supported devices. running scanner initialization script...");
			execute_and_wait(initscanner_script);
			syslog(LOG_DEBUG, "initialization script executed.");
			scanners = backend->scanbtnd_get_supported_devices();
			continue;
		}

		scanner = scanners;
		while (scanner != NULL) {
			result = backend->scanbtnd_open(scanner);
			if (result != 0) {
				syslog(LOG_WARNING, "scanbtnd_open failed, error code: %d", result);
				if (result == -ENODEV) {
					// device has been disconnected, force re-scan
					syslog(LOG_INFO, "scanbtnd_open returned -ENODEV, device rescan will be performed");
					scanners = NULL;
					usleep(retry_delay);
					break;
				}
				usleep(retry_delay);
				break;
			}

			button = backend->scanbtnd_get_button(scanner);
			backend->scanbtnd_close(scanner);

			if ((button > 0) && (button != scanner->lastbutton)) {
				syslog(LOG_INFO, "button %d has been pressed.", button);
				scanner->lastbutton = button;
				char cmd[BUF_SIZE];
				snprintf(cmd, BUF_SIZE, "%s %d %s", buttonpressed_script, button,
						 backend->scanbtnd_get_sane_device_descriptor(scanner));
				execute_and_wait(cmd);
			}
			if ((button == 0) && (scanner->lastbutton > 0)) {
				syslog(LOG_INFO, "button %d has been released.", scanner->lastbutton);
				scanner->lastbutton = button;
			}
			scanner = scanner->next;
		}

		usleep(poll_delay);

	}

	syslog(LOG_WARNING, "exited main loop!?!");

	shutdown();
	exit(EXIT_SUCCESS);
}

