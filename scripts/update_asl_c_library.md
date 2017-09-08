# Update ASL C Libraries

## Introduction
Use the update_asl_c_library.sh script to update the C-libraries based on the message definitions in the fw_mavlink repo.

This script _tries_ to reflect the commit tree in the fw_mavlink repository onto the C library repositories.

Meanining:
You want to test your new message. For that purpose, you created a new branch ```feature/new_messages``` which is based on ```devel``` and made a new commit containing the new message.
The script then automatically creates a new branch ```feature/new_messages``` in both C-library repos, that forks from the same commit in ```devel```.

## Usage
In general, you can just invoke the script by executing it from the mavlink root directory:
```
./scripts/update_asl_c_library.sh
```

This generates the ASLUAV C libraries (and all it's dependencies, i.e. common message definitions in ```common.xml```) in the subdirectory ```include/mavlink```. 

Please be aware that this script automatically commits the changes to the C-library repos and pushes them.

## Other
This script _tries_ to reflect the commit tree means: the script tries to find the parent commit within the C-library repo.
This only works to some degree (i.e. if every commit in fw_mavlink repo has an auto-generated commit in the C-library repo).

Feedback is highly appreciated!
