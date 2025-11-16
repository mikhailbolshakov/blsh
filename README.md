# BLSH Coin – Aptos Move Fungible Token

BLSH is a fungible token implemented in Move for the Aptos blockchain.  
This repository contains the Move module, package configuration, and helper Makefile targets to compile, publish, and interact with the token.

> **Security note**  
> This repo is for learning/demo purposes. Do **not** use any included keys or accounts in production. Always generate and securely store your own keys.

---

## Prerequisites

- [Aptos CLI](https://aptos.dev/tools/aptos-cli/install-cli/)
- Git
- Make (for using the provided `Makefile`)
- An Aptos account on Devnet or Testnet (or both, depending on which network you want to use)

---

## Project Structure (Short)

- `Move.toml` – Move package configuration
- `sources/coin.move` – Move module that defines the BLSH fungible token
- `Makefile` – Helper commands to compile, publish, and interact with the module
- `.aptos/config.yaml` – Aptos CLI profiles (local-only; do not reuse in production)
- `README.md` – This file

---

## Configuration

### Aptos profiles

The project uses Aptos CLI profiles defined in `.aptos/config.yaml` to connect to Devnet/Testnet and sign transactions.

You can either:

1. **Use your own profiles**

   Initialize and configure your own profiles:

   ```bash
   aptos init --profile my-admin
   ```

Then update:
- `YOUR_ADDRESS`, `RECEIVER_ADDRESS`, `USER_ADDRESS`
- `PROFILE`, `RECEIVER_PROFILE`

in the `Makefile` to match your accounts and profiles.

2. **Use the existing profile names**

   Keep the existing profile names but **replace the keys and addresses** in `.aptos/config.yaml` with your own generated ones via `aptos init`.

> Recommended: Always work with your own keys and addresses.

---

## Building

To compile the Move package:
```
bash make compile
``` 

Internally this runs:
```
bash aptos move compile --named-addresses blsh=
```

`PROFILE` is defined in the `Makefile` and should point to the admin profile that will own the module.

---

## Publishing the Module

To publish the module to the network:
```
bash make publish
``` 

This runs:
```

bash aptos move publish
--profile --named-addresses blsh=
```

After publishing, the module will be available under:
```

text <YOUR_ADDRESS>::blsh_coin
``` 

where `<YOUR_ADDRESS>` corresponds to the account configured as the named address `blsh`.

---

## Interacting With the Token

The `Makefile` defines convenient targets to interact with the token via Aptos CLI.

### Mint tokens

Mint tokens from the admin account to `YOUR_ADDRESS`:
```

bash make mint
```

This calls:
```
text <YOUR_ADDRESS>::blsh_coin::mint(address, u64)
``` 

Update the amount inside the `Makefile` or modify the Makefile to accept parameters if you need variable amounts.

---

### Check balances

Check the admin/user balance:
```
bash make balance
```

Check the receiver balance:
```

bash make receiver-balance
``` 

Check another user’s balance:
```

bash make user-balance
```

All of these call the view function:
```

text <YOUR_ADDRESS>::blsh_coin::get_balance(address): u64
``` 

---

### Transfer tokens

Transfer from admin to receiver:
```

bash make transfer
```

Transfer from receiver to user:
```

bash make transfer-rec-to-user
``` 

Both call:
```

text <YOUR_ADDRESS>::blsh_coin::transfer(&signer, address, u64)
```

The signing profile is determined by `PROFILE` or `RECEIVER_PROFILE` in the `Makefile`.

---

### View metadata

To retrieve the on-chain metadata object address:
```

bash make get-metadata
``` 

This calls:
```

text <YOUR_ADDRESS>::blsh_coin::get_metadata(): object
```

You can then inspect the metadata via Aptos explorers or via additional CLI calls.

---

## Customization

You can customize the token by modifying the Move module in `sources/coin.move`, for example:

- Token name
- Symbol
- Decimals
- Icon URI / project URL
- Access control logic (who can mint, burn, freeze accounts, etc.)

After any change:

1. Re-compile:

   ```bash
   make compile
   ```

2. Re-publish (on a fresh account, or with upgrade rules that you control):

   ```bash
   make publish
   ```

---

## Testing

The module includes Move unit tests. To run them:
```

bash aptos move test
``` 

This will execute the tests defined in the module (e.g., mint/transfer/burn workflow, freeze/unfreeze behavior).

---

## Notes & Best Practices

- **Never commit real production keys** to version control.
- Use separate profiles/accounts for:
  - Development/experimentation
  - Testnet
  - Mainnet
- Before deploying to mainnet:
  - Thoroughly review the Move code.
  - Add more tests for your business logic.
  - Consider a security review.

---

## License

Apache-2.0

