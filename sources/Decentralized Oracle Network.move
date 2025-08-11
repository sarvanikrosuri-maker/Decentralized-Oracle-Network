module hrithvika_addr::OracleNetwork {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing an oracle provider in the network.
    struct OracleProvider has store, key {
        stake_amount: u64,      // Amount staked by the oracle provider
        data_feeds: u64,        // Number of data feeds provided
        reputation_score: u64,  // Reputation score based on accuracy
        is_active: bool,        // Whether the provider is currently active
    }

    /// Struct representing a data feed from an oracle.
    struct DataFeed has store, key {
        value: u64,             // The data value provided by oracle
        timestamp: u64,         // When the data was submitted
        provider_count: u64,    // Number of providers who submitted this feed
        total_stake: u64,       // Total stake backing this data feed
    }

    /// Function to register a new oracle provider with stake.
    public fun register_oracle_provider(provider: &signer, stake_amount: u64) {
        let provider_addr = signer::address_of(provider);
        
        // Ensure provider doesn't already exist
        assert!(!exists<OracleProvider>(provider_addr), 1);
        
        // Minimum stake requirement
        assert!(stake_amount >= 1000, 2);
        
        // Transfer stake from provider
        let stake = coin::withdraw<AptosCoin>(provider, stake_amount);
        coin::deposit<AptosCoin>(provider_addr, stake);
        
        // Create oracle provider profile
        let oracle = OracleProvider {
            stake_amount,
            data_feeds: 0,
            reputation_score: 100, // Starting reputation
            is_active: true,
        };
        
        move_to(provider, oracle);
    }

    /// Function to submit data feed to the oracle network.
    public fun submit_data_feed(provider: &signer, data_value: u64) acquires OracleProvider, DataFeed {
        let provider_addr = signer::address_of(provider);
        
        // Verify provider is registered and active
        assert!(exists<OracleProvider>(provider_addr), 3);
        let oracle = borrow_global_mut<OracleProvider>(provider_addr);
        assert!(oracle.is_active, 4);
        
        // Update provider stats
        oracle.data_feeds = oracle.data_feeds + 1;
        
        // Create or update data feed
        let current_time = timestamp::now_seconds();
        
        if (exists<DataFeed>(provider_addr)) {
            let feed = borrow_global_mut<DataFeed>(provider_addr);
            feed.value = data_value;
            feed.timestamp = current_time;
            feed.provider_count = feed.provider_count + 1;
            feed.total_stake = feed.total_stake + oracle.stake_amount;
        } else {
            let new_feed = DataFeed {
                value: data_value,
                timestamp: current_time,
                provider_count: 1,
                total_stake: oracle.stake_amount,
            };
            move_to(provider, new_feed);
        };
    }
}