#!/usr/bin/env bats

@test "nginx proxying request to application instances" {
    run curl -s http://10.0.2.15/
    [[ $output =~ ">The current ladder is:" ]]
}
