# SAK - Simple SSH Key Manager

SAK is a lightweight, Haskell-based tool to manage your `~/.ssh/authorized_keys` file safely and efficiently. It allows you to add, list, enable, disable, and remove SSH keys with UUID-based identification.

## Features

* Add SSH keys with optional description.
* List all keys (including loose keys) with status.
* Enable/Disable keys by UUID (adds/removes `#` comment).
* Remove keys by UUID.
* Thread-safe file operations using file locks.
* Preserves existing formatting and loose keys.

## Installation

Clone the repository and build with Stack:

```bash
git clone <repo-url>
cd SAK
stack build
stack install
```

## Usage

```bash
sak help           # Shows help menu
sak list           # Lists all keys
sak add <name> <key> [desc]    # Adds a new key
sak disable <uuid> # Disables a key
sak enable <uuid>  # Enables a key
sak remove <uuid>  # Removes a key
sak uuid           # Lists all UUIDs
sak cmd            # Lists all commands
```

## Example

```bash
sak add mykey "ssh-rsa AAA..." "My personal key"
sak list
sak disable 123e4567-e89b-12d3-a456-426614174000
sak enable 123e4567-e89b-12d3-a456-426614174000
sak remove 123e4567-e89b-12d3-a456-426614174000
```

## Notes

* SAK uses UUIDs to safely identify keys.
* Loose keys in `authorized_keys` are preserved.
* Requires Haskell Stack to build.

