#!/usr/bin/env bash
# Test suite for ocxo-extract
# Run: bash ocxo-extract.test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/ocxo-extract"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
EXIT_CODE=0
OUTPUT=""

run_and_capture() {
  local input="$1"
  shift
  OUTPUT=""
  EXIT_CODE=0
  OUTPUT=$(echo "$input" | "$SCRIPT" "$@" 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  ((TESTS_RUN++))
  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}✓${NC} $msg"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $msg"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    ((TESTS_FAILED++))
  fi
}

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local msg="$3"
  ((TESTS_RUN++))
  if [[ "$haystack" == *"$needle"* ]]; then
    echo -e "${GREEN}✓${NC} $msg"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $msg"
    echo "  Expected to contain: $needle"
    echo "  Actual: $haystack"
    ((TESTS_FAILED++))
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  ((TESTS_RUN++))
  if [[ "$expected" -eq "$actual" ]]; then
    echo -e "${GREEN}✓${NC} $msg"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $msg"
    echo "  Expected exit code: $expected"
    echo "  Actual exit code: $actual"
    ((TESTS_FAILED++))
  fi
}

echo "=== ocxo-extract Test Suite ==="
echo

# Test 1: Handle error response
echo -e "${YELLOW}Test Group: Error Handling${NC}"
ERROR_JSON='{"type":"error","timestamp":1772259581905,"sessionID":"ses_35d18ef46ffendSjVREJ9315fn","error":{"name":"APIError","data":{"message":"Forbidden: token disabled","statusCode":403}}}'
run_and_capture "$ERROR_JSON" final-text
assert_exit_code 1 "$EXIT_CODE" "Error response returns exit code 1"
assert_contains "Error:" "$OUTPUT" "Error response contains Error prefix"
assert_contains "APIError" "$OUTPUT" "Error response contains error name"
assert_contains "403" "$OUTPUT" "Error response contains status code"
assert_contains "ses_35d18ef46ffendSjVREJ9315fn" "$OUTPUT" "Error response contains session ID"

# Test 2: Handle complex error (like the real example)
COMPLEX_ERROR='{"type":"error","timestamp":1772259581905,"sessionID":"ses_35d18ef46ffendSjVREJ9315fn","error":{"name":"APIError","data":{"message":"Forbidden: {\"error\":{\"code\":\"\",\"message\":\"令牌分组 aws-q-sale 已被禁用 (request id: 20260228141941559322744bC9b3Q1w)\",\"type\":\"packy_api_error\"}}","statusCode":403,"isRetryable":false}}}'
run_and_capture "$COMPLEX_ERROR" final-text
assert_exit_code 1 "$EXIT_CODE" "Complex error response returns exit code 1"
assert_contains "APIError" "$OUTPUT" "Complex error contains error name"

# Test 3: Handle non-JSON lines mixed with JSON
echo -e "\n${YELLOW}Test Group: Non-JSON Handling${NC}"
MIXED_INPUT='Some debug output
{"type":"text","sessionID":"ses_test123","part":{"text":"Hello world","messageID":"msg1"}}
Another non-JSON line
{"type":"step_finish","sessionID":"ses_test123","part":{"messageID":"msg1"}}'
run_and_capture "$MIXED_INPUT" final-text
assert_exit_code 0 "$EXIT_CODE" "Mixed JSON/non-JSON returns exit code 0"
assert_contains "Hello world" "$OUTPUT" "Extracts text from mixed input"
assert_contains "ses_test123" "$OUTPUT" "Extracts session from mixed input"

# Test 4: Handle only non-JSON (should error)
ONLY_NON_JSON='This is just plain text
No JSON here at all'
run_and_capture "$ONLY_NON_JSON" final-text
assert_exit_code 1 "$EXIT_CODE" "Only non-JSON returns exit code 1"
assert_contains "No valid JSON" "$OUTPUT" "Non-JSON only shows error message"

# Test 5: Handle empty input
echo -e "\n${YELLOW}Test Group: Edge Cases${NC}"
run_and_capture "" final-text
assert_exit_code 1 "$EXIT_CODE" "Empty input returns exit code 1"
assert_contains "No input" "$OUTPUT" "Empty input shows error message"

# Test 6: Handle null text result
NULL_TEXT_JSON='{"type":"other","sessionID":"ses_test"}'
run_and_capture "$NULL_TEXT_JSON" final-text
assert_exit_code 1 "$EXIT_CODE" "No text content returns exit code 1"
assert_contains "No text content found" "$OUTPUT" "Null text shows error message"

# Test 7: Normal last-text extraction
echo -e "\n${YELLOW}Test Group: Normal Extraction${NC}"
NORMAL_INPUT='{"type":"text","sessionID":"ses_normal","part":{"text":"First text"}}
{"type":"text","sessionID":"ses_normal","part":{"text":"Last text"}}'
run_and_capture "$NORMAL_INPUT" last-text --no-session
assert_exit_code 0 "$EXIT_CODE" "last-text returns exit code 0"
assert_equals "Last text" "$OUTPUT" "last-text extracts last text"

# Test 8: final-text extraction
FINAL_INPUT='{"type":"text","sessionID":"ses_final","part":{"text":"Final message text","messageID":"msg_final"}}
{"type":"step_finish","sessionID":"ses_final","part":{"messageID":"msg_final"}}'
run_and_capture "$FINAL_INPUT" final-text --no-session
assert_exit_code 0 "$EXIT_CODE" "final-text returns exit code 0"
assert_equals "Final message text" "$OUTPUT" "final-text extracts correct text"

# Test 9: before-finish extraction
BEFORE_FINISH_INPUT='{"type":"text","sessionID":"ses_before","part":{"text":"Text before finish","messageID":"msg_before"}}
{"type":"step_finish","sessionID":"ses_before","part":{"messageID":"msg_before"}}'
run_and_capture "$BEFORE_FINISH_INPUT" before-finish --no-session
assert_exit_code 0 "$EXIT_CODE" "before-finish returns exit code 0"
assert_equals "Text before finish" "$OUTPUT" "before-finish extracts correct text"

# Test 10: --no-session flag
run_and_capture "$NORMAL_INPUT" last-text
WITH_SESSION_OUTPUT="$OUTPUT"
run_and_capture "$NORMAL_INPUT" last-text --no-session
NO_SESSION_OUTPUT="$OUTPUT"
assert_contains "Session:" "$WITH_SESSION_OUTPUT" "Without --no-session shows session"
((TESTS_RUN++))
if [[ "$NO_SESSION_OUTPUT" == *"Session:"* ]]; then
  echo -e "${RED}✗${NC} --no-session flag hides session"
  ((TESTS_FAILED++))
else
  echo -e "${GREEN}✓${NC} --no-session flag hides session"
  ((TESTS_PASSED++))
fi

# Test 11: Unknown subcommand
run_and_capture "$NORMAL_INPUT" unknown-cmd
assert_exit_code 1 "$EXIT_CODE" "Unknown subcommand returns exit code 1"
assert_contains "Unknown subcommand" "$OUTPUT" "Unknown subcommand shows error"

# Test 12: Help flag
OUTPUT=$("$SCRIPT" --help 2>&1) && EXIT_CODE=0 || EXIT_CODE=$?
assert_exit_code 0 "$EXIT_CODE" "Help flag returns exit code 0"
assert_contains "last-text" "$OUTPUT" "Help shows last-text subcommand"
assert_contains "final-text" "$OUTPUT" "Help shows final-text subcommand"

# Summary
echo
echo "=== Test Summary ==="
echo -e "Tests run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed!${NC}"
  exit 1
fi
