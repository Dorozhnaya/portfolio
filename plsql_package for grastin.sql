-- Выдержки из пакета, хранящегося в базе данных (названия изменены)
PACKAGE delivery
IS

-- отправка заказов
spec:

TYPE T_CURSOR IS REF CURSOR;
procedure Get_Grastin_orders (orders out t_cursor);

body:

procedure Get_Grastin_orders (orders out t_cursor)
is

begin

open orders for select * from
(
 select to_char(to_date(nvl(inf.TIME_FROM,10),'hh24:mi'),'hh24:mi') shippingtimefrom
     , to_char(to_date(nvl(inf.TIME_TO,18),'hh24:mi'),'hh24:mi') shippingtimefor
     , to_char(nvl(inf.DELIVERY_DATE,trunc(sysdate)+1),'ddmmyyyy') shippingdate
     , inf.RECIPIENT_NAME buyer
     , inf.TOTAL_VALUE summa
     , inf.ESTIMATED_VALUE assessedsumma
     , inf.RECIPIENT_PHONE phone1
     , inf.RECIPIENT_PHONE2 phone2
     , gr.GRASTIN_SERVICE_TYPE service
     , o.amount seats
     , 'Москва' takewarehouse
     , 'Товары' cargotype
     , site.val_str sitename
     , inf.recipient_email email
     , inf.id  ff_id
from
ldv_ff_order_info inf
join st_doc_out o on (inf.FF_ORDER_ID = o.n and o.status=8 and nvl(o.amount,0)!=0 and sysdate between o.fd and o.td)
join ldv_ff_params_grastin gr on (inf.id=gr.ff_order_info_id and sysdate between gr.fd and gr.td)
left join client_prop_values site on (inf.contragent_n=site.client_n and site.client_prop_items_n=1419 and sysdate between site.fd and site.td)
where sysdate between inf.fd and inf.td
and nvl(inf.is_normalized,0) = 1
and inf.courier_service = 1
and nvl(inf.is_placed_in_cs,0) = 0
);

end Get_Grastin_orders;


-- фиксация принятия заказа

spec:

procedure Delivery_order_created (POrderN varchar2, PTracking varchar2);

body:

procedure Delivery_order_created (POrderN varchar2, PTracking varchar2)
is
v_ff_id integer;

begin

select id into v_ff_id
from ldv_ff_order_info
where ff_order_id=to_number(POrderN)
and sysdate between fd and td;

update ldv_ff_order_info set is_placed_in_cs=1 where id=v_ff_id;

update ldv_ff_delivery_info set td=sysdate where ff_order_info_id=to_number(POrderN) and up=0 and sysdate between fd and td;

insert into ldv_ff_delivery_info
   (N, FF_ORDER_INFO_ID, UP, NORMALIZED_STATUS, DELIVERY_TRACKING, IS_FINALIZED, FD, TD)
values
   (sq_ldv_ff_order_info.NEXTVAL, v_ff_id, 0, null, PTracking, 0, sysdate, kk_common.GetTD);

exception when no_data_found then
 null;

end Delivery_order_created;


-- трекинг заказов
spec:

type order_tracking_rec is record (auth varchar2(100), n integer, orderNumber integer, trackingNumber varchar2(50));
type order_tracking_table is table of order_tracking_rec;
function Get_orders_to_track (PCourierService integer) return order_tracking_table pipelined;

body:

function Get_orders_to_track (PCourierService integer) return order_tracking_table pipelined
is
rec order_tracking_rec;

begin

for j in
(
select kk_const.GetConstV('LDV.IntegrationServices.Grastin.ApiKey',sysdate,inf.contragent_n) auth
     , di.n
     , inf.ff_order_id orderNumber
     , case when di.return_created is null then di.delivery_tracking else di.return_tracking end trackingNumber
from ldv_ff_delivery_info di
join ldv_ff_order_info inf on (di.ff_order_info_id=inf.id and inf.courier_service=PCourierService and sysdate between inf.fd and inf.td)
where di.is_finalized=0
and sysdate between di.fd and di.td
)
loop
rec:=j;
pipe row(rec);
end loop;

return;

end Get_orders_to_track;

-- конец пакета
END delivery;