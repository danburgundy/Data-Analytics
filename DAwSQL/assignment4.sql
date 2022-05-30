with tbl as(
select product_id,
sum(quantity) over (PARTITION by product_id order by product_id) quan,
sum(list_price*quantity) over (PARTITION by product_id order by product_id) lis,
sum((1-discount)*list_price*quantity) over (PARTITION by product_id order by product_id) dis,
quantity q1,
discount d1,
lead(quantity) over(order by product_id) q2,
lead(discount) over(order by product_id) d2
from sale.order_item
),
tbl1 as(
select product_id,q1,q2,d1,d2,
Case 
    when d2>d1 and q2>q1 Then 1
    when d2>d1 and q2<q1 then -1
    when d2>d1 and q2 = q1 then 0
    when d2<d1 and q2<q1 then 1
    when d2<d1 and q2>q1 then -1
    when d2<d1 and q2=q1 then 0
    else 0
end as effect
from tbl
)
select 
product_id,
sum(effect) as effect1,
case 
    when sum(effect)>0 then 'Positive'
    when sum(effect)<0 then 'Negative'
    else 'Neutral'
end as Discount_Effect
from tbl1
group by product_id
order by product_id


select * from tbl