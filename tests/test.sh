#/bin/bash

COLORS_ON=1

. lib.sh || exit 1

section "Tasks in this role:"
ansible-playbook -i hosts playbook.yml --list-tasks

section "Check syntax..."
ansible-playbook -i hosts playbook.yml --syntax-check
exit_code_syntax_check=$?

section "Run linter..."
ansible-lint playbook.yml
exit_code_linter=$?

section "Run role..."
ansible-playbook -i hosts playbook.yml
exit_code_role_execution=$?

ansible-playbook -i hosts playbook.yml > idempotence_output

section "Idempotence check..."
./idempotence_check.sh idempotence_output
exit_code_idempotence_test=$?

if [ -f suite.bats ]; then
  section "Integration tests..."
  bats suite.bats
  exit_code_integration_tests=$?
fi

section 'Report'
echo "Syntax check: $(exit_code_msg $exit_code_syntax_check)"
echo "Ansible lint: $(exit_code_msg $exit_code_linter)"
echo "Execution: $(exit_code_msg $exit_code_role_execution)"
echo "Idempotence test: $(exit_code_msg $exit_code_idempotence_test)"
if [ ! -z $exit_code_integration_tests ]; then
  echo "Integration tests: $(exit_code_msg $exit_code_integration_tests)"
fi

[ $exit_code_syntax_check -eq 0 ] \
        && [ $exit_code_linter -eq 0 ] \
        && [ $exit_code_role_execution -eq 0 ] \
        && [ $exit_code_idempotence_test -eq 0 ] \
        && [ ${exit_code_integration_tests:-0} -eq 0 ] \
        && :
exit_code=$?

exit_code_msg $exit_code
echo

exit $exit_code
