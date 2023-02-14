import Time "mo:base/Time";

import Cap "mo:cap/Cap";

import ExtCore "../toniq-labs/ext/Core";
import TokenTypes "../Tokens/types";
import Tokens "../Tokens";
import Sale "../Sale";
import Disburser "../Disburser";
import LedgerTypes "../Ledger/types";

module {

  public func newStableState() : StableState {
    return {
      _transactionsState : [Transaction] = [];
      _tokenSettlementState : [(TokenTypes.TokenIndex, Settlement)] = [];
      _tokenListingState : [(TokenTypes.TokenIndex, Listing)] = [];
      _frontendsState : [(Text, Frontend)] = [];
    };
  };

  public type Frontend = {
    fee : Nat64;
    accountIdentifier : AccountIdentifier;
  };

  public type AccountIdentifier = ExtCore.AccountIdentifier;

  public type Time = Time.Time;

  public type TokenIdentifier = TokenTypes.TokenIdentifier;

  public type Metadata = TokenTypes.Metadata;

  public type SubAccount = ExtCore.SubAccount;

  public type CommonError = ExtCore.CommonError;

  public type TokenIndex = ExtCore.TokenIndex;

  public type Transaction = {
    token : TokenIdentifier;
    seller : Principal;
    price : Nat64;
    buyer : AccountIdentifier;
    time : Time;
  };

  public type Settlement = {
    seller : Principal;
    price : Nat64;
    subaccount : SubAccount;
    buyer : AccountIdentifier;
    sellerFrontend : ?Text;
    buyerFrontend : ?Text;
  };

  public type Listing = {
    seller : Principal;
    price : Nat64;
    locked : ?Time;
    sellerFrontend : ?Text;
    buyerFrontend : ?Text;
  };

  public type ListRequest = {
    token : TokenIdentifier;
    from_subaccount : ?SubAccount;
    price : ?Nat64;
    frontendIdentifier : ?Text;
  };

  public type StableState = {
    _transactionsState : [Transaction];
    _tokenSettlementState : [(TokenIndex, Settlement)];
    _tokenListingState : [(TokenIndex, Listing)];
    _frontendsState : [(Text, Frontend)];
  };

  public type Dependencies = {
    _Cap : Cap.Cap;
    _Tokens : Tokens.Factory;
    _Sale : Sale.Factory;
    _Disburser : Disburser.Factory;
  };

  public type Constants = {
    LEDGER_CANISTER : LedgerTypes.LEDGER_CANISTER;
    minter : Principal;
  };

};
