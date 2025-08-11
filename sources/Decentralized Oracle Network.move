module hrithvika_addr::OracleNetwork {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    
    struct OracleProvider has store, key {
        stake_amount: u64,      
        data_feeds: u64,        
        reputation_score: u64,  
        is_active: bool,        
    }

    
    struct DataFeed has store, key {
        value: u64,             
        timestamp: u64,         
        provider_count: u64,   
        total_stake: u64,       
    }

    
    public fun register_oracle_provider(provider: &signer, stake_amount: u64) {
        let provider_addr = signer::address_of(provider);
        
        
        assert!(!exists<OracleProvider>(provider_addr), 1);
        
        
        assert!(stake_amount >= 1000, 2);
        
        
        let stake = coin::withdraw<AptosCoin>(provider, stake_amount);
        coin::deposit<AptosCoin>(provider_addr, stake);
        
        
        let oracle = OracleProvider {
            stake_amount,
            data_feeds: 0,
            reputation_score: 100, // Starting reputation
            is_active: true,
        };
        
        move_to(provider, oracle);
    }

    
    public fun submit_data_feed(provider: &signer, data_value: u64) acquires OracleProvider, DataFeed {
        let provider_addr = signer::address_of(provider);
        
        
        assert!(exists<OracleProvider>(provider_addr), 3);
        let oracle = borrow_global_mut<OracleProvider>(provider_addr);
        assert!(oracle.is_active, 4);
        
        
        oracle.data_feeds = oracle.data_feeds + 1;
        
        
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
