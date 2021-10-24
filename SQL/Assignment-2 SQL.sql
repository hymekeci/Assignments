--a.    Create above table (Actions) and insert values,
CREATE TABLE Actions
(
Visitor_ID int,
Adv_Type VARCHAR(10),
Action_m VARCHAR(10),
);

INSERT INTO Actions (Visitor_ID, Adv_Type,Action_m)
 VALUES
(1,'A','Left'),
(2,'A','Order'),
(3,'B','Left'),
(4,'A','Order'),
(5,'A','Review'),
(6,'A','Left'),
(7,'B','Left'),
(8,'B','Order'),
(9,'B','Review'),
(10,'A','Review');

--select * from Actions


--b.    Retrieve count of total Actions and Orders for each Advertisement Type,
select Adv_Type, COUNT(Action_m) As Num_Action, (select COUNT(Action_m) FROM Actions WHERE Action_m = 'Order'  and  Adv_Type = 'A')  As Num_order
from Actions
where  Adv_Type = 'A'
group by Adv_Type
UNION
select Adv_Type, COUNT(Action_m) As Num_Action, (select COUNT(Action_m) FROM Actions WHERE Action_m = 'Order' and  Adv_Type = 'B' )  As Num_order
from Actions
where  Adv_Type = 'B'
group by Adv_Type

/* 
c.    Calculate Orders (Conversion) rates 
for each Advertisement Type by dividing 
by total count of actions casting as float by multiplying by 1.0.
*/
select Adv_Type, 100/(Num_Action/Num_Order)*0.01 as Conversion_Rate
from (select Adv_Type, COUNT(Action_m) As Num_Action, (select COUNT(Action_m) FROM Actions WHERE Action_m = 'Order'  and  Adv_Type = 'A')  As Num_order
    from Actions
    where  Adv_Type = 'A'
    group by Adv_Type
    UNION
    select Adv_Type, COUNT(Action_m) As Num_Action, (select COUNT(Action_m) FROM Actions WHERE Action_m = 'Order' and  Adv_Type = 'B' )  As Num_order
    from Actions
    where  Adv_Type = 'B'
    group by Adv_Type) new_table

/*
select Adv_Type, round(cast(Num_order as float)/ CAST() ) as Conversion_Rate
from (select Adv_Type, COUNT(Action_m) As Num_Action, (select COUNT(Action_m) FROM Actions WHERE Action_m = 'Order'  and  Adv_Type = 'A')  As Num_order
    from Actions
    where  Adv_Type = 'A'
    group by Adv_Type
    UNION
    select Adv_Type, COUNT(Action_m) As Num_Action, (select COUNT(Action_m) FROM Actions WHERE Action_m = 'Order' and  Adv_Type = 'B' )  As Num_order
    from Actions
    where  Adv_Type = 'B'
    group by Adv_Type) new_table
*/

