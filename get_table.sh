
woolf_deployer=0xf87acad2d46e507ac5b4191ba93a23a6ec60b60e4d35ad6ff05d73f7f43eefad

curl https://fullnode.devnet.aptoslabs.com/v1/accounts/${woolf_deployer}/resource/${woolf_deployer}::barn::Pack | jq .data.items.handle

#curl -H 'Content-Type: application/json' --data '{"key_type":"u64","vector<Stake>":"address","key": "1"}' https://fullnode.devnet.aptoslabs.com/v1/tables/${handle}/item
