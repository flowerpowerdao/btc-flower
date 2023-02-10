import Float "mo:base/Float";
import Int "mo:base/Int";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import List "mo:base/List";
import Principal "mo:base/Principal";

import Encoding "mo:encoding/Binary";
import AviateAccountIdentifier "mo:accountid/AccountIdentifier";

import ExtCore "../toniq-labs/ext/Core";
import Types "types";
import Utils "../utils";

module {
  public class Factory(this : Principal, state : Types.StableState, consts : Types.Constants) {

    /*********
    * STATE *
    *********/

    private var _disbursements : List.List<Types.Disbursement> = List.fromArray(state._disbursementsState);

    public func toStable() : Types.StableState {
      return {
        _disbursementsState = List.toArray(_disbursements);
      };
    };

    //*** ** ** ** ** ** ** ** ** * * PUBLIC INTERFACE * ** ** ** ** ** ** ** ** ** ** /

    public func addDisbursement(disbursement : Types.Disbursement) : () {
      _disbursements := List.push(disbursement, _disbursements);
    };

    public func getDisbursements() : [Types.Disbursement] {
      List.toArray(_disbursements);
    };

    public func cronDisbursements() : async () {
      label payloop while (true) {
        let (last, newDisbursements) = List.pop(_disbursements);
        switch (last) {
          case (?disbursement) {
            _disbursements := newDisbursements;

            try {
              var res = await consts.LEDGER_CANISTER.transfer({
                to = switch (AviateAccountIdentifier.fromText(disbursement.to)) {
                  case (#ok(accountId)) {
                    AviateAccountIdentifier.addHash(accountId);
                  };
                  case (#err(_)) {
                    // this should never happen because account ids are always created from within the
                    // canister which should guarantee that they are valid and we are able to decode them
                    // to [Nat8]
                    continue payloop;
                  };
                };
                from_subaccount = ?disbursement.fromSubaccount;
                amount = { e8s = disbursement.amount };
                fee = { e8s = 10000 };
                created_at_time = null;
                memo = Encoding.BigEndian.toNat64(Blob.toArray(Principal.toBlob(Principal.fromText(ExtCore.TokenIdentifier.fromPrincipal(this, disbursement.tokenIndex)))));
              });

              switch (res) {
                case (#Ok(blockIndex)) {};
                case (#Err(#InsufficientFunds({ balance }))) {
                  // don't add disbursement back to _disbursements because it will lead to an infinite loop
                };
                case (#Err(_)) {
                  _disbursements := List.push(disbursement, _disbursements);
                };
              };
            } catch (e) {
              _disbursements := List.push(disbursement, _disbursements);
            };
          };
          case (null) {
            break payloop;
          };
        };
      };
    };

    public func pendingCronJobs() : Nat {
      List.size(_disbursements);
    };
  };
};
