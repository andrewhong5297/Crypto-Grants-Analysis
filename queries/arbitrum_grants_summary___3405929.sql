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
        WHERE g.grant_blockchain = 'arbitrum'
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
            , tx.effective_gas_price
            --we only want to keep the highest order trace call by a grantee contract. We do want to keep potential multi-calls so we use rank instead of row_number().
            , rank() over (partition by gc.grantee, tr.tx_hash order by cardinality(trace_address) asc) as trace_order
        FROM arbitrum.traces tr 
        JOIN grant_contracts gc ON tr.to = gc.address
        JOIN arbitrum.transactions tx ON tx.hash = tr.tx_hash
        WHERE tr.block_time >= now() - interval '30' day
        AND tx.block_time >= now() - interval '30' day
        AND gc.latest = 1
    )
    
    , blockchain_summary as (
        SELECT 
            blockchain as blockchain
            , approx_distinct(tx.hash) as txs_30d
            , approx_distinct(tx."from") as users_30d
            , sum(tx.effective_gas_price*tx.gas_used/1e18) as gas_fees_eth_30d
        FROM evms.transactions tx
        WHERE tx.block_time >= now() - interval '30' day
        AND blockchain IN ('arbitrum') --add all arbitrum chains later
        GROUP BY 1
    )
    
    , quality_users as (
        with base as (
            SELECT 
                gc.grantee
                , tx."from" as user
                , count(distinct tx.hash) as txs
            FROM grant_contracts gc
            JOIN arbitrum.traces tr ON tr.to = gc.address AND gc.grant_blockchain = 'arbitrum'
            JOIN arbitrum.transactions tx ON tx.hash = tr.tx_hash AND tx.block_time = tr.block_time
            WHERE latest = 1
            AND tr.block_time >= now() - interval '30' day
            AND tx.block_time >= now() - interval '30' day
            GROUP BY 1,2
            HAVING count(distinct tx.hash) >= 5
        )
        
        SELECT 
            grantee
            , count(*) as q_users_30d
        FROM base
        group by 1
    )
    
SELECT 
    case when gc.dashboard_link is null then substring(gc.grantee,1,20) 
        else get_href(gc.dashboard_link, '📊 ' || substring(gc.grantee,1,20)) 
        end as grantee
    , gc.grant_amount*p.price as grant_amount_usd
    , COALESCE(approx_distinct(tr.tx_hash),0) as txs_30d
    , COALESCE(approx_distinct(tr.tx_from),0) as users_30d
    , COALESCE(qu.q_users_30d,0) as q_users_30d
    , COALESCE(sum(tr.gas_used*tr.effective_gas_price/1e18),0) as gas_fees_eth_30d
    , COALESCE(sum(cast(tr.gas_used*tr.effective_gas_price/1e18 as double)/cast(blk.gas_fees_eth_30d as double)),0) as percent_total_fees_30d
    , array_agg(distinct grant_name || ' (#' || cast(grant_round as varchar) || ')') as grants
FROM dune.cryptodatabytes.dataset_evm_grants gc
LEFT JOIN ordered_traces tr ON tr.grantee = gc.grantee AND tr.trace_order = 1
LEFT JOIN quality_users qu ON qu.grantee = gc.grantee
LEFT JOIN prices.usd p ON p.blockchain = 'arbitrum'
    and p.contract_address = gc.grant_token_address
    and p.minute = DATE_PARSE(gc.grant_date, '%m/%d/%Y')
LEFT JOIN blockchain_summary blk ON blk.blockchain = gc.grant_blockchain --potential issues if protocol is deployed on multiple chains. How to handle?
WHERE gc.grant_blockchain = 'arbitrum'
GROUP BY 1,2,qu.q_users_30d
order by grant_amount_usd desc