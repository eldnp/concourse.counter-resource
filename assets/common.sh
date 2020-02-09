includeDriver() {
  local driver=$1
  local file="$(dirname $0)/drivers/$1.sh"
  if [ ! -f "$file" ]; then
    echo "Error: driver $driver not found." >&2
    exit 1
  fi
  source $file
}

process() {
  local step=$(jq -r '.source.step // 1' < $1)
  local inc=$(jq -r '.params.inc // -1' < $1)
  local dec=$(jq -r '.params.dec // -1' < $1)
  local number=$2
  local newNumber=$number

  # increment
  if [ "$inc" == "true"  ]; then
    inc=$step
  fi
  if [ "$inc" -gt "0"  ]; then
    newNumber=$(($number + $inc))
    echo "increased locally from $number to $newNumber" >&2
    number=$newNumber #for decrement if exists
  fi

  # decrement
  if [ "$dec" == "true"  ]; then
    dec=$step
  fi
  if [ "$dec" -gt "0"  ]; then
    newNumber=$(($number - $dec))
    echo "decreased locally from $number to $newNumber" >&2
  fi

  echo $newNumber
}
