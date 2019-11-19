function usage() {
    printf "${0} OPTIONS

Assume AWS role

OPTIONS

    -r          role name (required)
    -h          print this message and exit

"
    exit 2
}

function required() {
    local name=$1
    local opt=$2

    if ! [ ${!name} ]; then
        echo "error: missing required argument ${opt}"
        exit 1
    fi
}

while getopts "r:" opt; do
    case $opt in
    r) role=$OPTARG;;
    h) usage ;;
    *) usage ;;
    esac
done

required role -r

account_id=$(aws sts get-caller-identity | jq .Account | sed s/\"//g)
if ! [ $account_id ]; then
    echo "error: unable to get AWS account ID"
    exit 1
fi

aws sts assume-role \
        --role-arn arn:aws:iam::${account_id}:role/${role} \
        --role-session-name AWSCLI-Session \
    | jq '.Credentials|[.AccessKeyId, .SecretAccessKey, .SessionToken]' \
    | sed 's/,//g' \
    | sed 's/\[//g' \
    | sed 's/\]//g' \
    | sed 's/\"//g' \
    | awk 'NF' \
    | awk 'BEGIN { \
        names[0]="AWS_ACCESS_KEY_ID"; \
        names[1]="AWS_SECRET_ACCESS_KEY"; \
        names[2]="AWS_SESSION_TOKEN"; \
    } { print names[NR-1]"="$1 }'
