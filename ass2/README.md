
# Assignment #2: APKwatcher
Create a version monitor for specific Android APKs, meeting the following requirements:

 - Use apkmirror.com at first, prepare support for others
 - Monitor brawl-stars, prepare support for others
 - Report APK updates including timestamps via E-Mail
 - Create activity log in DB-readable format
 - Schedule polling every 2 hours
 - Deliverables:
	 - Documentation of implementation methods and decision reasoning
	 - A working script
	 
	 
	 
## Implementation methods:
### General environment
The assignment was performed on a VM running CentOS 7, and was written in bash


The reasoning:

While bash is not considered a "sexy" programming language (or a programming language alltogether), as long as there are no performance issues or complex data structures, one may find it extremely flexible with quite a few tricks up it's sleeve, especially when combined with the Linux ecosystem.
For the purpose of this task, it was the easiest and most natural for me, so bash it is :)

### Generic design
I have implemented an `apkwatcher.d` directory where apk config files may be dropped at any time, and will be picked-up at the next apkwatcher run, looping through the APKs defined (one APK per config file)

Each APK has it's own `FEED_SOURCE` and `WATCHER_EMAIL` , making configuration extremely flexible.
For the test, only apkmirror was implemented, but there's a case switch just waiting there for other sources. The code to parse each source is completely independent. 

The APK configuration file also stores the current APK version, and this value is updated after the notifications are sent.

### Handling apkmirror.com
I've used curl (with a fake user-agent header) to pull the HTML pages, and the standard bash/grep/sed/awk/tr bunch to parse them

### Scheduling
Scheduling is done using a cron configuration file which is put in place by the installation script. scheduling may be changed directly at `/etc/crond/apkwatcher`, or at the installation script before running it.

### Sending E-Mails
The script assume a sendmail-compatible E-Mail agent, which can be configured according to the host running the script

### Handling errors
In addition to the default emails sent by cron to the Linux user on errors, the script also notifies the maintainer (configurable) of problems it detects (such as parsing issues, if the source changes it's schema)

### Installation and configuration
The script defaults to be placed at `/opt/apkwatcher`, but it can be easily changed using the install script.
To deploy apkwatcher, verify the configuration params, and then run `install.sh` which will copy files, adjust ownerships and set-up scheduling

**Note**: The user who runs the installation script must have sudo permissions.



## Deliverables

|File            |Description                               |
|----------------|------------------------------------------|
|`README.md`     |This documentation file                   |
|[`apkwatcher.sh`](apkwatcher.sh)   |The monitoring script                |
|[`apkwatcher.conf`](apkwatcher.conf)      |Main configuration file           |
|[`apkwatcher.d/brawl-stars`](apkwatcher.d/brawl-stars)    |APK configuration file|
|[`install.sh`](install.sh)    |Installation script|




## Discussion of alternatives
### Alternative web sources
There are several alternatives available on the web, including the Google play store itself, they are of no significant difference (monitoring-wise)

### RSS feeds
While much easier to parse (see [https://www.apkmirror.com/feed/](https://www.apkmirror.com/feed/)), RSS feeds are limited in their scrollback time, so if the watcher is down for too long, it will skip updated versions when it resumes. Personally, I favor the HTML approach as I would rather fail in parsing and know about it than miss updates and not know about that.

### Twitter and the likes
Twitter feeds could be valid alternatives, as the watcher can keep a marker on the last message it got and resume from there.

### A word about parsing in code
While this is not considered best-practice or mainstream,  I have found it to be extremely effective at non-standard tasks. Just look at the size of the watcher :)
