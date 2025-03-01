## Compliance Rule: Proof of Unique Participation
To prevent multiple claims and ensure fairness, users must provide a **unique identifier** (e.g., a hash of personal data like an email or ID) when claiming funds. Each identifier can only be used once, enforced via the `used_identifiers` mapping. This ties claims to a unique off-chain identity rather than an address.

### Key Features
- Token faucet requiring a unique identifier per claim.
- Admin can mint the maximum supply and issue spend limits.
- Users can transfer tokens privately with a daily spend limit.