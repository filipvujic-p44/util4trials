#!/bin/bash
version="v1.0.1"
author="Filip Vujic"
last_updated="14-Oct-2025"
repo_owner="filipvujic-p44"
repo_name="util4trials"
repo="https://github.com/$repo_owner/$repo_name"

###################################### TO-DO ##############################################
# - 
###########################################################################################



###########################################################################################
###################################### Info and help ######################################
###########################################################################################



# Help text
help_text=$(cat <<EOL
UTIL4TRIALS HELP:
-------------

Info:
-----
    util4trials version: $version
    author: $author
    last updated: $last_updated
    github: $repo

    This script is a tool for downloading and updating trials.

Requirements:
-------------
    - wget (for downloading updates)
    - curl (for calls)
    - bash-completion (for autocomplete)

Installation:
-------------
    Using '--install' option will create a folder ~/util4trials and put the script inside.
    That path will be exported to ~/.bashrc so it can be used from anywhere.
    Script requires wget, curl and bash-completion, so it will install those packages.
    Use '--install-y' to preapprove dependencies.
    Using '--uninstall' will remove ~/util4trials folder and ~/.bashrc inserts. 
    You can remove wget, curl and bash-completion dependencies manually, if needed.

Options:
--------
    util4trials.sh [-v | --version] [-h | --help] [--help-actions-and-envs]
               [--install] [--install-y] [--uninstall] [--chk-install] [--chk-for-updates] 
               [--auto-chk-for-updates-off] [--auto-chk-for-updates-on] [--generate-env-file]
               [--export-trials] [--update-trials-from-file] [--update-trials-from-name]
               [--int] [--stg] [--sbx] [--eu] [--us]
               [--ltl] [--tl] [--carrier-push] [--carrier-pull]
               [--auth] [--rating] [--dispatch] [--tracking] [--imaging] [--telemetry]
               [--carrier <carrier_scac>] <carrier_scac>

Options (details):
------------------
    general:
        -v | --version                    Display script version and author.
        -h | --help                       Display help and usage info.
        --help-actions-and-envs           Display actions and environments info.
        --install                         Install script to use from anywhere in terminal.
        --install-y                       Install with preapproved dependencies and run 'gcloud auth login' after installation.
        --uninstall                       Remove changes made during install (except dependencies).
        --chk-install                     Check if script and dependencies are installed correctly.
        --chk-for-updates                 Check for new script versions.
        --auto-chk-for-updates-off        Turn off automatic check for updates (default state).
        --auto-chk-for-updates-on         Turn on automatic check for updates (checks on every run).
        --generate-env-file               Generate '.env_util4trials' in current folder.

    actions:
        --export-trials                   Get all trials jsons.
        --update-trials-from-file         Update trials using input file containing trial jsons.
        --update-trials-from-name         Update trials using a specific trial name.

    environment options:
        int                               GCP qa-integration.
        stg                               GCP qa-stage.
        sbx                               GCP sandbox.
        eu                                GCP eu-production.
        us                                GCP us-production.
        --int                             Set environment name to int.
        --stg                             Set environment name to stg.
        --sbx                             Set environment name to sbx.
        --eu                              Set environment name to eu.
        --us                              Set environment name to us.


    transportation-modes:
        --ltl                             Set mode to 'LTL' (default value).
        --tl                              Set mode to 'TL'.
        
    service-types:
    	--auth                            Set service to 'AUTHENTICATION_RENEWAL'.
        --rating                          Set service to 'RATING'.
        --dispatch                        Set service to 'DISPATCH'.
        --tracking                        Set service to 'SHIPMENT_STATUS'.
        --imaging                         Set service to 'IMAGING'.
        --telemetry                       Set service to 'TELEMETRY'.

    interaction-types:
        --carrier-push                    Set interaction to 'CARRIER_PUSH'.
        --carrier-pull                    Set interaction to 'CARRIER_PULL' (default value).

    carrier:
        --carrier <carrier_scac>          Set carrier scac (case insensitive; can be set without using '--carrier' flag).

Usage:
------
    util4trials.sh (general-option | [transportation-mode] [interaction-type] [--carrier] scac service-type action)
    util4trials.sh abfs --imaging --compare lcl us
    util4trials.sh --generate-env-file
    util4trials.sh --tl --rating --download int gtjn
    util4trials.sh --carrier-pull --dispatch --carrier EXLA --update lcl pg
    util4trials.sh --tracking --carrier gtjn --update pg gh

Notes:
------
    - Tested on WSL Debian 13.1
    - Default mode is 'LTL', default interaction is 'CARRIER_PULL'.
    - Carrier can be specified without using '--carrier' flag and is case insensitive.
    - Value by priority (highest->lowest): flags->env_file->internal
EOL
)

# Modes text
actions_and_envs_text=$(cat <<EOL
ACTIONS AND ENVIRONMENTS HELP:
-----------

Options:
--------
    actions:
        --export-trials                   Get all trials jsons.
        --update-trials-from-file         Update trials using input file containing trial jsons.
        --update-trials-from-name         Update trials using a specific trial name.

Usage:
------
    util4trials.sh (general-option | [transportation-mode] [interaction-type] [--carrier] scac service-type action)
    util4trials.sh abfs --imaging --compare lcl us
    util4trials.sh --generate-env-file
    util4trials.sh --tl --rating --download int gtjn
    util4trials.sh --carrier-pull --dispatch --carrier EXLA --update lcl pg
    util4trials.sh --tracking --carrier gtjn --update pg gh

EOL
)



############################################################################################
###################################### Vars and flags ######################################
############################################################################################



# Initialize variables to default values
flg_args_passed=false
do_install=false
do_install_y=false
do_uninstall=false
do_chk_install_=false
# ref_chk_for_updates (do not change comment)
flg_chk_for_updates=false
flg_generate_env_file=false

flg_export_trials=false
flg_update_trials_from_file=false
flg_update_trials_from_name=false

gcp_pg_base_url="gs://p44-datafeed-pipeline/qa-int/src"
qa_int_api_base_url="https://na12.api.qa-integration.p-44.com/onramp-connection-manager-gateway/trial"
gcp_qa_stage_base_url="gs://p44-staging-us-central1-data-feed-plan-definitions-staging/qa-stage/src"
gcp_sandbox_base_url="gs://p44-sandbox-us-data-feed-plan-definitions/sandbox/src"
gcp_eu_prod_base_url="gs://p44-production-eu-data-feed-plan-definitions/production-eu/src"
gcp_us_prod_base_url="gs://data-feed-plan-definitions-prod-prod-us-central1-582378/production/src"

#ref_token
glb_token="eyJraWQiOiJZVnhpTDBrVThRZGdSOWN5TjZDeCIsImFsZyI6IlJTMjU2In0.eyJjdXN0b21lcklkcFJvbGVzIjpbIkJhc2ljIiwiTGVhZCIsImx0bC1hZG1pbiIsImNhcnJpZXItdGVuYW50LWRlbGV0ZXIiLCJzaGlwcGVyLXRlbmFudC1kZWxldGVyIiwidGVuYW50LW5ldHdvcmstcm9sZS11cGRhdGVyIl0sImdpdmVuTmFtZSI6IkZpbGlwIiwiZmFtaWx5TmFtZSI6IlZ1amljIiwidGVuYW50SWQiOiIyNTYiLCJjb21wYW55VWlkIjoiZWVmZmZmNmEtNTQ3Ny00ZGI2LWI1ZGMtYTVkYTQ1M2Q3OGFmIiwibGFrZUlkIjoiMTY4MDYwNDQ2MzU3NSIsImF1dGhJZHBzIjpbIjBvYXc5NGpudXJ1ZHpnbjU4MGg3Il0sImF1ZCI6ImFwaTovL2RlZmF1bHQiLCJpYXQiOjE3NjA1MjA4MTgsImlzcyI6Imh0dHBzOi8vbmExMi5hcGkucWEtaW50ZWdyYXRpb24ucC00NC5jb20iLCJzdWIiOiJmaWxpcC52dWppY0Bwcm9qZWN0NDQuY29tIiwiZXhwIjoxNzYwNTY0MDE3LCJqdGkiOiJlN2QxOWEyZS00YmFhLTQ5ZWEtOWQ0My02ZGVmMzExNGIzY2QifQ.HpLOyY11IV1N3pv7CcGDBIHYeriByCB4y7K_AT64hD_YpKITs0tIVK92_yELIVFAZ5ZpSwQeHqk21csWS6bvF3FMAt2MUxCpJEWivVaBgXKa8LlSRAWN4uL-j6EegTVaJuvJFHiTqsTECWYR4p88uQMENfLbUbvEwopHvRdmBNpuFj_oOlHscARYKeA5ztoaLVTCssRzuYap_PLaWUJZT1rXpPtERm19JDcx2uazgtQNd5d1s_7wkFmGQoL32Zi4LmcXBlAhsbgL3vzPgzCA8u9S-VxkSgP96E98yMzli77O_ymXTBY_pG5ODS9ggbMffdiPyv7fnPuZn7G6UU6m1Q"
#ref_username
glb_username="filip.vujic@project44.com"
#ref_env_id
glb_env_user_id="1680604463575"
glb_valid_env_name_values=("int" "stg" "sbx" "eu" "us")
#ref_env_name
glb_env_name="int"
#ref_mode
glb_mode="LTL"
#ref_service
glb_service="RATING"
#ref_interaction
glb_interaction="CARRIER_PULL"
#ref_carrier
glb_carrier="ABFS"

glb_trials_file_path=""
glb_trial_name=""
glb_trials_backup_file_name="trials_backup.json"
glb_trials_export_file_name="trials.json"

# Check if any args are passed to the script
if [ ! -z "$1" ]; then
    flg_args_passed=true
fi

# Load local .env_util4trials file
if [ -e ".env_util4trials" ]; then
    flg_args_passed=true
    source .env_util4trials

    # Set URLs from .env

    # Load qa int base URL value
    if [ ! -z "$QA_INT_BASE_URL" ]; then
        qa_int_base_url="$QA_INT_BASE_URL"
    fi

        # Load sandbox base URL value
    if [ ! -z "$QA_STAGE_BASE_URL" ]; then
        qa_stage_base_url="$QA_STAGE_BASE_URL"
    fi

    # Load sandbox base URL value
    if [ ! -z "$SANDBOX_BASE_URL" ]; then
        sandbox_base_url="$SANDBOX_BASE_URL"
    fi

        # Load eu prod base URL value
    if [ ! -z "$EU_PROD_BASE_URL" ]; then
        eu_prod_base_url="$EU_PROD_BASE_URL"
    fi

    # Load us prod base URL value
    if [ ! -z "$US_PROD_BASE_URL" ]; then
        us_prod_base_url="$US_PROD_BASE_URL"
    fi

    # Set auth details from .env

    # Load token value
    if [ ! -z "$TOKEN" ]; then
        glb_token="$TOKEN"
    fi

    # Load username value
    if [ ! -z "$USERNAME" ]; then
        glb_username="$USERNAME"
    fi

    # Load environment user ID value
    if [ ! -z "$ENVIRONMENT_USER_ID" ]; then
        glb_env_user_id="$ENVIRONMENT_USER_ID"
    fi

    # Set integration details from .env

    # Load environment name value
    if [ ! -z "$ENVIRONMENT_NAME" ]; then
        glb_env_name="$ENVIRONMENT_NAME"
    fi

    # Load mode value
    if [ ! -z "$MODE" ]; then
        glb_mode="$MODE"
    fi

    # Load service value
    if [ ! -z "$SERVICE" ]; then
        glb_service="$SERVICE"
    fi

    # Load interaction value
    if [ ! -z "$INTERACTION" ]; then
        glb_interaction="$INTERACTION"
    fi

    # Load carrier value
    if [ ! -z "$CARRIER" ]; then
        glb_carrier="$CARRIER"
    fi

    # Set trial source details

    # Load trials file path value
    if [ ! -z "$TRIALS_FILE_PATH" ]; then
        glb_trials_file_path="$TRIALS_FILE_PATH"
    fi

    # Load trial name value
    if [ ! -z "$TRIAL_NAME" ]; then
        glb_trial_name="$TRIAL_NAME"
    fi
fi

while [ "$1" != "" ] || [ "$#" -gt 0 ]; do
    case "$1" in
        -v | --version)
            echo "util4trials version: $version"
            echo "author: $author"
            echo "last updated: $last_updated"
            echo "github: $repo"
            exit 0
            ;;
        -h | --help)
            echo "$help_text"
            exit 0
            ;;
        --help-actions-and-envs)
            echo "$actions_and_envs_text"
            exit 0
            ;;
        --install)
            do_install=true
            ;;
        --install-y)
            do_install_y=true
            ;;
        --uninstall)
            do_uninstall=true
            ;;
        --chk-install)
            do_chk_install=true
            ;;
        --chk-for-updates)
            flg_chk_for_updates=true
            ;;
        --auto-chk-for-updates-off)
            ref_line_number=$(grep -n "ref_chk_for_updates*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "flg_chk_for_updates=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/flg_chk_for_updates=true/flg_chk_for_updates=false/" "$0"
                echo "Info: Auto check for updates turned off."	
            fi
            exit 0
            ;;
        --auto-chk-for-updates-on)
            ref_line_number=$(grep -n "ref_chk_for_updates*" "$0" | head -n1 | cut -d':' -f1)
            line_number=$(grep -n "flg_chk_for_updates=" "$0" | head -n1 | cut -d':' -f1)
            if [ "$((line_number - ref_line_number))" -eq 1 ]; then
                sed -i "${line_number}s/flg_chk_for_updates=false/flg_chk_for_updates=true/" "$0"
                echo "Info: Auto check for updates turned on."
            fi
            exit 0
            ;;
        --generate-env-file)
            flg_generate_env_file=true
            ;;
        -c | --config)
			echo "Token ------------------- $glb_token"
            echo "Username ---------------- $glb_username"
            echo "Env user id ------------- $glb_env_user_id"
            echo "Environment ------------- $glb_env_name"
            echo "Mode -------------------- $glb_mode"
            echo "Service ----------------- $glb_service"
            echo "Interaction ------------- $glb_interaction"
			echo "Carrier ----------------- $glb_carrier"
            echo "Trials file path -------- $glb_trials_file_path"
            echo "Trial name -------------- $glb_trial_name"
			exit 0
			;;
		-t | --set-token)
			ref_line_number=$(grep -n "ref_token*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_token=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_token=.*/glb_token=\"$2\"/" "$0"
				echo "Info: Token updated."	
			shift 1
			fi
			;;
        --set-username)
			ref_line_number=$(grep -n "ref_username*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_username=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_username=.*/glb_username=\"$2\"/" "$0"
				echo "Info: Username updated."	
			shift 1
			fi
			;;
        --set-env-id)
			ref_line_number=$(grep -n "ref_env_id*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_env_user_id=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_env_user_id=.*/glb_env_user_id=\"$2\"/" "$0"
				echo "Info: Environment user ID updated."	
			shift 1
			fi
			;;
        --set-env-name)
            if [[ ! " ${glb_valid_env_name_values[*]} " =~ " $2 " ]]; then
                echo "Error: '$2' is not a valid value. Must be one of: ${valid_values[*]}"
                exit 1
            fi
			ref_line_number=$(grep -n "ref_env_name*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_env_name=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_env_name=.*/glb_env_name=\"$2\"/" "$0"
				echo "Info: Environment user ID updated."	
			shift 1
			fi
			;;
        --int)
            glb_env_name="int"
            echo "Info: Environment set to 'int'."	
            ;;
        --stg)
            glb_env_name="stg"
            echo "Info: Environment set to 'stg'."	
            ;;
        --sbx)
            glb_env_name="sbx"
            echo "Info: Environment set to 'sbx'."	
            ;;
        --eu)
            glb_env_name="eu"
            echo "Info: Environment set to 'eu'."	
            ;;
        --us)
            glb_env_name="us"
            echo "Info: Environment set to 'us'."	
            ;;
        --set-mode)
			ref_line_number=$(grep -n "ref_mode*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_mode=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_mode=.*/glb_mode=\"$2\"/" "$0"
				echo "Info: Mode updated."	
			shift 1
			fi
			;;
        --set-service)
			ref_line_number=$(grep -n "ref_service*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_service=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_service=.*/glb_service=\"$2\"/" "$0"
				echo "Info: Service updated."	
			shift 1
			fi
			;;
        --set-interaction)
			ref_line_number=$(grep -n "ref_interaction*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_interaction=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_interaction=.*/glb_interaction=\"$2\"/" "$0"
				echo "Info: Interaction updated."	
			shift 1
			fi
			;;
        --set-carrier)
			ref_line_number=$(grep -n "ref_carrier*" "$0" | head -n1 | cut -d':' -f1)
			line_number=$(grep -n "glb_carrier=" "$0" | head -n1 | cut -d':' -f1)
			if [ "$((line_number - ref_line_number))" -eq 1 ]; then
				sed -i "${line_number}s/^glb_carrier=.*/glb_carrier=\"$2\"/" "$0"
				echo "Info: Carrier updated."	
			shift 1
			fi
			;;
        --export-trials)
            flg_export_trials=true
            # glb_env_name="${2}"
            # shift 1
            ;;
        --update-trials-from-file)
            flg_update_trials_from_file=true
            glb_trials_file_path="${2}"
            shift 1 # plus 1 after case block
            ;;
        --update-trials-from-name)
            flg_update_trials_from_name=true
            glb_trial_name="${2}"
            shift 1 # plus 1 after case block
            ;;
        --ltl)
            glb_mode="LTL"
            ;;
        --tl)
            glb_mode="TL"
            ;;
        --auth)
        	glb_service="AUTHENTICATION_RENEWAL"
        	;;
        --rating)
            glb_service="RATING"
            ;;
        --dispatch)
            glb_service="DISPATCH"
            ;;
        --tracking)
            glb_service="SHIPMENT_STATUS"
            ;;
        --imaging)
            glb_service="IMAGING"
            ;;
        --telemetry)
            glb_service="TELEMETRY"
            ;;
        --carrier-push)
            glb_interaction="CARRIER_PUSH"
            ;;
        --carrier-pull)
            glb_interaction="CARRIER_PULL"
            ;;
        --carrier)
            glb_carrier="${2^^}"
            shift 2 # plus 1 after case block
            ;;
        *)
            glb_carrier="${1^^}"
            ;;
    esac
    # Since this default shift exists, all flag handling shifts are decreased by 1
    shift
done



################################################################################################
###################################### Check functions #########################################
################################################################################################



# Check if wget is installed
check_wget_installed() {
    command -v wget &>/dev/null
}

# Check if curl is installed
check_curl_installed() {
    command -v curl &>/dev/null
}

check_bash_completion_installed() {
    if dpkg -l | grep -q "bash-completion"; then
        return 0
    fi
    return 1
}

# Check if there is a new release on util4trials GitHub repo
check_for_updates() {
    # Local script version
    local local_version=$(echo "$version" | sed 's/^v//')
    # Latest release text
    local latest_text=$(curl -s "https://api.github.com/repos/$repo_owner/$repo_name/releases/latest")
    # Latest remote version
    local remote_version=$(echo "$latest_text" | grep "tag_name" | sed 's/.*"v\([0-9.]*\)".*/\1/' | cat)
    # Check if versions are different
    local version_result=$(
        awk -v v1="$local_version" -v v2="$remote_version" '
            BEGIN {
                if (v1 == v2) {
                    result = 0;
                    exit;
                }
                split(v1, a, ".");
                split(v2, b, ".");
                for (i = 1; i <= length(a); i++) {
                    if (a[i] < b[i]) {
                        result = 1;
                        exit;
                    } else if (a[i] > b[i]) {
                        result = 2;
                        exit;
                    }
                }
                result = 0;
                exit;
            }
            END {
                print result
            }'
    )   
    if [ "$version_result" -eq 0 ]; then
        echo "Info: You already have the latest script version ($version)."
    elif [ "$version_result" -eq 1 ]; then
        local release_notes=$(echo "$latest_text" | grep "body" | sed -n 's/.*"body": "\([^"]*\)".*/\1/p' | sed 's/\\r\\n/\n/g' | cat)
        echo "Info: New version available (v$remote_version). Your version is (v$local_version)."
        echo "Info: Release notes:"
        echo "$release_notes"
        echo "Info: Visit '$repo/releases' for more info."
        echo "Q: Do you want to download and install updates? (Y/n):"
        read do_update
        if [ "${do_update,,}" == "y" ] || [ -z "$do_update" ]; then
            install_updates "$remote_version"
        else
            echo "Info: Update canceled."
        fi
    elif [ "$version_result" -eq 2 ]; then
        echo "Info: You somehow have a version that hasn't been released yet ;)"
        echo "Info: Latest release is (v$remote_version). Your version is (v$local_version)."
    fi
}

# Check if all necessary changes are done during installation
check_installation() {
    local cnt_missing=0
    if check_wget_installed; then
        echo "Info: wget ------------------- OK."
    else
        echo "Error: wget ------------------ NOT FOUND."
        ((cnt_missing++))
    fi

    if check_curl_installed; then
        echo "Info: curl ===---------------- OK."
    else
        echo "Error: curl ------------------ NOT FOUND."
        ((cnt_missing++))
    fi

    if check_bash_completion_installed; then
        echo "Info: bash-completion -------- OK."
    else
        echo "Error: bash-completion ------- NOT FOUND."
        ((cnt_missing++))
    fi
        
    if [ -d ~/util4trials ] && [ -f ~/util4trials/main/util4trials.sh ] && [ -f ~/util4trials/util/autocomplete_util4trials.sh ]; then
        echo "Info: ~/util4trials/ --------- OK."
    else
        echo "Error: ~/util4trials/ -------- NOT OK."
        ((cnt_missing++))
    fi

    if grep -q "# util4trials script" ~/.bashrc && grep -q 'export PATH=$PATH:~/util4trials/main' ~/.bashrc &&
        grep -q "source ~/util4trials/util/autocomplete_util4trials.sh" ~/.bashrc; then
        echo "Info: ~/.bashrc -------------- OK."
    else
        echo "Error: ~/.bashrc ------------- NOT OK."
        ((cnt_missing++))
    fi	

    if [ "$cnt_missing" -gt "0" ]; then
        echo "Error: Problems found. Use '--install' or '--install-y' to (re)install the script." >&2
        return 1
    fi
    return 0
}

# Check if the required number of args is passed to a function
# $1 - required number of args
# $2 - all passed args
check_args() {
        local parent_func="${FUNCNAME[1]}"
        local required_number_of_args=$1
        shift;
        local total_number_of_args=$#
        local args=$@
        if [ $total_number_of_args == 0 ] || [ -z $total_number_of_args ]; then
            echo "Error: No arguments provided!" >&2
            return 1
        fi
        if [ $total_number_of_args -ne $required_number_of_args ]; then
            echo "Error: Function '$parent_func' required $required_number_of_args arguments but $total_number_of_args provided!" >&2
            return 1
        fi
}

# Checks if a file starts with any of the prefixes.
# $1 - local file name
check_file_prefix() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local filename=$1
    # Function logic
    local prefixes=("dataFeedPlan" "valueTranslations" "controlTemplate" "headerTemplate" "uriTemplate" "requestBodyTemplate" "responseBodyTemplate")
    for prefix in "${prefixes[@]}"; do
        if [[ "$filename" == "$prefix"* ]]; then
            return 0
        fi
    done
    return 1
}

# Check if current directory is a git repo.
check_is_git_repo() {
    if [ -d ".git" ] && [ "$(git rev-parse --is-inside-work-tree)" == "true" ]; then
           return 0
       else
        return 1
    fi
}

# Check all git requirements.
check_git_repo_requirements() {
    if ! check_git_installed; then
        echo "Error: Git is not installed!" >&2
        return 1
    fi
    if ! check_is_git_repo; then
        echo "Error: Directory is not a git repo!" >&2
        return 1
    fi
}

# Check if carrier scac is provided
check_carrier_set() {
    if [ -z "$glb_carrier" ]; then
        return 1
    fi
    return 0
}

# Check if service name is provided
check_service_set() {
    if [ -z "$glb_service" ]; then
        return 1
    fi
    return 0
}

# Check if all dependencies are installed
check_dependencies() {
    if ! check_wget_installed; then
        echo "Info: Wget is not installed. Installing updates may not work properly."
    fi

    if ! check_curl_installed; then
        echo "Info: Curl is not installed. Calls may not work properly."
    fi

    if ! check_bash_completion_installed; then
        echo "Info: Bash-completion is not installed. It is not required, but you won't have command completion."
    fi
}

# Check if carrier is set
check_carrier_is_set() {
    if ! check_carrier_set; then
        echo "Error: No carrier scac provided!" >&2
        exit 1
    fi
}

# Check if service is set
check_service_is_set() {
    if ! check_service_set; then
        echo "Error: No service name provided!" >&2
        exit 1
    fi
}



#################################################################################################
###################################### Install / Uninstall functions ############################
#################################################################################################



# Main installation function
install_script() {
    echo "Info: Installing util4trials..."
    script_directory="$(dirname "$(readlink -f "$0")")"
    # Check if requirements installed
    if ! check_wget_installed || ! check_curl_installed || ! check_bash_completion_installed; then
        install_dependencies
    fi
    # Check if script already installed
    if [ -d ~/util4trials ] && [ -f ~/util4trials/main/util4trials.sh ] && [ -f ~/util4trials/util/autocomplete_util4trials.sh ] &&
    grep -q "# util4trials script" ~/.bashrc && grep -q 'export PATH=$PATH:~/util4trials/main' ~/.bashrc &&
    grep -q "source ~/util4trials/util/autocomplete_util4trials.sh" ~/.bashrc; then
        echo "Info: Script already installed at '~/util4trials' folder."
        echo "Q: Do you want to reinstall util4trials? (Y/n):"
        read do_reinstall
        if [ "${do_reinstall,,}" == "n" ]; then
            echo "Info: Exited installation process. No changes made."
            exit 0
        fi
    fi
    # Clean up possible leftovers or previous installation
    clean_up_installation
    # Set up util4trials home folder
    echo "Info: Setting up '~/util4trials/' directory..."
    mkdir ~/util4trials
    mkdir ~/util4trials/main
    mkdir ~/util4trials/util
    cp $script_directory/util4trials.sh ~/util4trials/main
    # Generate autocomplete script
    generate_autocomplete_script
    echo "Info: Setting up '~/util4trials/' directory completed."
    # Set up bashrc inserts
    echo "Info: Adding paths to '~/.bashrc'..."
    echo "# util4trials script" >> ~/.bashrc
    echo 'export PATH=$PATH:~/util4trials/main' >> ~/.bashrc
    echo "source ~/util4trials/util/autocomplete_util4trials.sh" >> ~/.bashrc
    echo "Info: Paths added to '~/.bashrc'."
    # Print success message
    echo "Info: Success. Script installed in '~/util4trials/' folder."
    # If '--install-y' was used, set up gcloud auth
    if [ "$do_install_y" == "true" ]; then
        echo "Info: Setting up GCloud CLI login..."
        echo "Q: Input your p44 email:"
        read email
        gcloud auth login $email
        if gcloud auth list | grep -q "$email"; then
            echo "Info: Logged in to GCloud CLI."
            echo "Info: Use '--help-gcloud-cli' for more info."
        else
            echo "Error: Something went wrong during GCloud CLI login attempt." >&2
        fi
    else
        echo "Info: Use 'gcloud auth login my.email@project44.com' to login to GCloud CLI."
        echo "Info: Use 'gcloud auth list' to check if you are logged in."
        echo "Info: Use '--help-gcloud-cli' for more info."
    fi
    echo "Info: Run 'source ~/.bashrc' to apply changes in current session."
    echo "Info: Local file './util4trials.sh' is no longer needed."
    echo "Info: Use '-h' or '--help' to get started."
    exit 0
}

install_wget() {
    echo "Info: Installing wget..."
    if [ "$do_install_y" == "true" ]; then
        sudo apt install -y wget
    else
        sudo apt install wget
    fi
    echo "Info: Wget installed."
    
}

install_curl() {
    echo "Info: Installing curl..."
    if [ "$do_install_y" == "true" ]; then
        sudo apt install -y curl
    else
        sudo apt install curl
    fi
    echo "Info: Curl installed."
}

install_bash_completion() {
    echo "Info: Installing bash-completion..."
    if [ "$do_install_y" == "true" ]; then
        sudo apt install -y bash-completion
    else
        sudo apt install bash-completion
    fi
    echo "Info: Bash-completion installed."
}

install_dependencies() {
    sudo apt update
    # Check if wget is installed
    if ! check_wget_installed; then
        install_wget
    fi
    
    # Check if curl is installed
    if ! check_curl_installed; then
        install_curl
    fi

    # Check if bash-completion installed
    if ! check_bash_completion_installed; then
        install_bash_completion
    fi
}

# Cleans up existing installation and leftover files/changes
clean_up_installation() {
    echo "Info: Cleaning up existing files/changes..."
    if [ -d ~/util4trials ]; then
        rm  ~/util4trials/main/*
        rm  ~/util4trials/util/*
        rmdir ~/util4trials/main
        rmdir ~/util4trials/util
        rmdir ~/util4trials
    fi
    if [ -f ~/.bashrc.bak ]; then
        rm ~/.bashrc.bak
        cp ~/.bashrc ~/.bashrc.bak
    fi
    sed -i "/# util4trials script/d" ~/.bashrc
    sed -i '/export PATH=$PATH:~\/util4trials\/main/d' ~/.bashrc
    sed -i "/source ~\/util4trials\/util\/autocomplete_util4trials.sh/d" ~/.bashrc
    echo "Info: Cleanup completed."
}

# Main uninstall function
uninstall_script() {
    echo "Info: Uninstaling script..."
    clean_up_installation
    echo "Info: Script required wget, curl and bash-completion installed."
    echo "Info: You can remove these packages manually if needed."
    echo "Info: Uninstall completed."
    exit 0
}

# Download and install updates
# $1 - remote version
install_updates() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local remote_version=$1
    # Function logic
    update_url="https://github.com/$repo_owner/$repo_name/archive/refs/tags/v$remote_version.tar.gz"
    tmp_folder="tmp_util4trials_$remote_version"
    if [ -d "tmp_folder" ]; then
        rm -r "$tmp_folder"
    fi
    echo "Info: Downloading latest version..."
    wget -q -P "$tmp_folder" "$update_url"
    echo "Info: Download completed."
    echo "Info: Extracting..."
    cd "$tmp_folder"
    tar -xzf "v$remote_version.tar.gz"
    rm "v$remote_version.tar.gz"
    echo "Info: Extraction completed."
    cd "util4trials-$remote_version"
    ./util4trials.sh --install
    cd ../..
    rm -r "$tmp_folder"
}

# Generates autocomplete script in install folder
generate_autocomplete_script() {
    echo "Info: Generating 'autocomplete_util4trials.sh' script..."
    completion_text=$(cat <<EOL
#!/bin/bash

autocomplete_util4trials() {
    local cur prev words cword
    _init_completion || return

    local options="--version -v --chk-for-updates --auto-chk-for-updates-off --auto-chk-for-updates-on "
    options+="--help -h --help-actions-and-envs --install --install-y --uninstall "
    options+="--chk-install --generate-env-file "
    options+="--set-token --set-username --set-env-user-id --set-env-name --int --stg --sbx --eu --us "
    options+="--set-mode --set-interaction --set-service --set-carrier --set-trials-file-path --set-trial-name "
    options+="--export-trials --update-trials-from-file --update-trials-from-name "
    options+="--ltl --tl --all-modes --carrier-push --carrier-pull "
    options+="--auth --rating --dispatch --tracking --imaging --telemetry --carrier"

    if [[ "\${COMP_WORDS[@]} " =~ " --set-env-name " ]]; then
        local env_options=("int" "stg" "sbx" "eu" "us")
        COMPREPLY=(\$(compgen -W "\${env_options[*]}" -- "\${cur}"))
    elif [[ "\${COMP_WORDS[@]} " =~ " --set-mode " ]]; then
        local env_options=("LTL" "TL")
        COMPREPLY=(\$(compgen -W "\${env_options[*]}" -- "\${cur}"))
    elif [[ "\${COMP_WORDS[@]} " =~ " --set-interaction " ]]; then
        local env_options=("CARRIER_PULL" "CARRIER_PUSH")
        COMPREPLY=(\$(compgen -W "\${env_options[*]}" -- "\${cur}"))
    elif [[ "\${COMP_WORDS[@]} " =~ " --set-service " ]]; then
        local env_options=("RATING" "DISPATCH" "SHIPMENT_STATUS" "IMAGING" "AUTHENTICATION_RENEWAL" "TELEMETRY")
        COMPREPLY=(\$(compgen -W "\${env_options[*]}" -- "\${cur}"))
    elif [[ " \${COMP_WORDS[@]} " =~ " --set-trials-file-path " || " \${COMP_WORDS[@]} " =~ " --update-trials-from-file " ]]; then
        # Use compgen with proper quoting and readarray to handle spaces in filenames
        readarray -t COMPREPLY < <(compgen -f -- "\$cur" | grep -v '^-' )
    else
        COMPREPLY=(\$(compgen -W "\$options" -- "\${cur}"))
    fi

    return 0
}

complete -F autocomplete_util4trials util4trials.sh
EOL
)
    echo "$completion_text" >> ~/util4trials/util/autocomplete_util4trials.sh
    chmod +x ~/util4trials/util/autocomplete_util4trials.sh
    echo "Info: Generated 'autocomplete_util4trials.sh' script."
}

# Generates .env_util4trials file in current folder
generate_env_file() {
    echo "Info: Generating '.env_util4trials' file..."
    if [ -f "./.env_util4trials" ]; then
        rm ./.env_util4trials
    fi
    env_text=$(cat <<EOL
#!/bin/bash
# version="$version"
# author="$author"
# last_updated="$last_updated"
# github="$repo"

# URLS (defaults: already set)
QA_INT_BASE_URL=""
QA_STAGE_BASE_URL=""
SANDBOX_BASE_URL=""
EU_PROD_BASE_URL=""
US_PROD_BASE_URL=""

# AUTH DETAILS
# Token
TOKEN=""
# Username
USERNAME=""
# Environment ID
ENVIRONMENT_USER_ID=""

# INTEGRATION DETAILS (defaults: MODE=LTL, INTERACTION=CARRIER_PULL)
# Fields can be overridden by flags
# Environment name = [int, stg, sbx, eu, us]
ENVIRONMENT_NAME=""
# Modes  = [ LTL, TL ]
MODE=""
# Interactions = [ CARRIER_PULL, CARRIER_PUSH ]
INTERACTION=""
# Services = [ AUTHENTICATION_RENEWAL, RATING, DISPATCH, TRACKING, IMAGING ]
SERVICE="MY_SERVICE"
# Carrier scac
CARRIER="MY_SCAC"

# TRIAL INPUT DETAILS
# Trial file path
TRIALS_FILE_PATH=""
# Trial name
TRIAL_NAME=""
EOL
)
    echo "$env_text" >> ./.env_util4trials
    echo "Info: Generated '.env_util4trials' file."
}



###############################################################################################
###################################### Helper functions ######################################
###############################################################################################



# Return corresponding GCP base url based on passed environment name
# $1 - environment name
resolve_env_to_api_base_url() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local env_name=$1
    # Function logic
    result=""
    case "$env_name" in
        "pg")
            result="$gcp_pg_base_url"
            ;;
        "int")
            result="$qa_int_api_base_url"
            ;;
        "stg")
            result="$gcp_qa_stage_base_url" 
            ;;
        "sbx")
            result="$gcp_sandbox_base_url" 
            ;;
        "eu")
            result="$gcp_eu_prod_base_url" 
            ;;
        "us")
            result="$gcp_us_prod_base_url" 
            ;;
        *)
            :
            ;;
    esac
    if [ -z "$result" ]; then
        echo "Error: Environment '$env_name' not recognized!" >&2
        return 1
    else
        echo "$result"
    fi
}

# Extract id, display name and description from file
# $1 - input file containing json response of trials
extract_trial_values_from_file() {
    # Check arg count and npe, assign values
    # Requirement checks
    # Function logic
    local input_file=$glb_trials_file_path

    if jq empty "$input_file" >/dev/null 2>&1; then
        jq -r '.. | objects | select(.trialId? and .displayName? and .description?) | "\(.trialId) -- \(.displayName) -- \(.description)"' "$input_file" | sort -u
    else
        paste <(grep -oP '"trialId"\s*:\s*"\K[^"]+' "$input_file") \
            <(grep -oP '"displayName"\s*:\s*"\K[^"]+' "$input_file") \
            <(grep -oP '"description"\s*:\s*"\K[^"]*' "$input_file") \
            | awk -F '\t' '{print $1 " -- " $2 " -- " $3}' | sort -u
    fi
}

# Update a specific trial with provided payload
# $1 - trial payload
update_trial_from_payload() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local trial_payload=$1
    # Requirement checks
    # Function logic
    local base_url=$(resolve_env_to_api_base_url "$glb_env_name")
    local integration_string="$glb_mode.$glb_service.$glb_interaction.$glb_carrier"
    local username=$glb_username
    local token=$glb_token
    local trial_id=$(jq -r '.trialId' <<< "$trial_payload")

    curl -s -o /dev/null "$base_url/$integration_string/$trial_id/updateTrial" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -b "ajs_user_id=$username; AuthToken_usdev=$token" \
        --data-raw "$trial_payload"
}

# Get a specific trial using id
# $1 - trial id
get_trial() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local trial_id=$1
    # Requirement checks
    # check_carrier_is_set
    # check_service_is_set
    # Function logic
    local base_url=$(resolve_env_to_api_base_url "$glb_env_name")
    local integration_string="$glb_mode.$glb_service.$glb_interaction.$glb_carrier"
    local username=$glb_username
    local token=$glb_token

    curl -s "$base_url/$integration_string/$trial_id" \
        -H 'accept: application/json' \
        -b "ajs_user_id=$username; AuthToken_usdev=$token" \
        -H 'origin: https://movement.qa-integration.p-44.com' \
        -H 'referer: https://movement.qa-integration.p-44.com/' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
}


# Get basic data for all trials
get_trials_basic_info() {
    # Check arg count and npe, assign values
    # Requirement checks
    # Function logic
    local base_url=$(resolve_env_to_api_base_url "$glb_env_name")
    local integration_string="$glb_mode.$glb_service.$glb_interaction.$glb_carrier"
    local username=$glb_username
    local token=$glb_token

    curl -s "$base_url/$integration_string/getTrials" \
        -H 'accept: application/json' \
        -b "ajs_user_id=$username; AuthToken_usdev=$token" \
        -H 'origin: https://movement.qa-integration.p-44.com' \
        -H 'referer: https://movement.qa-integration.p-44.com/' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
}

# Get full data for all trials
get_trials_full_info() {
    # Check arg count and npe, assign values
    # Requirement checks
    # Function logic
    local base_url=$(resolve_env_to_api_base_url "$glb_env_name")
    local integration_string="$glb_mode.$glb_service.$glb_interaction.$glb_carrier"
    local username=$glb_username
    local token=$glb_token
    local trials_basic_response=$(get_trials_basic_info)

    # Extract trial IDs from the raw JSON array and get full trial details
    echo "$trials_basic_response" | jq -r '.[].trialId' | while read -r trial_id; do
        get_trial "$trial_id"
    done | jq -s '.'  # Combine all full trials into a JSON array
}



###################################################################################################
###################################### Implemented action functions ###############################
###################################################################################################



# Download all trials and export to file
export_trials_to_file() {
    echo "Info: Downloading trials data..."
    local response=$(get_trials_full_info)
    echo "Info: Exporting trials to file '$glb_trials_export_file_name'..."
    echo "$response" > "$glb_trials_export_file_name"
}

# Update all trials using input file
# $1 - input file path
update_trials_from_file() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local trials_file_path=$1
    # Requirement checks
    # Function logic
    local trials_response=$(get_trials_full_info)
    echo "$trials_response" > "$glb_trials_backup_file_name"
    echo "Creating a backup of trials in file '$glb_trials_backup_file_name'."

    mapfile -t trial_jsons < <(jq -c '.[]' "$trials_file_path")

    for trial in "${trial_jsons[@]}"; do
        trial_id=$(jq -r '.trialId' <<< "$trial")
        display_name=$(jq -r '.displayName' <<< "$trial")
        description=$(jq -r '.description' <<< "$trial")
        
        echo "Updating trial: '$trial_id' with display name: '$display_name' and description: '$description'"
        update_trial_from_payload "$trial"
    done
}

# Update all trials using a specific trial name
# $1 - trial name
update_trials_from_name() {
    # Check arg count and npe, assign values
    check_args 1 "$@"
    local trial_name=$1
    # Requirement checks
    # Function logic
    local trials_response=$(get_trials_full_info)
    echo "$trials_response" > "$glb_trials_backup_file_name"
    echo "Creating a backup of trials in file '$glb_trials_backup_file_name'."
    
    source_trial_json=$(jq -c --arg name "$trial_name" '.[] | select(.displayName == $name)' <<< "$trials_response" | head -n1)
    source_trial_id=$(jq -r '.trialId' <<< "$source_trial_json")
    source_display_name=$(jq -r '.displayName' <<< "$source_trial_json")
    source_description=$(jq -r '.description' <<< "$source_trial_json")

    echo "Using values from trial: '$source_trial_id' with display name: '$source_display_name' and description '$source_description'"

    mapfile -t target_trials < <(jq -c '.[]' <<< "$trials_response")

    for target_trial in "${target_trials[@]}"; do
        target_trial_id=$(jq -r '.trialId' <<< "$target_trial")
        target_display_name=$(jq -r '.displayName' <<< "$target_trial")
        target_description=$(jq -r '.description' <<< "$target_trial")
        modified_payload=$(jq \
            --arg trialId "$target_trial_id" \
            --arg displayName "$target_display_name" \
            --arg description "$target_description" \
            '.trialId = $trialId | .displayName = $displayName | .description = $description' \
            <<< "$source_trial_json")
        
        echo "Updating trial: '$target_trial_id' with display name: '$target_display_name' and description: '$target_description'"
        update_trial_from_payload "$modified_payload"
    done
}



###########################################################################################################################
############################################ Flags checks and function calls ##############################################
###########################################################################################################################



# If any args are passed, check if dependencies are installed
if [ "$flg_args_passed" == "true" ]; then
    check_dependencies
fi

# General option calls

# Check for updates
if [ "$flg_chk_for_updates" == "true" ]; then
    check_for_updates
    # exit 0
fi

# Install
if [ "$do_install" == "true" ] || [ "$do_install_y" == "true" ]; then
    install_script
    exit 0
fi

# Uninstall
if [ "$do_uninstall" == "true" ]; then
    uninstall_script
    exit 0
fi

# Check installation
if [ "$do_chk_install" == "true" ]; then
    check_installation
    exit 0
fi

# Generate env file
if [ "$flg_generate_env_file" == "true" ]; then
    generate_env_file
    exit 0
fi

# Action calls

# Get trials
if [ "$flg_export_trials" == "true" ]; then
    export_trials_to_file
fi

# Update trials from file
if [ "$flg_update_trials_from_file" == "true" ]; then
    update_trials_from_file "$glb_trials_file_path"
fi

# Update trials from trial name
if [ "$flg_update_trials_from_name" == "true" ]; then
    update_trials_from_name "$glb_trial_name"
fi



###################################################################################################
############################################ Cleanup ##############################################
###################################################################################################



# Remove temporary download folders
# for dir in "tmp_util4trials"*; do
#     if [ -d "$dir" ]; then
#         rm -r "$dir"
#     fi
# done

echo "Info: Script completed."
