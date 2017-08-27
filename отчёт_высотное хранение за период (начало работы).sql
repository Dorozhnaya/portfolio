-- Сколько всего ячеек на складе
select 1 typ, 0 nom, (to_char(store_n) || ' ' || s.name || ' всего') as nam, sel.dat dat, count (ca.addr) cnt
from cell_address ca join store s on ca.store_n = s.n
    join
    (select trunc(:PDateT + 1 - level) as dat from dual
    connect by level <= to_number(trunc(:PDateT - :PDateF + 1))) sel
        on dat between ca.fd and ca.td
    where 
        ca.store_n = :PStore
        and (ca.cell_typ_n = 1 or ca.cell_typ_n = -1)
        and ca.pall_typ = 1
    group by store_n, s.name, sel.dat


union all

-- Сколько заполненных ячеек на складе
select 1 typ, 0 nom, nam, dat, sum(cnt) cnt
from
    ((select 0 nom, nam, dat, sum(cnt) cnt
    from
        (select s.nam, s.dat, s.typ, decode(typ, 2, cnt, 4, cnt, 5, cnt, 6, cnt, 7, cnt*4) cnt
        from
            (select to_char(sel1.store_n) || ' ' || s.name || ' занято' as nam, sel1.dat dat, sel1.pall_type typ, count(sel1.cell_address_n) cnt
            from
                (select distinct ss.store_n, sel.dat, ss.pall_type, ss.cell_address_n
                from st_stock ss 
                    join client_prop_values cpv on
                        ss.contragent_n = cpv.client_n 
                        and cpv.client_prop_items_n = 1248 
                        and cpv.val_str = '1'
                    join cell_address ca on
                        ss.cell_address_n = ca.n
                        and (ca.cell_typ_n = 1 or ca.cell_typ_n = -1)
                        and ca.pall_typ = 1
                    join
                    (select trunc(:PDateT + 1 - level) as dat from dual
                    connect by level <= to_number(trunc(:PDateT - :PDateF + 1))) sel
                        on dat between ss.fd and ss.td
                        and dat between cpv.fd and cpv.td
                    where
                        ss.store_n = :PStore
                        and ss.pall_type in (2,4,5,6,7)
                ) sel1
                left join store s on sel1.store_n = s.n
                group by sel1.store_n, s.name, sel1.dat, sel1.pall_type
            ) s
        )
    group by nam, dat)
    
    union all
    
    (select 0 nom, to_char(sel1.store_n) || ' ' || s.name || ' занято' as nam, sel1.dat dat, count(sel1.cell_address_n) cnt
    from
        (select distinct ss.store_n, sel.dat, ss.cell_address_n
        from st_stock ss 
            join client_prop_values cpv on
                ss.contragent_n = cpv.client_n 
                and cpv.client_prop_items_n = 1248 
                and cpv.val_str = '1'
            join cell_address ca on
                ss.cell_address_n = ca.n
                and (ca.cell_typ_n = 1 or ca.cell_typ_n = -1)
                and ca.pall_typ = 1
            join
            (select trunc(:PDateT + 1 - level) as dat from dual
            connect by level <= to_number(trunc(:PDateT - :PDateF + 1))) sel
                on dat between ss.fd and ss.td
                and dat between cpv.fd and cpv.td
            where
                ss.store_n = :PStore
        ) sel1
        left join store s on sel1.store_n = s.n
        group by sel1.store_n, s.name, sel1.dat))
group by nam, dat


union all

-- Сколько заполненных ячеек по контрагентам
select 1 typ, cntr.n nom, cntr.name nam, cntr.dat dat, to_number(nvl(to_char(stck.cnt), '0')) cnt
from
    ((select names.n, names.name, dates.dat
    from
        (select distinct ct.n, ct.name
        from
            st_stock ss
            join cell_address ca 
                on ss.cell_address_n = ca.n
                and (ca.cell_typ_n = 1 or ca.cell_typ_n = -1)
                and ca.pall_typ = 1
            join client_prop_values cpv
                on ss.contragent_n = cpv.client_n
                and cpv.client_prop_items_n = 1248 
                and cpv.val_str = '1'
            join
            (select trunc(:PDateT + 1 - level) as dat from dual
            connect by level <= to_number(trunc(:PDateT - :PDateF + 1))) sel
                on dat between ss.fd and ss.td
                and dat between cpv.fd and cpv.td
            join contragent ct
                on ss.contragent_n = ct.n
            where ss.store_n = :PStore
        ) names              
        
        full join
        (select trunc(:PDateT + 1 - level) as dat from dual
        connect by level <= to_number(trunc(:PDateT - :PDateF + 1))) dates
            on 1=1
    ) cntr

    left join

    (select nom, dat, sum(cnt) cnt
    from
        ((select nom, dat, sum(cnt) cnt
        from
            (select s.nom, s.dat, s.typ, decode(typ, 2, cnt, 4, cnt, 5, cnt, 6, cnt, 7, cnt*4) cnt
            from
                (select nom, sel1.dat dat, sel1.pall_type typ, count(sel1.cell_address_n) cnt
                from
                    (select distinct ss.contragent_n nom, sel.dat, ss.pall_type, ss.cell_address_n
                    from st_stock ss 
                        join client_prop_values cpv on
                            ss.contragent_n = cpv.client_n 
                            and cpv.client_prop_items_n = 1248 
                            and cpv.val_str = '1'
                        join cell_address ca on
                            ss.cell_address_n = ca.n
                            and (ca.cell_typ_n = 1 or ca.cell_typ_n = -1)
                            and ca.pall_typ = 1
                        join
                        (select trunc(:PDateT + 1 - level) as dat from dual
                        connect by level <= to_number(trunc(:PDateT - :PDateF + 1))) sel
                            on dat between ss.fd and ss.td
                            and dat between cpv.fd and cpv.td
                        where
                            ss.store_n = :PStore
                            and ss.pall_type in (2,4,5,6,7)
                    ) sel1
                    group by sel1.nom, sel1.dat, sel1.pall_type
                ) s
            )
        group by nom, dat)
    
        union all
    
        (select sel1.nom nom, sel1.dat dat, count(sel1.cell_address_n) cnt
        from
            (select distinct ss.contragent_n nom, sel.dat, ss.cell_address_n
            from st_stock ss 
                join client_prop_values cpv on
                    ss.contragent_n = cpv.client_n 
                    and cpv.client_prop_items_n = 1248 
                    and cpv.val_str = '1'
                join cell_address ca on
                    ss.cell_address_n = ca.n
                    and (ca.cell_typ_n = 1 or ca.cell_typ_n = -1)
                    and ca.pall_typ = 1
                join
                (select trunc(:PDateT + 1 - level) as dat from dual
                connect by level <= to_number(trunc(:PDateT - :PDateF + 1))) sel
                    on dat between ss.fd and ss.td
                    and dat between cpv.fd and cpv.td
                where
                    ss.store_n = :PStore
            ) sel1
        group by sel1.nom, sel1.dat))
    group by nom, dat
    ) stck

        on cntr.n = stck.nom
        and cntr.dat = stck.dat)
    
order by typ, nom, nam, dat desc
