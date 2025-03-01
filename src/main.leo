import token_registry.aleo;

// The 'compliant_token' program with a unique participation restriction.
program sushant_token_faucet_program.aleo {
  // Constants defining the token parameters.
  const COMPLAINT_TOKEN_ID: field = 9141392167392299637368214875764field; // Unique token identifier
  const ADMIN_ADDRESS: address = aleo1gxnumv92wz9jqn5awhzv0wer4mwanfnutnvrpcf9frf7m3qp0cpqj9jnrt; // Admin address
  const MAX_SUPPLY: u128 = 1_000_000_000_000_000u128; // Maximum supply of the token
  const MAX_SPEND_PER_DAY: u128 = 10_000_000_000u128; // Daily spending limit per user
  const MAX_U32: u32 = 4294967295u32; // Maximum value of a u32, used for transaction expiration

  // Record defining the spend limit for a user.
  record SpendLimit {
    owner: address,      // The owner of the spend limit
    amount_spent: u128,  // Amount spent in the current epoch
    epoch_spent: u32     // The epoch in which the last transaction occurred
  }

  // Mapping to track whether the token has been minted (prevents multiple minting).
  mapping has_minted: u8 => bool;
  
  // Mapping to track whether a user has an active spend limit.
  mapping has_spend_limit: field => bool;

  // Mapping to track used unique identifiers for claiming funds.
  mapping used_identifiers: field => bool;

  /**
   * Initializes the compliant token by registering it with the token registry.
   * Can only be called by the ADMIN_ADDRESS.
   */
  async transition initialize() -> Future {
    assert_eq(self.caller, ADMIN_ADDRESS);

    let name: u128 = 9141392167392299637368214875764u128; // "san_compliant" encoded in ASCII
    let symbol: u128 = 9141392167392299637368214875764u128; // "compliant" encoded in ASCII
    let decimals: u8 = 6u8; // Decimal places for the token
    let max_supply: u128 = 10_000_000_000_000_000u128; // Maximum supply
    let external_authorization_required: bool = true; // Requires external authorization
    let external_authorization_party: address = self.address; // Authorization controlled by this contract

    // Register the token in the token registry
    let f0: Future = token_registry.aleo/register_token(
      COMPLAINT_TOKEN_ID,
      name,
      symbol,
      decimals,
      max_supply,
      external_authorization_required,
      external_authorization_party
    );

    return finalize_register_token(f0);
  }

  /**
   * Awaits the completion of the token registration process.
   */
  async function finalize_register_token(f0: Future) {
    f0.await();
  }

  /**
   * Claims funds from the faucet.
   * Requires a unique identifier that hasn’t been used before.
   */
  async transition get_funds(
    public unique_id: field // A unique identifier (e.g., hash of user's personal data)
  ) -> Future {
    let f0: Future = token_registry.aleo/mint_public(COMPLAINT_TOKEN_ID, self.caller, 100000000u128, MAX_U32);
    return finalize_get_funds(f0, unique_id);
  }

  async function finalize_get_funds(f0: Future, unique_id: field) {
    f0.await();
    let is_used: bool = used_identifiers.get_or_use(unique_id, false);
    assert(!is_used); // Ensure the unique identifier hasn’t been used before
    used_identifiers.set(unique_id, true); // Mark the identifier as used
  }

  /**
   * Mints the maximum supply of tokens to the ADMIN_ADDRESS.
   * Can only be called once by the ADMIN_ADDRESS.
   */
  async transition mint_private() -> (token_registry.aleo/Token, Future) {
    assert_eq(self.caller, ADMIN_ADDRESS);
    
    // Mint private tokens to the admin
    let mint_output: (token_registry.aleo/Token, Future) = token_registry.aleo/mint_private(
      COMPLAINT_TOKEN_ID,
      ADMIN_ADDRESS,
      MAX_SUPPLY,
      true,
      MAX_U32
    );

    return (mint_output.0, finalize_mint_private(mint_output.1));
  }

  /**
   * Finalizes the minting process and ensures that tokens are minted only once.
   */
  async function finalize_mint_private(f0: Future) {
    f0.await();

    let has_already_minted: bool = has_minted.contains(0u8);
    assert(!has_already_minted); // Ensure tokens are minted only once
    has_minted.set(0u8, true);
  }

  /**
   * Issues a new spend limit record for a specific user.
   * Can only be called by the ADMIN_ADDRESS.
   */
  transition issue_limit(
    owner: address
  ) -> SpendLimit {
    assert_eq(self.caller, ADMIN_ADDRESS);

    // Create a new spend limit record for the user
    return SpendLimit {
      owner: owner,
      amount_spent: 0u128,
      epoch_spent: 0u32
    };
  }

  /**
   * Transfers tokens privately while enforcing the user's spend limit.
   */
  async transition transfer_private(
    input_token: token_registry.aleo/Token,
    spend_limit: SpendLimit,
    amount: u128,
    recipient: address,
    public epoch: u32
  ) -> (SpendLimit, token_registry.aleo/Token, token_registry.aleo/Token, token_registry.aleo/Token, Future) {
    
    let updated_amount_spent: u128 = spend_limit.epoch_spent < epoch 
        ? amount 
        : amount + spend_limit.amount_spent;
    
    assert(updated_amount_spent <= MAX_SPEND_PER_DAY);

    let updated_spend_limit: SpendLimit = SpendLimit {
      owner: spend_limit.owner,
      amount_spent: updated_amount_spent,
      epoch_spent: epoch
    };

    let prehook_output: (token_registry.aleo/Token, token_registry.aleo/Token, Future) = token_registry.aleo/prehook_private(
      input_token,
      amount,
      MAX_U32
    );

    let transfer_output: (token_registry.aleo/Token, token_registry.aleo/Token, Future) = token_registry.aleo/transfer_private(
      recipient,
      amount,
      prehook_output.1
    );

    return (
      updated_spend_limit,
      prehook_output.0,
      transfer_output.0,
      transfer_output.1,
      finalize_transfer_private(prehook_output.2, transfer_output.2)
    );
  }

  /**
   * Finalizes the transfer process.
   */
  async function finalize_transfer_private(f0: Future, f1: Future) {
    f0.await();
    f1.await();
  }
}