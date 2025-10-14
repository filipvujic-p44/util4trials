# util4trials

INFO:
-----
    author: Filip Vujic
    github: https://github.com/filipvujic-p44/gcp2git

    This script is a tool for downloading and updating trials.

REQUIREMENTS:
-------------
    - wget (for downloading updates)
    - curl (for calls)
    - bash-completion (for autocomplete)

INSTALLATION:
-------------
    Using '--install' option will create a folder ~/util4trials and put the script inside.
    That path will be exported to ~/.bashrc so it can be used from anywhere.
    Script requires wget, curl and bash-completion, so it will install those packages.
    Use '--install-y' to preapprove dependencies.
    Using '--uninstall' will remove ~/util4trials folder and ~/.bashrc inserts. 
    You can remove wget, curl and bash-completion dependencies manually, if needed.
