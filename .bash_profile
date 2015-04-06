alias ls='ls -la -G'

export XCODE_LOCATION="/Applications/Xcode.app"
export XCODEBUILD_LOCATION="${XCODE_LOCATION}/Contents/Developer/usr/bin"
export CODESIGN_ALLOCATE="${XCODE_LOCATION}/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate"
if [[ -z /usr/bin/codesign_allocate ]]; then
    ln -s "/usr/bin/codesign_allocate" "${XCODE_LOCATION}/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate"
fi

# find a string, first parameter is required (the term), and optional 2nd parameter is the file to limit the search to
function get() {
    grep -I -r -n "$1" ${2:-.}
}

# exit the current branch and return to master, can specify a 1st parameter for the upstream/source remote, and 2nd being the home branch
function gohome() {
    git reset --hard HEAD &&
    git checkout ${2:-master} &&
    git pull ${1:-upstream} ${2:-master}  &&
    git push &&
    git branch -l
}

# a LoC count of all the current code files in the given folder
function howmany() {
    git ls-files | xargs | wc -l *.h *.m | sort -n -r
}

# prints stats broken down by each person
function blame() {
    git ls-files -i --exclude=*.h --exclude=*.m -z | xargs -0n1 git blame -w | ruby -n -e '$_ =~ /^.*\((.*?)\s[\d]{4}/; puts $1.strip' | sort -f | uniq -c | sort -n
}

# takes the current staged and unstaged changes and rolls it into the previous commit, may specify a parameter for the upstream remote to push to
function compact() {
    name=`git log -1 --pretty=%B`
    git reset --soft HEAD~1 &&
    git add --all &&
    git commit -m "${name}" &&
    git push -f ${1:-origin}
}

# starts a rebase against master or continues it, a parameter allows non-master rebases
function rebase() {
    if [ -a "./.git/rebase-apply" ]; then
        git add --all
        git rebase --continue
    else
        git rebase ${1:-master}
    fi
}

# adds all the current changes to the staged changes
function all() {
    git add --all
}

# creates a commit, no args use a garbage commit message
function commit() {
    git commit -m "${1:-foobar}"
}

# creates a csv, which reports the LoC count of the repo, 1st parameter is the project folder to report on
function code_report() {
    rm ../report.csv &> /dev/null
    touch ../report.csv
    cd $1
    i=0
    for commit in `git rev-list master`; do
        git checkout $commit &> /dev/null
        i=$((i + 1))
        echo "${commit} ${i}"
        for first_line in `git ls-files | xargs | wc -l *.h *.m | sort -n -r`; do
            echo "${first_line}, ${commit}" >> ../../report.csv
            break
        done
        git reset --hard HEAD &> /dev/null
    done
    cd ..
}
