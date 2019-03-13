#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load '../common'

setup() {
    export suiteName="domain-records"
}

@test "it should create a domain" {
    setToken $suiteName

    timestamp=$(date +%s)
    domainId=$(linode-cli domains list --format="id" --text --no-header)

    run linode-cli domains create \
        --type master \
        --domain "$timestamp-example.com" \
        --soa_email="pthiel@linode.com" \
        --text \
        --no-header

    assert_success
}

@test "it should create a domain SRV record" {
    getToken "$suiteName"
    echo "records test token is $LINODE_CLI_TOKEN" >&3

    domainId=$(linode-cli domains list --format="id" --text --no-header)

    run linode-cli domains records-create \
        --protocol=tcp \
        --type=SRV \
        --port=23 \
        --priority=4 \
        --service=telnet \
        --target=8.8.8.8 \
        --weight=4 $domainId \
        --text \
        --no-header \
        --delimiter=","

    assert_success
    assert_output --regexp "[0-9]+,SRV,_telnet.tcp._tcp,8.8.8.8,0,4,4"
}

@test "it should list the SRV record" {
    getToken "$suiteName"

    domainId=$(linode-cli domains list --format="id" --text --no-header)
    run linode-cli domains records-list $domainId \
        --text \
        --no-header \
        --delimiter=","

    assert_success
    assert_output --regexp "[0-9]+,SRV,_telnet.tcp._tcp,8.8.8.8,0,4,4"
}

@test "it should view domain record" {
    getToken "$suiteName"

    domainId=$(linode-cli domains list --format="id" --text --no-header)
    recordId=$(linode-cli domains records-list $domainId --text --no-header --format="id")

    run linode-cli domains records-view $domainId $recordId \
        --text \
        --no-header \
        --delimiter=","

    assert_success
    assert_output --regexp "[0-9]+,SRV,_telnet.tcp._tcp,8.8.8.8,0,4,4"
}

@test "it should update a domain record" {
    skip "BUG 969"

    domainId=$(linode-cli domains list --format="id" --text --no-header)
    recordId=$(linode-cli domains records-list $domainId --text --no-header --format="id")

    run linode-cli domains records-update $domainId $recordId \
        --target="8.8.4.4" \
        --text \
        --no-header \
        --delimiter=","

    assert_success
    assert_output --regexp "[0-9]+,SRV,_telnet.tcp._tcp,8.8.4.4,0,4,4"
}

@test "it should delete a domain record" {
    getToken "$suiteName"

    domainId=$(linode-cli domains list --format="id" --text --no-header)
    recordId=$(linode-cli domains records-list $domainId --text --no-header --format="id")

    run linode-cli domains records-delete $domainId $recordId

    assert_success
}

@test "it should delete all domains" {
    getToken "$suiteName"
    run removeDomains
    clearToken "$suiteName"
}
