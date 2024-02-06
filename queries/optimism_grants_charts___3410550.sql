-- part of a query repo
-- query name: Optimism Grants Charts
-- query link: https://dune.com/queries/3410550


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
    
    , ordered_traces as (
        SELECT 
            gc.grantee
            , gc.grant_blockchain
            , tr.tx_hash
            , tr.gas_used
            , tr.trace_address
            , tr.block_time
            , tx."from" as tx_from
            , tx.gas_price
            --we only want to keep the highest order trace call by a grantee contract. We do want to keep potential multi-calls so we use rank instead of row_number().
            , rank() over (partition by gc.grantee, tr.tx_hash order by cardinality(trace_address) asc) as trace_order
        FROM optimism.traces tr 
        JOIN grant_contracts gc ON tr.to = gc.address
        JOIN optimism.transactions tx ON tx.hash = tr.tx_hash
        WHERE tr.block_time >= timestamp '2023-12-01 00:00:00'
        AND tx.block_time >= timestamp '2023-12-01 00:00:00'
        AND gc.latest = 1
    )
    
SELECT 
    date_trunc('week',block_time) as week
    , grantee
    , approx_distinct(tx_hash) as txs
    , approx_distinct(tx_from) as users
    , sum(gas_used*gas_price/1e18) as gas_fees_eth
FROM ordered_traces
WHERE trace_order = 1
GROUP BY 1,2
ORDER BY week DESC, txs DESC