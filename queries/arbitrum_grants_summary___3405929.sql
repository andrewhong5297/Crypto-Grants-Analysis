-- part of a query repo
-- query name: Arbitrum Grants Summary
-- query link: https://dune.com/queries/3405929


with 
    grant_contracts as (
        SELECT
            c.address
            , c.namespace
            , c.name
            , g.*
            , row_number() over (partition by c.address order by created_at desc) as latest
        FROM dune.cryptodatabytes.dataset_evm_grants g
        LEFT JOIN evms.contracts c ON g.grant_blockchain = c.blockchain and contains(split(g.dune_namespaces,','),c.namespace)
    )
    
    , quality_users as (
        with base as (
            SELECT 
                gc.grantee
                , tx."from" as user
                , count(distinct tx.hash) as txs
            FROM grant_contracts gc
            LEFT JOIN arbitrum.traces tr ON tr.to = gc.address AND gc.grant_blockchain = 'arbitrum'
            LEFT JOIN arbitrum.transactions tx ON tx.hash = tr.tx_hash
            WHERE latest = 1
            AND tr.block_time >= now() - interval '30' day
            AND tx.block_time >= now() - interval '30' day
            GROUP BY 1,2
            HAVING count(distinct tx.hash) >= 10
        )
        
        SELECT 
            grantee
            , count(*) as q_users_30d
        FROM base
        group by 1
    )
    
SELECT 
    gc.grantee
    , p.symbol as grant_token
    , gc.grant_amount
    , gc.grant_amount*p.price as grant_amount_usd
    , array_agg(distinct grant_name || ' (#' || cast(grant_round as varchar) || ')') as grants
    -- , approx_distinct(case when tx.block_time >= now() - interval '7' day then tr.tx_hash else null end) as txs_7d
    , approx_distinct(tr.tx_hash) as txs_30d
    -- , approx_distinct(case when tx.block_time >= now() - interval '7' day then tx."from" else null end) as users_7d
    , approx_distinct(tx."from") as users_30d
    , qu.q_users_30d
    -- , sum(case when tx.block_time >= now() - interval '7' day then tr.gas_used*tx.gas_price/1e18 else null end) as gas_fees_eth_7d
    , sum(tr.gas_used*tx.gas_price/1e18) as gas_fees_eth_30d
FROM grant_contracts gc
LEFT JOIN arbitrum.traces tr ON tr.to = gc.address AND gc.grant_blockchain = 'arbitrum'
LEFT JOIN arbitrum.transactions tx ON tx.hash = tr.tx_hash
LEFT JOIN quality_users qu ON qu.grantee = gc.grantee
LEFT JOIN prices.usd p ON p.blockchain = 'arbitrum' 
    and p.contract_address = gc.grant_token_address
    and p.minute = DATE_PARSE(gc.grant_date, '%m/%d/%Y')
WHERE latest = 1
AND tr.block_time >= now() - interval '30' day
AND tx.block_time >= now() - interval '30' day
GROUP BY 1,2,3,4, qu.q_users_30d
order by gc.grant_amount desc