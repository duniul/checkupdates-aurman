# ⬆ checkupdates-aurman
![checkupdates-aurman-banner](https://user-images.githubusercontent.com/11836617/43890938-66b61638-9bc8-11e8-912e-1acc260144e7.png)  

**An update checking script for [aurman](https://github.com/polygamma/aurman)**  
Outputs a list of available updates from both official repositories and the AUR.

> There is no quick command in aurman to check updates from both official repos and the AUR at the same time. 
> The recommended way is to parse the JSON output from `aurmansolver -Su` on your own. The problem is that 
> `aurmansolver` isn't meant as a version checker, so it requires a bit of stitching to get output similar to 
> that of pacman's `checkupdates`.  
>
> I made this script to deal with that, and to add some options to prettify the output. It also works well with
> [Arch Linux Updates Indicator](https://github.com/RaphaelRochet/arch-update), see [example below](#using-with-arch-linux-updates-indicator).

## Usage
```bash
checkupdates-aurman [...options]
```

Without any options, the output looks identical to that of pacman's `checkupdates`, but includes packages from the AUR.

#### Options
* `-o, --origin`  
  🔖 Add tags to indicate the origin/type of each package (see [Origin tags](#origin-tags)).  
    
* `-c, --color`  
  🌈 Print output in color, also highlighting version changes.  
    
* `-t, --table`  
  🏛️ Print output as a table with aligned columns.  
    
* `-h, --help`  
  ❓ Show help page.
   
#### Requirements
* [aurman](https://github.com/polygamma/aurman) (of course)
* [jq](https://github.com/stedolan/jq) for parsing JSON output from `aurmansolver`
   
#### Installation
It's just a simple shell file, just clone this repo or download it manually and then run it.

#### Using with Arch Linux Updates Indicator
To use with [Arch Linux Updates Indicator](https://github.com/RaphaelRochet/arch-update), set this as your command to check for updates:

```bash
/bin/sh -c "/home/dagr01/bin/checkupdates-aurman"
```

You need to toggle the "Strip out versions number"-option if you want the indicator to show full lines or origin tags.

   
## Origin tags
Origin tags correspond with aurmansolver's *type_of* for each package.

The tags are (*type_of* in parentheses):  
* **[REP]** - Official repository packages (REPO_PACKAGE) 
* **[AUR]** - AUR packages (AUR_PACKAGE) 
* **[DEV]** - Development packages (DEVEL_PACKAGE) 
* **[EXT]** - External packages (PACKAGE_NOT_REPO_NOT_AUR)
