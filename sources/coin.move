module blsh::blsh_coin {
    use std::signer;
    use std::string::{Self, String};
    use std::option;
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;

    /// Errors
    const E_NOT_OWNER: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;

    /// Holds references to control the minting, transferring, and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    /// Initialize the module and create the fungible asset
    fun init_module(admin: &signer) {
        let constructor_ref = &object::create_named_object(admin, b"BLSH");
        
        // Create the fungible asset with metadata
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(), // Maximum supply (none = unlimited)
            string::utf8(b"Bolshakov coin"), // Name
            string::utf8(b"BLSH"), // Symbol
            8, // Decimals
            string::utf8(b"https://example.com/blsh-icon.png"), // Icon URI
            string::utf8(b"https://example.com/blsh"), // Project URI
        );

        // Generate mint, transfer, and burn references
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);

        // Store the refs so we can manage the fungible asset
        let managed_fungible_asset = ManagedFungibleAsset {
            mint_ref,
            transfer_ref,
            burn_ref,
        };
        move_to(admin, managed_fungible_asset);
    }

    /// Mint new tokens to a specified address
    public entry fun mint(
        admin: &signer,
        to: address,
        amount: u64,
    ) acquires ManagedFungibleAsset {
        let admin_address = signer::address_of(admin);
        assert!(exists<ManagedFungibleAsset>(admin_address), E_NOT_OWNER);
        
        let managed_fungible_asset = borrow_global<ManagedFungibleAsset>(admin_address);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, get_metadata());
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
    }

    /// Transfer tokens from one address to another
    public entry fun transfer(
        from: &signer,
        to: address,
        amount: u64,
    ) acquires ManagedFungibleAsset {
        let from_address = signer::address_of(from);
        let from_wallet = primary_fungible_store::primary_store(from_address, get_metadata());
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, get_metadata());
        
        // Check if sender has sufficient balance
        let balance = fungible_asset::balance(from_wallet);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);
        
        // For admin, we can use transfer_ref for forced transfers
        // For regular users, we use normal transfer
        if (exists<ManagedFungibleAsset>(from_address)) {
            let managed_fungible_asset = borrow_global<ManagedFungibleAsset>(from_address);
            fungible_asset::transfer_with_ref(
                &managed_fungible_asset.transfer_ref,
                from_wallet,
                to_wallet,
                amount
            );
        } else {
            // Regular transfer (requires approval from sender)
            primary_fungible_store::transfer(from, get_metadata(), to, amount);
        }
    }

    /// Burn tokens from a specified address
    public entry fun burn(
        admin: &signer,
        from: address,
        amount: u64,
    ) acquires ManagedFungibleAsset {
        let admin_address = signer::address_of(admin);
        assert!(exists<ManagedFungibleAsset>(admin_address), E_NOT_OWNER);
        
        let managed_fungible_asset = borrow_global<ManagedFungibleAsset>(admin_address);
        let from_wallet = primary_fungible_store::primary_store(from, get_metadata());
        let fa = fungible_asset::withdraw_with_ref(&managed_fungible_asset.transfer_ref, from_wallet, amount);
        fungible_asset::burn(&managed_fungible_asset.burn_ref, fa);
    }

    /// Freeze/unfreeze an account's ability to send/receive tokens
    public entry fun freeze_account(admin: &signer, account: address) acquires ManagedFungibleAsset {
        let admin_address = signer::address_of(admin);
        assert!(exists<ManagedFungibleAsset>(admin_address), E_NOT_OWNER);
        
        let managed_fungible_asset = borrow_global<ManagedFungibleAsset>(admin_address);
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, get_metadata());
        fungible_asset::set_frozen_flag(&managed_fungible_asset.transfer_ref, wallet, true);
    }

    public entry fun unfreeze_account(admin: &signer, account: address) acquires ManagedFungibleAsset {
        let admin_address = signer::address_of(admin);
        assert!(exists<ManagedFungibleAsset>(admin_address), E_NOT_OWNER);
        
        let managed_fungible_asset = borrow_global<ManagedFungibleAsset>(admin_address);
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, get_metadata());
        fungible_asset::set_frozen_flag(&managed_fungible_asset.transfer_ref, wallet, false);
    }

    /// View functions

    #[view]
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@blsh, b"BLSH");
        object::address_to_object<Metadata>(asset_address)
    }

    #[view]
    public fun get_balance(account: address): u64 {
        if (primary_fungible_store::primary_store_exists(account, get_metadata())) {
            let store = primary_fungible_store::primary_store(account, get_metadata());
            fungible_asset::balance(store)
        } else {
            0
        }
    }

    #[view]
    public fun get_total_supply(): u128 {
        let metadata = get_metadata();
        option::get_with_default(&fungible_asset::supply(metadata), 0)
    }

    #[view]
    public fun get_name(): String {
        fungible_asset::name(get_metadata())
    }

    #[view]
    public fun get_symbol(): String {
        fungible_asset::symbol(get_metadata())
    }

    #[view]
    public fun get_decimals(): u8 {
        fungible_asset::decimals(get_metadata())
    }

    #[view]
    public fun is_account_frozen(account: address): bool {
        if (primary_fungible_store::primary_store_exists(account, get_metadata())) {
            let store = primary_fungible_store::primary_store(account, get_metadata());
            fungible_asset::is_frozen(store)
        } else {
            false
        }
    }

    // Tests
    #[test_only]
    use aptos_framework::account;

    #[test(admin = @blsh, user1 = @0x456, user2 = @0x789)]
    public fun test_token_workflow(
        admin: &signer,
        user1: &signer,
        user2: &signer,
    ) acquires ManagedFungibleAsset {
        // Initialize the fungible asset
        init_module(admin);
        
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        
        // Mint tokens to user1
        mint(admin, user1_addr, 1000);
        assert!(get_balance(user1_addr) == 1000, 1);
        
        // Transfer from user1 to user2
        transfer(user1, user2_addr, 500);
        assert!(get_balance(user1_addr) == 500, 2);
        assert!(get_balance(user2_addr) == 500, 3);
        
        // Check total supply
        assert!(get_total_supply() == 1000, 4);
        
        // Burn some tokens
        burn(admin, user2_addr, 200);
        assert!(get_balance(user2_addr) == 300, 5);
        assert!(get_total_supply() == 800, 6);
    }

    #[test(admin = @blsh, user = @0x456)]
    public fun test_freeze_account(admin: &signer, user: &signer) acquires ManagedFungibleAsset {
        init_module(admin);
        
        let user_addr = signer::address_of(user);
        
        // Mint tokens to user
        mint(admin, user_addr, 1000);
        
        // Freeze account
        freeze_account(admin, user_addr);
        assert!(is_account_frozen(user_addr) == true, 1);
        
        // Unfreeze account
        unfreeze_account(admin, user_addr);
        assert!(is_account_frozen(user_addr) == false, 2);
    }
}