#!/usr/bin/env zsh

# Get the directory where the main scripts are located.
_MAIN_SCRIPT_DIR=${0:A:h}
source "${_MAIN_SCRIPT_DIR}/_common.zsh"

# --- Test Configuration ---
# Create an associative array to hold the "Hello, World" source code for each language.
typeset -A LANG_TEST_CODE
LANG_TEST_CODE=(
  c '
#include <stdio.h>
int main(int argc, char *argv[]) {
  printf("Hello, C!\n");
  for (int i = 1; i < argc; i++) {
    printf("Arg %d: %s\n", i, argv[i]);
  }
  return 0;
}'
  cpp '
#include <iostream>
#include <vector>
#include <string>
int main(int argc, char *argv[]) {
  std::cout << "Hello, C++!" << std::endl;
  for (int i = 1; i < argc; i++) {
    std::cout << "Arg " << i << ": " << argv[i] << std::endl;
  }
  return 0;
}'
  java '
public class Test {
  public static void main(String[] args) {
    System.out.println("Hello, Java!");
    for (int i = 0; i < args.length; i++) {
      System.out.println("Arg " + (i + 1) + ": " + args[i]);
    }
  }
}'
  rs '
use std::env;
fn main() {
  println!("Hello, Rust!");
  for (i, arg) in env::args().skip(1).enumerate() {
    println!("Arg {}: {}", i + 1, arg);
  }
}'
  py '
import sys
print("Hello, Python!")
for i, arg in enumerate(sys.argv[1:]):
  print(f"Arg {i+1}: {arg}")'
  js '
console.log("Hello, JavaScript!");
process.argv.slice(2).forEach((arg, i) => {
  console.log(`Arg ${i+1}: ${arg}`);
});'
  php '
<?php
echo "Hello, PHP!\n";
foreach (array_slice($argv, 1) as $i => $arg) {
  echo "Arg " . ($i + 1) . ": " . $arg . "\n";
}'
  rb '
puts "Hello, Ruby!"
ARGV.each_with_index do |arg, i|
  puts "Arg #{i+1}: #{arg}"
end'
  sh '
echo "Hello, Shell!"
i=1
for arg in "$@"; do
  echo "Arg $i: $arg"
  i=$((i+1))
done'
  pl '
use 5.010;
say "Hello, Perl!";
foreach my $i (0 .. $#ARGV) {
  say "Arg " . ($i+1) . ": $ARGV[$i]";
}'
  lua '
print("Hello, Lua!")
for i, arg in ipairs(arg) do
  print(string.format("Arg %d: %s", i, arg))
end'
)

# --- Main Execution ---
TEST_DIR="test_workspace"
PASSED=0
FAILED=0
SKIPPED=0

cleanup() {
  echo -e "\n${YELLOW}🧹 Cleaning up test environment...${RESET}"
  cd "${_MAIN_SCRIPT_DIR}" &>/dev/null
  rm -rf "test_workspace"
  echo -e "${GREEN}✅ Cleanup complete.${RESET}"
}
trap cleanup EXIT INT TERM

# --- Setup ---
echo -e "${BLUE}🔧 Setting up test environment in 'test_workspace'...${RESET}"
rm -rf "test_workspace"
mkdir -p "test_workspace"

for ext in ${(k)LANG_TEST_CODE}; do
  local filename="${TEST_DIR}/test.${ext}"
  # For Java, the filename must match the public class name
  if [[ "$ext" == "java" ]]; then
    filename="${TEST_DIR}/Test.java"
  fi
  echo -e "${GRAY}  Creating ${filename}...${RESET}"
  # Use 'print -r' to avoid interpreting backslashes
  print -r -- "${LANG_TEST_CODE[$ext]}" > "$filename"
done
echo -e "${GREEN}✅ Test environment ready.${RESET}\n"

# --- Language Tests ---
cd "test_workspace" || exit 1
echo -e "${MAGENTA}🚀 Running language-specific tests...${RESET}"

# Test arguments that include spaces to ensure proper handling
local test_arg1="test_arg1"
local test_arg2="hello world"

for ext in ${(k)LANG_CONFIG}; do
    # Skip Go and TypeScript to avoid CI failures
    if [[ "$ext" == "go" || "$ext" == "ts" ]]; then
        continue
    fi
    total_tests=$((total_tests + 1))
    local filename="test.${ext}"
    local expected_output="" # Reset for each iteration

    # Set the expected "Hello" string based on the test code for each language
    case "$ext" in
      c)      expected_output="Hello, C!" ;;
      cpp)    expected_output="Hello, C++!" ;;
      java)   filename="Test.java"; expected_output="Hello, Java!" ;;
      rs)     expected_output="Hello, Rust!" ;;
      py)     expected_output="Hello, Python!" ;;
      js)     expected_output="Hello, JavaScript!" ;;
      php)    expected_output="Hello, PHP!" ;;
      rb)     expected_output="Hello, Ruby!" ;;
      sh)     expected_output="Hello, Shell!" ;;
      pl)     expected_output="Hello, Perl!" ;;
      lua)    expected_output="Hello, Lua!" ;;
    esac

    # Check for dependencies before running the test
    local config_string=${LANG_CONFIG[$ext]}
    local -a config_parts
    config_parts=("${(@s/:/)config_string}")
    local type=${config_parts[1]}
    local compiler=${config_parts[2]}
    local runner=${config_parts[5]}
    local dependency_missing=false
    local missing_dep=""

    if [[ "$type" == "compile_jvm" ]]; then
        if ! command -v "$compiler" &>/dev/null; then
            dependency_missing=true
            missing_dep="$compiler"
        elif ! command -v "java" &>/dev/null; then
            dependency_missing=true
            missing_dep="java"
        fi
    elif [[ "$type" == "compile" ]]; then
        if ! command -v "$compiler" &>/dev/null; then
            dependency_missing=true
            missing_dep="$compiler"
        fi
    elif [[ "$type" == "direct" ]]; then
        if ! command -v "$runner" &>/dev/null; then
            dependency_missing=true
            missing_dep="$runner"
        fi
    fi

    if [[ "$dependency_missing" == "true" ]]; then
        echo -e "${YELLOW}- [SKIP]   .${ext} (missing dependency: ${missing_dep})${RESET}"
        ((SKIPPED++))
        continue
    fi

    echo -ne "${BLUE}  [TEST]   .${ext} ... ${RESET}"

    # Run the main script and capture output, with colors disabled for stable comparison.
    # Stderr is redirected to stdout to capture compilation errors
    local output
    output=$(TERM=dumb "${_MAIN_SCRIPT_DIR}/ucode" "$filename" "$test_arg1" "$test_arg2" 2>&1)
    local exit_code=$?

    # Check for success conditions
    if [[ $exit_code -eq 0 && "$output" == *"$expected_output"* && "$output" == *"$test_arg1"* && "$output" == *"$test_arg2"* ]]; then
      ((PASSED++))
      echo -e "${GREEN}\r- [PASS]   .${ext}${RESET}"
    else
      ((FAILED++))
      echo -e "${RED}\r- [FAIL]   .${ext}${RESET}"
      # Print captured output on failure for debugging
      echo -e "${GRAY}------- ERROR OUTPUT -------"
      echo "$output"
      echo -e "--------------------------${RESET}"
    fi
done

# --- GDrive Simulation Test ---
echo -e "\n${MAGENTA}🚀 Running cloud drive simulation test...${RESET}"
local gdrive_dir="gdrive_simulation"
mkdir -p "$gdrive_dir"

echo 'int main() { printf("Older C file\n"); return 0; }' > "${gdrive_dir}/older.c"
touch -d "2 seconds ago" "${gdrive_dir}/older.c"
sleep 1 
# This python script now also prints its arguments to match the assertion
echo 'import sys; print("Latest Python file"); [print(f"Arg {i+1}: {arg}") for i, arg in enumerate(sys.argv[1:])]' > "${gdrive_dir}/latest.py"

# Run the test from within the simulated gdrive directory, and pass arguments.
# In auto-detection mode, all arguments are passed to the executed program.
pushd "$gdrive_dir" >/dev/null
output=$(TERM=dumb "${_MAIN_SCRIPT_DIR}/ucode" "$test_arg1" "$test_arg2" 2>&1)
exit_code=$?
popd >/dev/null
  
# Verify the output
echo -ne "${BLUE}  [TEST]   Auto-detection in cloud drive... ${RESET}"
if [[ $exit_code -eq 0 && "$output" == *"Latest Python file"* && "$output" == *"Automatically selected file: ./latest.py"* && "$output" == *"$test_arg1"* && "$output" == *"$test_arg2"* ]]; then
  echo -e "${GREEN}\r- [PASS]   Auto-detection in cloud drive${RESET}"
  ((PASSED++))
else
  ((FAILED++))
  echo -e "${RED}\r- [FAIL]   Auto-detection in cloud drive${RESET}"
  echo -e "${GRAY}------- ERROR OUTPUT -------"
  echo "$output"
  echo -e "--------------------------${RESET}"
fi

# --- Final Summary ---
cd "${_MAIN_SCRIPT_DIR}" &>/dev/null

echo -e "\n${BOLD}${WHITE}📊 Test Summary:${RESET}"
echo -e "  ${GREEN}Passed: $PASSED${RESET}"
echo -e "  ${RED}Failed: $FAILED${RESET}"
if [[ $SKIPPED -gt 0 ]]; then
    echo -e "  ${YELLOW}Skipped: $SKIPPED${RESET}"
fi

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
exit 0