# Windows-Credential-manager-cleaner
Powershell script to delete credentials from the windows credential manager.
----------------------------------------------------------
!!! WARNING !!!
!!! Use at own risk !!!
!!! I take no responsibility for any lost credentials !!!
----------------------------------------------------------
This script will permanently delete credentials from the Windows Credential Manager.
Before running this script backup the credentials
1. Search windows menu for "Credential Manager"
2. Open credential manager and select the "Windows Credential" Tab
3. Select the "Back up Credentials" link and follow the instructions

I run this script in powershell ISE as the user profile that you are working on, not as administrator.
It will ask you to choose if you want to delete all credentials or search for a "Name" and only delete those found containing that "Name"
The search is case sensitive.
It will ask two times to confirm if you want to proceed with the deletion.
It saves a log of what credentials were deleted.
The log contains no passwords.

This is very handy for that issue where Adobe caches literally hundreds of credentials in the credential manager.
Select option 2 and enter Adobe when prompted and follow the instructions.

!!! I have tested this and it does work, however I do stress that you should back up the credentials before you run it !!!
!!! YOU HAVE BEEN WARNED !!!
----------------------------------------------------------
