select to_char(d.ddate, 'dd.mm.yyyy hh24:mi:ss') "Дата"
     , d.typ "Тип операции"
     , n.code "Код товара"
     , n.artk "Артикул"
     , n.name "Наименование товара"
     , d.doc "№Документа"
     , cc.name  "Поставщик/Получатель"
     , ttn.val_str  "№ТТН поставки"
     , ttn_date.val_str  "Дата ТТН поставки"
     , sf.val_str  "№ СФ поставки"
     , sf_date.val_str  "Дата СФ поставки"     
     , d.fact_cnt "Кол-во по факту"
     , d.doc_price "Цена с НДС"
     , d.fact_cnt*d.doc_price  "Сумма поставки/отгрузки с НДС"
     , round((d.fact_cnt*d.doc_price*nvl(u.nds,18))/(100+nvl(u.nds,18)),2)  "Сумма НДС поставки/отгрузки"
     , d.doc_cnt "Кол-во по документу" 
     , d.fact_price "Цена от поставщика с НДС"    
     , d.doc_cnt*d.fact_price  "Сумма от поставщика с НДС"
     , round((d.doc_cnt*d.fact_price*nvl(u.nds,18))/(100+nvl(u.nds,18)),2)  "Сумма НДС от поставщика"
from
(
select 'Приход' typ, i.n, i.contragent_n, i.ccontragent_n, i.idoc_num doc, i.put_on_store_fd ddate, det_in.nomenklatura_n, 
        nvl(det_in.doc_cnt,0) doc_cnt, det_in.doc_price, nvl(det_in.fact_cnt,0) fact_cnt, det_in.fact_price, det_in.nds
from st_doc_in i
join
(
select nvl(dfact.sq_st_doc_in_n,ddoc.sq_st_doc_in_n) sq_st_doc_in_n
     , nvl(dfact.nomenklatura_n,ddoc.nomenklatura_n) nomenklatura_n
     , ddoc.cnt doc_cnt
     , ddoc.price doc_price
     , dfact.cnt fact_cnt
     , ddoc.s_price fact_price
     , ddoc.nds
from
(
  select d.sq_st_doc_in_n
       , d.nomenklatura_n
       , sum(d.cnt_in+d.cnt_brak) cnt
       , max(nvl(d.price,0)) price
       , max(case when s_price.fd>to_date('12072017 130000','ddmmyyyy hh24miss') then round(nvl(kk_output.STRING2NUMBER(s_price.val_str),0)*((100+nvl(dd.r_n,0))/100),2) else nvl(kk_output.STRING2NUMBER(s_price.val_str),0) end) s_price
       , max(nvl(dd.r_n,0)) nds
  from st_doc_in_det d
  left join client_prop_values s_price  on (d.n=s_price.client_n and s_price.client_prop_items_n=1209 and sysdate between s_price.fd and s_price.td)
  left join client_prop_values nds on (d.n=nds.client_n and nds.client_prop_items_n=1211 and sysdate between nds.fd and nds.td)
  left join dic_data dd on (nds.val_str=to_char(dd.code) and dd.up=552 and sysdate between dd.fd and dd.td)
  where d.typ=0
  and sysdate between d.fd and d.td
  group by d.sq_st_doc_in_n, d.nomenklatura_n
) ddoc
full outer join
(
  select sq_st_doc_in_n, nomenklatura_n, sum(cnt_in+cnt_brak) cnt --, max(nvl(price,0)) price
  from st_doc_in_det 
  where typ=1
  and sysdate between fd and td
  group by sq_st_doc_in_n, nomenklatura_n
) dfact 
        on (ddoc.sq_st_doc_in_n=dfact.sq_st_doc_in_n and ddoc.nomenklatura_n=dfact.nomenklatura_n)
) det_in
on (i.n=det_in.sq_st_doc_in_n)  
where i.put_on_store_fd between (trunc(:PFD) + 9/24) and (trunc(:PTD) + 9/24 - 1/86400)
and 
i.contragent_n in (1811,1820)
and sysdate between i.fd and i.td
and status=4  

union all

select 'Отгрузка' typ, o.n, o.contragent_n, o.ccontragent_n, o.doc, o.user_upload_end ddate, d.nomenklatura_n, null doc_cnt, pr.price doc_price, d.cnt fact_cnt, null fact_price, null nds
from st_doc_out o
join st_doc_out_det d on (o.n=d.sq_st_doc_out_n and sysdate between d.fd and d.td)
left join (select max(nvl(price,0)) price, nomenklatura_n from st_doc_in_det where typ=0 and sysdate between fd and td group by nomenklatura_n) pr on (d.nomenklatura_n=pr.nomenklatura_n)
where o.user_upload_end between (trunc(:PFD) + 9/24) and (trunc(:PTD) + 9/24 - 1/86400)
and o.contragent_n in (1811,1820)
and sysdate between o.fd and o.td
and o.status=3
and d.cnt>0
) d
left join nomenklatura n on (d.nomenklatura_n=n.n)
left join nom_unit u on (n.n=u.nomenklatura_n and n.unit=u.unit_typ and sysdate between u.fd and u.td)
left join c_contragent cc on (d.ccontragent_n=cc.n)
left join client_prop_values ttn  on (d.n=ttn.client_n and ttn.client_prop_items_n=1466 and sysdate between ttn.fd and ttn.td)
left join client_prop_values ttn_date on (d.n=ttn_date.client_n and ttn_date.client_prop_items_n=1467 and sysdate between ttn_date.fd and ttn_date.td)
left join client_prop_values sf on (d.n=sf.client_n and sf.client_prop_items_n=1468 and sysdate between sf.fd and sf.td)
left join client_prop_values sf_date on (d.n=sf_date.client_n and sf_date.client_prop_items_n=1469 and sysdate between sf_date.fd and sf_date.td)
order by d.ddate 