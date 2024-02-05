-- part of a query repo
-- query name: All Grants
-- query link: https://dune.com/queries/3405947


SELECT
grant_source
, grant_blockchain
, grant_date
, grant_name
, grant_round
, p.symbol as grant_token
, sum(grant_amount) as grant_amount
, sum(grant_amount*p.price) as grant_amount_usd
, count(distinct grantee) as grantees
, approx_percentile(grant_amount*p.price, 0.5) as median_grant_amount_usd
FROM dune.cryptodatabytes.dataset_evm_grants gc
LEFT JOIN prices.usd p ON p.blockchain = 'arbitrum' 
    and p.contract_address = gc.grant_token_address
    and p.minute = DATE_PARSE(gc.grant_date, '%m/%d/%Y')
GROUP BY 1, 2, 3, 4, 5, 6