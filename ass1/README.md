# Assignment #1: Kiosk

Achieve a custom Linux O/S tailor-made to serve as a "Kiosk" station, meeting the following requirements:

 - Slim Linux-based O/S, Not Debian/Ubuntu.
 - UI interface running xcalc as the sample kiosk app
 - Nothing else is allowed to run in parallel to the sample app
 - 2FA authentication for operators
 - Full disk encryption
 - Deliverables:
	 - Documentation of implementation methods and decision reasoning
	 - List of removed components from the O/S and kernel
	 - Encrypted VM in a ready state of the final solution
	 - Automation for adding components or changing configurations
	 
## Implementation methods:
### General environment
The assignment was performed on a laptop running Windows 10, using Vagrant, VirtualBox and Cygwin.

The reasoning:

**Windows 10 + VirtualBox**: I already had these running on my laptop.

**Vagrant**: The natural infrastructure for small-scale automation, including a wide range of provisioners and supported languages

**Cygwin**: A proven "linux-like" environment for Windows, used for the encryption and export script. Why not WSL ?  I have no experience with it and due to time constraints I chose the familiar solution

### Slim Linux-based O/S
I chose to use a ready-made [minimal](https://app.vagrantup.com/minimal) CentOS 7 box.
Since one of the requirements was NOT to use Debian/Ubuntu, I went for the other major line of distros, and CentOS is the industry standard distro for this line. There are plenty of specialized distributions out there, but as I am not familiar with them I went for the mainstream. 
The publisher of this particular box specializes in minimal boxes and the number of downloads reflects the community's trust :)

### xcalc and nothing else
As this is a kiosk implementation, I have enforced the single app on the console (tty1) only, so SSH is still possible for maintenance/provisioning/support
The restriction is implemented by adding `/etc/profile.d/kiosk.sh` with code to launch xcalc in a dedicated window (no window managers installed), and if by chance the user breaks away (or the application crashes and exits), the user is immediately logged out. The code for that is:

    tty | grep tty1 >/dev/null && { xinit /usr/bin/xcalc $* -- >/dev/null 2>/dev/null ; logout ; }

### 2FA authentication for operators
2FA is achieved using google-authenticator. Pre-authorized operators are configured on the machine along with they activation key. The same activation key should be used on the phone (or whatever) app to initialize the tokens generator.
The restriction is implemented by adding a  google-auth requirement to `/etc/pam.d/login` and a configuration file for each user with their individual keys.
This restriction was not applied to SSH, as that would break any further automatic provisioning (Sure, finer tuning is possible)

### Full disk encryption
The included [encrypt.sh](encrypt.sh) performs full disk encryption using VirtualBox, however this is not exportable, or even portable to other VirtualBox hosts
There are procedures out there to encrypt an existing Linux machine, but they require an additional temporary disk and are fairly complicated to automate.
The "Proper" approach would be to install a new VM from the O/S's ISO image(s) and choose to encrypt the disk during the installation (or in Kickstart..). Due to time constraints I did not perform this (and as a result, there's also no export of an encrypted VM). If this is a significant part of your evaluation, please let me know and I will complete this part as well.

**Update**: An encrypted VM was created and exported as described above, A link to it was sent via E-Mail.

### System and kernel components
As I have used a minimal box I would expect it to be.. minimal. I'm not an expert at hardening Linux beyond the basics of installing only what one needs. In addition, I have verified that the VM only listens to ssh on the network.

### Automation
Configuration managements of the VM is done using a single chef recipe, [kiosk.rb](kiosk.rb)
The use of the [chef-apply](https://www.vagrantup.com/docs/provisioning/chef_apply.html) provisioner poses some limitation, such as lack of roes and attribute files. On the other hand it does not require shared folders an thus a long chain of required packages. As this is a very simple implementation, this seems to me like the right balance.

Users are defined using attribues in the recipe, and running `vagrant provision` after adding or modifying users will update them automatically.  
**Note**: Removing a user from the recipe will not remove it from the VM. That would require a full Chef client.

To change the running app from xcalc to something else, just replace xcalc in kiosk.rb with the desired app (first in app installation, and then execution)


## Deliverables

|File            |Description                               |
|----------------|------------------------------------------|
|`README.md`     |This documentation file                   |
|[`Vagrantfile`](Vagrantfile)   |Vagrant configuration file                |
|[`kiosk.rb`](kiosk.rb)      |Chef recipe to set-up the kiosk           |
|[`encrypt.sh`](encrypt.sh)    |Script to encrypt the VM (local VBOX only)|


