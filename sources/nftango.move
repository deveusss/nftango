module overmind::nftango {
    use std::signer;
    use std::error;
    use aptos_framework::account;
    use std::vector;
    use aptos_token::token::{Self,TokenId};
    use std::option::{Self, Option};
    use std::string::{String, utf8};
    //
    // Errors
    //
    const ERROR_NFTANGO_STORE_EXISTS: u64 = 0;
    const ERROR_NFTANGO_STORE_DOES_NOT_EXIST: u64 = 1;
    const ERROR_NFTANGO_STORE_IS_ACTIVE: u64 = 2;
    const ERROR_NFTANGO_STORE_IS_NOT_ACTIVE: u64 = 3;
    const ERROR_NFTANGO_STORE_HAS_AN_OPPONENT: u64 = 4;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT: u64 = 5;
    const ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET: u64 = 6;
    const ERROR_NFTS_ARE_NOT_IN_THE_SAME_COLLECTION: u64 = 7;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN: u64 = 8;
    const ERROR_NFTANGO_STORE_HAS_CLAIMED: u64 = 9;
    const ERROR_NFTANGO_STORE_IS_NOT_PLAYER: u64 = 10;
    const ERROR_VECTOR_LENGTHS_NOT_EQUAL: u64 = 11;

    //
    // Data structures
    //
    struct NFTangoStore has key {
        creator_token_id: TokenId,
        // The number of NFTs (one more more) from the same collection that the opponent needs to bet to enter the game
        join_amount_requirement: u64,
        opponent_address: Option<address>,
        opponent_token_ids: vector<TokenId>,
        active: bool,
        has_claimed: bool,
        did_creator_win: Option<bool>,
        signer_capability: account::SignerCapability
    }

    //
    // Assert functions
    //
    public fun assert_nftango_store_exists(
        account_address: address,
    ) {
        // assert that `NFTangoStore` exists
        assert!(
            exists<NFTangoStore>(account_address),
            error::invalid_state(ERROR_NFTANGO_STORE_EXISTS)
        );
    }

    public fun assert_nftango_store_does_not_exist(
        account_address: address,
    ) {
        // assert that `NFTangoStore` does not exist
        assert!(
            !exists<NFTangoStore>(account_address),
            error::invalid_state(ERROR_NFTANGO_STORE_EXISTS)
        );
    }

    public fun assert_nftango_store_is_active(
        account_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.active` is active
       let nftango_store = borrow_global_mut<NFTangoStore>(account_address);

        assert!(
            nftango_store.active,
            error::invalid_argument(ERROR_NFTANGO_STORE_IS_NOT_ACTIVE)
        );
    }

    public fun assert_nftango_store_is_not_active(
        account_address: address,
    ) acquires NFTangoStore {
        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);

         assert!(
            !nftango_store.active,
            error::invalid_argument(ERROR_NFTANGO_STORE_IS_NOT_ACTIVE)
        );
    }

    public fun assert_nftango_store_has_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);
        assert!(
            option::is_some(&nftango_store.opponent_address),
            error::invalid_state(ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT)
        );
    }

    public fun assert_nftango_store_does_not_have_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.opponent_address` is not set
        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);
        assert!(
            !option::is_some(&nftango_store.opponent_address),
            error::invalid_argument(ERROR_NFTANGO_STORE_HAS_AN_OPPONENT)
        );
    }

    public fun assert_nftango_store_join_amount_requirement_is_met(
        game_address: address,
        token_ids: vector<TokenId>,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.join_amount_requirement` is met
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        let join_amount_requirement=nftango_store.join_amount_requirement;
        let i = 0;
        let collection_name=b"";
        while (i < vector::length(&token_ids)) {
            let token_id = *vector::borrow(&token_ids, i);
            let (_, nft_collection_name, _, _) = token::get_token_id_fields(
                &token_id
            );

             assert!(
                (collection_name==b"" || nft_collection_name==utf8(collection_name)),
                error::invalid_argument(ERROR_NFTS_ARE_NOT_IN_THE_SAME_COLLECTION)
            );
           
            i = i + 1;

        };
        assert!(
                vector::length(&token_ids) >= join_amount_requirement,
                error::invalid_argument(ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET)
            );
    }

    public fun assert_nftango_store_has_did_creator_win(
        game_address: address,
    ) acquires NFTangoStore {
        //  assert that `NFTangoStore.did_creator_win` is set
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        assert!(
                option::is_some(&nftango_store.did_creator_win),
                error::invalid_argument(ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN)
            );
    }

    public fun assert_nftango_store_has_not_claimed(
        game_address: address,
    ) acquires NFTangoStore {
        //  assert that `NFTangoStore.has_claimed` is false
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        assert!(
            !nftango_store.has_claimed,
                error::invalid_argument(ERROR_NFTANGO_STORE_HAS_CLAIMED)
            );
    }

    public fun assert_nftango_store_is_player(account_address: address, game_address: address) acquires NFTangoStore {
        //  assert that `account_address` is either the equal to `game_address` or `NFTangoStore.opponent_address`
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        assert!(
            account_address==game_address ||account_address==*option::borrow(&nftango_store.opponent_address),
                error::invalid_argument(ERROR_NFTANGO_STORE_IS_NOT_PLAYER)
            );
    }

    public fun assert_vector_lengths_are_equal(creator: vector<address>,
                                               collection_name: vector<String>,
                                               token_name: vector<String>,
                                               property_version: vector<u64>) {
        //  assert all vector lengths are equal
        assert!(
            vector::length(&creator) == vector::length(&collection_name),
            error::invalid_state(ERROR_VECTOR_LENGTHS_NOT_EQUAL)
        );
        assert!(
            vector::length(&token_name)==vector::length(&property_version),
            error::invalid_state(ERROR_VECTOR_LENGTHS_NOT_EQUAL)
        );
        assert!(
            vector::length(&token_name)==vector::length(&creator),
            error::invalid_state(ERROR_VECTOR_LENGTHS_NOT_EQUAL)
        );
    }

    //
    // Entry functions
    //
    public entry fun initialize_game(
        account: &signer,
        creator: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        join_amount_requirement: u64
    ) {
        let account_address = signer::address_of(account);

        //  run assert_nftango_store_does_not_exist
        assert_nftango_store_does_not_exist(account_address);
        //  create resource account
        let (escrow_signer, escrow_signer_cap) = account::create_resource_account(account, vector::empty());

        //  token::create_token_id_raw
        let token_id = token::create_token_id_raw(creator, collection_name, token_name, property_version);

        //  opt in to direct transfer for resource account
        token::opt_in_direct_transfer(&escrow_signer, true);

        //  transfer NFT to resource account
        token::transfer(account, token_id, signer::address_of(&escrow_signer), 1);
               
        //  move_to resource `NFTangoStore` to account signer
        move_to(account, NFTangoStore {
            creator_token_id:token_id,
            join_amount_requirement,
            opponent_address:option::none<address>(),
            opponent_token_ids:vector::empty(),
            active:true,
            has_claimed:false,
            did_creator_win:option::none<bool>(),
            signer_capability:escrow_signer_cap
        });
    }

    public entry fun cancel_game(
        account: &signer,
    ) acquires NFTangoStore {
        let account_address = signer::address_of(account);
        //  run assert_nftango_store_exists
        assert_nftango_store_exists(account_address);

        //  run assert_nftango_store_is_active
        assert_nftango_store_is_active(account_address);
        //  run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(account_address);
        //  opt in to direct transfer for account
        token::opt_in_direct_transfer(account, true);

        //  transfer NFT to account address
        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);
        token::transfer(&account::create_signer_with_capability(&nftango_store.signer_capability), nftango_store.creator_token_id, account_address, 1);

        //  set `NFTangoStore.active` to false
        nftango_store.active=false;
    }

    public fun join_game(
        account: &signer,
        game_address: address,
        creators: vector<address>,
        collection_names: vector<String>,
        token_names: vector<String>,
        property_versions: vector<u64>,
    ) acquires NFTangoStore {
        let account_address = signer::address_of(account);
        //  run assert_vector_lengths_are_equal
        assert_vector_lengths_are_equal(creators,collection_names,token_names,property_versions);
        let token_ids = vector::empty<TokenId>();
        let i=0;
        //  loop through and create token_ids vector<TokenId>
        while (i < vector::length(&creators)) {
            let creator = *vector::borrow(&creators, i);
            let collection_name = *vector::borrow(&collection_names, i);
            let token_name = *vector::borrow(&token_names, i);
            let property_version = *vector::borrow(&property_versions, i);
            let token_id = token::create_token_id_raw(creator, collection_name, token_name, property_version);
            vector::push_back(&mut token_ids, token_id);
            
            i = i + 1;
        };
        //  run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);
        //  run assert_nftango_store_is_active
        assert_nftango_store_is_active(game_address);
        //  run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(game_address);

        //  run assert_nftango_store_join_amount_requirement_is_met
        assert_nftango_store_join_amount_requirement_is_met(game_address,token_ids);
        //  loop through token_ids and transfer each NFT to the resource account
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        i=0;
        while (i < vector::length(&token_ids)) {
            let token_id = *vector::borrow(&token_ids, i);
            token::transfer(account, token_id, account::get_signer_capability_address(&nftango_store.signer_capability), 1);
            i = i + 1;
        };
        //  set `NFTangoStore.opponent_address` to account_address
        nftango_store.opponent_address=option::some(account_address);
        //  set `NFTangoStore.opponent_token_ids` to token_ids
        nftango_store.opponent_token_ids=token_ids;
    }

    public entry fun play_game(account: &signer, did_creator_win: bool) acquires NFTangoStore {
        let account_address = signer::address_of(account);
        //  run assert_nftango_store_exists
        assert_nftango_store_exists(account_address);
        //  run assert_nftango_store_is_active
        assert_nftango_store_is_active(account_address);
        //  run assert_nftango_store_has_an_opponent
        assert_nftango_store_has_an_opponent(account_address);
        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);

        //  set `NFTangoStore.did_creator_win` to did_creator_win
        nftango_store.did_creator_win=option::some(did_creator_win);
        //  set `NFTangoStore.active` to false\
        nftango_store.active=false;
    }

    public entry fun claim(account: &signer, game_address: address) acquires NFTangoStore {
        let account_address = signer::address_of(account);
        //  run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);
        //  run assert_nftango_store_is_not_active
        assert_nftango_store_is_not_active(game_address);
        //  run assert_nftango_store_has_not_claimed
        assert_nftango_store_has_not_claimed(game_address);

        //  run assert_nftango_store_is_player
        assert_nftango_store_is_player(account_address,game_address);

        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        let winner=game_address;
        //  if the player won, send them all the NFTs
        if (!*option::borrow(&nftango_store.did_creator_win)){
           winner=*option::borrow(&nftango_store.opponent_address);
        };
        
        let i=0;
        while (i < vector::length(&nftango_store.opponent_token_ids)) {
            let token_id = *vector::borrow(&nftango_store.opponent_token_ids, i);
            token::transfer(&account::create_signer_with_capability(&nftango_store.signer_capability), token_id, winner, 1);
            i = i + 1;
        };
        token::transfer(&account::create_signer_with_capability(&nftango_store.signer_capability), nftango_store.creator_token_id, winner, 1);            

        //  set `NFTangoStore.has_claimed` to true
        nftango_store.has_claimed=true;
    }
}