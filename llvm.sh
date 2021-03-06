#!/bin/bash
function repo_init() {
	UPSTREAM=$1
	WORKING_DIR=$2
	git clone --mirror $UPSTREAM $WORKING_DIR
}

function repo_update() {
	UPSTREAM=$1
	repo_dir="$2"
	cd $repo_dir
	echo "==== SYNC $repo_dir START ===="
	git remote set-url origin "$UPSTREAM"
	/usr/bin/timeout -s INT 3600 git remote -v update -p
	head=$(git remote show origin | awk '/HEAD branch:/ {print $NF}')
	[[ -n "$head" ]] && echo "ref: refs/heads/$head" > HEAD
	objs=$(find objects/ -type f | wc -l)
	[[ "$objs" -gt 8 ]] && git repack -a -b -d
	sz=$(git count-objects -v|grep -Po '(?<=size-pack: )\d+')
	total_size=$(($total_size+1024*$sz))
	echo "==== SYNC $repo_dir DONE ===="
}

UPSTREAM_BASE=${TUNASYNC_UPSTREAM_URL:-"https://llvm.org/git"}
repos=("llvm" "clang" "libcxx" "lldb" "clang-tools-extra" "polly" "zorg" "compiler-rt" "libcxxabi" "lld" "lnt")
total_size=0

for repo in ${repos[@]}; do
	if [[ ! -d "$TUNASYNC_WORKING_DIR/${repo}.git" ]]; then
		echo "Initializing ${repo}.git"
		repo_init "${UPSTREAM_BASE}/${repo}" "$TUNASYNC_WORKING_DIR/${repo}.git"
	fi
	repo_update "${UPSTREAM_BASE}/${repo}" "$TUNASYNC_WORKING_DIR/${repo}.git"
done

echo "Total size is" $(numfmt --to=iec $total_size)
