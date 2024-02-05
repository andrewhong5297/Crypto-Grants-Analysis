-- part of a query repo
-- query name: Arbitrum Grants Charts
-- query link: https://dune.com/queries/3405541


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
    
    , summary as (
        SELECT 
            date_trunc('week',tr.block_time) as week
            , gc.grantee
            , gc.grant_amount
            , approx_distinct(tr.tx_hash) as txs
            , approx_distinct(tx."from") as users
            , sum(tr.gas_used*tx.gas_price/1e18) as gas_fees_eth
        FROM grant_contracts gc
        LEFT JOIN arbitrum.traces tr ON tr.to = gc.address AND gc.grant_blockchain = 'arbitrum'
        LEFT JOIN arbitrum.transactions tx ON tx.hash = tr.tx_hash
        WHERE latest = 1
        AND tr.block_time >= timestamp '2024-01-01 00:00:00'
        AND tx.block_time >= timestamp '2024-01-01 00:00:00'
        GROUP BY 1,2,3
    )
    
SELECT 
*
, grant_amount/users as user_grant_ratio
FROM summary
ORDER BY week DESC, txs DESC