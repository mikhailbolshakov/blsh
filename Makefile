YOUR_ADDRESS :=     cd6b79***
RECEIVER_ADDRESS := dc55464***
USER_ADDRESS := c9411***
PROFILE := blsh-admin-dev
RECEIVER_PROFILE := blsh-reciever-dev

compile:
	aptos move compile --named-addresses blsh=$(PROFILE)

publish:
	aptos move publish --profile $(PROFILE) --named-addresses blsh=$(PROFILE)	

mint:
	aptos move run \
		--function-id "$(YOUR_ADDRESS)::blsh_coin::mint" \
		--args address:$(YOUR_ADDRESS) u64:100000000000 \
		--profile $(PROFILE)

balance:
	aptos move view \
		--function-id "$(YOUR_ADDRESS)::blsh_coin::get_balance" \
		--args address:$(YOUR_ADDRESS) \
		--profile $(PROFILE)

transfer:
	aptos move run \
		--function-id "$(YOUR_ADDRESS)::blsh_coin::transfer" \
		--args address:$(RECEIVER_ADDRESS) u64:50000000000 \
		--profile $(PROFILE)

receiver-balance:
	aptos move view \
		--function-id "$(YOUR_ADDRESS)::blsh_coin::get_balance" \
		--args address:$(RECEIVER_ADDRESS) \
		--profile $(PROFILE)

user-balance:
	aptos move view \
		--function-id "$(YOUR_ADDRESS)::blsh_coin::get_balance" \
		--args address:$(USER_ADDRESS) \
		--profile $(PROFILE)		

transfer-rec-to-user:
	aptos move run \
		--function-id "$(YOUR_ADDRESS)::blsh_coin::transfer" \
		--args address:$(USER_ADDRESS) u64:5000 \
		--profile $(RECEIVER_PROFILE)

get-metadata:
	aptos move view \
		--function-id "$(YOUR_ADDRESS)::blsh_coin::get_metadata" \
		--profile $(PROFILE)		