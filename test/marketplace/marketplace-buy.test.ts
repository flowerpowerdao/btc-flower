import { AccountIdentifier } from '@dfinity/nns';
import { describe, test, expect, it } from 'vitest';
import { ICP_FEE } from '../consts';
import { User } from '../user';
import { applyFees, buyFromSale, checkTokenCount, tokenIdentifier } from '../utils';
import { whitelistTier0, whitelistTier1 } from '../well-known-users';
import env from './.env.marketplace';

describe('buy on marketplace', async () => {
  let price = 1_000_000n;
  let initialBalance = 1_000_000_000n;

  let seller = new User;
  await seller.mintICP(initialBalance);

  let buyer = new User;
  await buyer.mintICP(initialBalance);

  it('buy from sale', async () => {
    await buyFromSale(seller)
  });

  it('check seller ICP balance', async () => {
    let expectedBalance = initialBalance - env.salePrice - ICP_FEE;
    expect(await seller.icpActor.account_balance({ account: seller.account })).toEqual({ e8s: expectedBalance });
  });

  it('check token count', async () => {
    await checkTokenCount(seller, 1)
  });

  let tokens;
  it('get tokens', async () => {
    let res = await seller.mainActor.tokens(seller.accountId);
    expect(res).toHaveProperty('ok');
    if ('err' in res) {
      throw res.err;
    }
    tokens = res.ok;
    expect(tokens).toHaveLength(1);
  });

  it('list', async () => {
    let res = await seller.mainActor.list({
      from_subaccount: [],
      price: [price],
      token: tokenIdentifier(tokens[0]),
    });
    expect(res).toHaveProperty('ok');
  });

  let paytoAddress: string;
  it('lock', async () => {
    let lockRes = await buyer.mainActor.lock(tokenIdentifier(tokens[0]), price, buyer.accountId, new Uint8Array);
    expect(lockRes).toHaveProperty('ok');
    if ('ok' in lockRes) {
      paytoAddress = lockRes.ok;
    }
  });

  it('transfer ICP', async () => {
    await buyer.sendICP(paytoAddress, price);
  });

  it('settle by another user', async () => {
    let user = new User;
    let res = await user.mainActor.settle(tokenIdentifier(tokens[0]));
    expect(res).toHaveProperty('ok');
  });

  it('check seller token count', async () => {
    await checkTokenCount(seller, 0);
  });

  it('check buyer token count', async () => {
    await checkTokenCount(buyer, 1);
  });

  it('check buyer ICP balance', async () => {
    let expectedBalance = initialBalance - price - ICP_FEE;
    expect(await buyer.icpActor.account_balance({ account: buyer.account })).toEqual({ e8s: expectedBalance });
  });

  it('cron settlements', async () => {
    await seller.mainActor.cronSettlements();
    await seller.mainActor.cronDisbursements();
  });

  it('check seller ICP balance', async () => {
    let balanceAfterBuyOnSale = initialBalance - env.salePrice - ICP_FEE;
    let transferFees = ICP_FEE * 4n; // 1 seller transfer, 1 marketplace transfer, 2 royalty transfers
    let expectedBalance = balanceAfterBuyOnSale + applyFees(price - transferFees, [env.royalty0, env.royalty1, env.defaultMarketplaceFee]);
    expect(await seller.icpActor.account_balance({ account: seller.account })).toEqual({ e8s: expectedBalance });
  });
});