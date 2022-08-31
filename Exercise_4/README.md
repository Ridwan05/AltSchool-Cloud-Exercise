# Exercise 4

## Created 3 groups – Admin, Support & Engineering and added the Admin group to sudoers
- I Used `sudo groupadd Admin` to create _Admin_ group  

  ![groupadd](groupadd.png)  
  `sudo groupadd Support` and `sudo groupadd Engineering` were used to create _Support_ and _Engineering_ group respectively.  
- I used `nano /etc/sudoers` to edit the content of /etc/sudoers
- added _Admin_ group to sudoers by adding _%Admin ALL=(ALL:ALL) ALL_ to content of /etc/sudoers  

   ![/etc/sudoers](etc_sudoers.png)

## Created a user in each of the groups.
I Used `sudo useradd -g Admin ARid` to create user _ARid_ in the _Admin_ group  

  ![useradd](useradd.png)  
  `sudo useradd -g Support SRid` and `sudo useradd -g Engineering ERid` were used to create user _SRid_ and user _ERid_ in _Support_ and _Engineering_ group respectively.  

## Generated SSH keys for the user in the Admin group
- I used `su ARid` to switched to user _ARid_
- `cd` to /home/ARid  
- created _.ssh_ file
- generated ssh key with `ssh-keygen` and saved in the default folder _/home/ARid/.ssh/id_rsa_  

   ![ssh](ssh.png)  

## Contents of /etc/passwd
   ![/etc/passwd](passwd.png)

## Contents of /etc/passwd
   ![/etc/group](group.png)
