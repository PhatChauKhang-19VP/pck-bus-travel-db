﻿use pck_bus_travel
go

/*
json format:
@ds_kh_dk
[
{"stt": 1, "ten": "ho va ten kh", "sdt": "sdt kh", "cccd": "cccd kh", "ngay_sinh_kh": "DD-MM-YYYY"},
...
]
@ds_phong_dk
[
{"stt": 1, "loai_phong": "loai phong"},
...
]

*/
create proc usp_dk_tour
	@ma_tour varchar(255),
	@mo_lan_thu int,
	@ma_kh_dk varchar(255),
	@ds_kh_dk nvarchar(max),
	@ma_ks int,
	@ds_phong_dk nvarchar(max)
as
begin

begin try
    begin tran

	declare @get_ds_kh_dk cursor

	-- insert to khach_hang_dang_ki
	set @get_ds_kh_dk = cursor for (
			select * from openjson(@ds_kh_dk) with (
				stt int 'strict $.stt',
				ten nvarchar(255) '$.ten',
				sdt char(10) '$.sdt',
				cccd char(20) '$.cccd',
				ngay_sinh_kh date '$.ngay_sinh_kh'
			)
		)
	declare @stt_ds_kh_dk int
	declare @ten nvarchar(255)
	declare @sdt char(10)
	declare @cccd varchar(20)
	declare @ngay_sinh_kh date
	open @get_ds_kh_dk
	fetch next from @get_ds_kh_dk into @stt_ds_kh_dk, @ten, @sdt, @cccd, @ngay_sinh_kh
	while @@FETCH_STATUS = 0
	begin
		insert into khach_hang_dang_ki 
			(ma_tour, mo_lan_thu, ma_kh_dk, stt, ten, ngay_sinh, cccd, sdt) values 
			(@ma_tour, @mo_lan_thu, @ma_kh_dk, @stt_ds_kh_dk, @ten, @ngay_sinh_kh, @cccd, @sdt)

		fetch next from @get_ds_kh_dk into @stt_ds_kh_dk, @ten, @sdt, @cccd, @ngay_sinh_kh
	end

	close @get_ds_kh_dk
	deallocate @get_ds_kh_dk


	-- insert into dang_ki_phong
	declare @get_ds_phong cursor

	-- insert to khach_hang_dang_ki
	set @get_ds_phong = cursor for (
			select * from openjson(@ds_phong_dk) with (
				stt int 'strict $.stt',
				loai_phong int '$.ma_loai_phong_ks'
			)
		)
	declare @stt_dk_phong int
	declare @loai_phong int

	open @get_ds_phong
	fetch next from @get_ds_phong into @stt_dk_phong, @loai_phong
	while @@FETCH_STATUS = 0
	begin
		insert into dang_ki_phong 
			(ma_tour, mo_lan_thu, ma_kh_dk, stt, ma_ks, ma_loai_phong_ks) values 
			(@ma_tour, @mo_lan_thu, @ma_kh_dk, @stt_dk_phong, @ma_ks, @loai_phong)

		fetch next from @get_ds_phong into @stt_dk_phong, @loai_phong
	end

	close @get_ds_phong
	deallocate @get_ds_phong

    commit tran -- Transaction Success!
end try
begin catch
    if @@trancount > 0
        rollback tran --RollBack in case of Error

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()

		print @ErrorMessage
end catch
end
go

-- TEST usp_dk_tour
	--@ma_tour varchar(255),
	--@mo_lan_thu int,
	--@ma_kh_dk varchar(255),
	--@ds_kh_dk nvarchar(max),
	--@ma_ks int,
	--@ds_phong_dk nvarchar(max)
--exec dbo.usp_dk_tour 
--	@ma_tour = 'tour1', 
--	@mo_lan_thu = 1, 
--	@ma_kh_dk = 'kh1', 
--	@ds_kh_dk = N'[{"stt": 1, "ten": "ho va ten kh 1", "sdt": "sdt kh", "cccd": "cccd kh", "ngay_sinh_kh": "06-01-2001"},{"stt": 2, "ten": "ho va ten kh 2", "sdt": "sdt kh", "cccd": "cccd kh", "ngay_sinh_kh": "06-01-2001"}]',
--	@ma_ks = 1,
--	@ds_phong_dk =N'[{"stt": 1, "ma_loai_phong_ks": 1},{"stt": 2, "ma_loai_phong_ks": 2}]'

--select * from khach_hang_dang_ki
--select * from dang_ki_phong
--delete khach_hang_dang_ki
--delete dang_ki_phong

-- TIM TOUR
/*
	@ma_tour nvarchar(255),
	@ten_tour nvarchar(255),
	@from_so_ngay int,
	@to_so_ngay int,
	@from_gia_tien float,
	@to_gia_tien float,
	@ds_ma_tinh nvarchar(max), [{"ma_tinh": "xxx"},...]
	@ds_dia_diem nvarchar(max)
*/
create proc usp_tim_tour_not_op
	@ma_tour nvarchar(255),
	@ten_tour nvarchar(255),
	@from_so_ngay int,
	@to_so_ngay int,
	@from_gia_tien float,
	@to_gia_tien float,
	@ds_ma_tinh nvarchar(max),
	@ds_ma_dia_diem nvarchar(max)
as
begin
	print 'usp_tim_tour_not_op'

	if @ma_tour is null
		set @ma_tour = ''
	if @ten_tour is null
		set @ten_tour = ''
	if @from_so_ngay is null
		set @from_so_ngay = -1
	if @to_so_ngay is null
		set @to_so_ngay = 2147483647
	if @from_gia_tien is null
		set @from_gia_tien = -1
	if @to_gia_tien is null
		set @to_gia_tien = 1000000000
	if @ds_ma_tinh is null
		set @ds_ma_tinh ='[]'
	if @ds_ma_dia_diem is null
		set @ds_ma_dia_diem = '[]'


	select * from tours as t
		where t.ma_tour like '%' + @ma_tour + '%'
			and t.ten_tour like '%' + @ten_tour + '%'
			and t.so_ngay >= @from_so_ngay and t.so_ngay <= @to_so_ngay
			and t.gia_tien_dk >= @from_gia_tien and t.gia_tien_dk <= @to_gia_tien
			and t.ma_tour in (select lot.ma_tour 
								from lo_trinh as lot
								where @ds_ma_tinh ='[]' or lot.noi_den in (select * from openjson(@ds_ma_tinh) 
														with (ma_tinh varchar(20) '$.ma_tinh')))
			and t.ma_tour in (select lit.ma_tour 
								from lich_trinh as lit
								where @ds_ma_dia_diem = '[]' or lit.ma_dia_diem in (select * from openjson(@ds_ma_dia_diem) 
														with (ma_dia_diem varchar(20) '$.ma_dia_diem')))
end
go

exec usp_tim_tour_not_op
	@ma_tour = null,
	@ten_tour = null,
	@from_so_ngay = 3,
	@to_so_ngay = 4,
	@from_gia_tien = null,
	@to_gia_tien = null,
	@ds_ma_tinh = null,
	@ds_ma_dia_diem = null


create proc usp_tao_tour
	@ma_tour varchar(255),
	@ten_tour nvarchar(255),
	@so_ngay int,
	@gia_tien_dk float,
	@ma_nv varchar(255),
	@ds_lo_trinh nvarchar(max),
	@ds_lich_trinh nvarchar(max)
as
begin
begin try
begin tran

-- insert to tours
insert into tours values (@ma_tour, @ten_tour, @so_ngay, CURRENT_TIMESTAMP, @gia_tien_dk, @ma_nv)

declare @get_lo_trinh cursor

set @get_lo_trinh = cursor for (
		select * from openjson(@ds_lo_trinh) with (
			stt int 'strict $.stt',
			noi_khoi_hanh int '$.noi_khoi_hanh',
			noi_den int '$.noi_den',
			tg_di_chuyen float '$.tg_di_chuyen',
			ma_ks int '$.ma_ks'
		)
	)
declare @stt_lo_trinh int
declare @noi_khoi_hanh int
declare @noi_den int
declare @tg_di_chuyen float
declare @ma_ks int

open @get_lo_trinh
fetch next from @get_lo_trinh into @stt_lo_trinh, @noi_khoi_hanh, @noi_den, @tg_di_chuyen, @ma_ks
while @@FETCH_STATUS = 0
begin
	insert into lo_trinh 
		(ma_tour, stt, noi_khoi_hanh, noi_den, tg_di_chuyen, ma_ks) values 
		(@ma_tour, @stt_lo_trinh, @noi_khoi_hanh, @noi_den, @tg_di_chuyen, @ma_ks)

	fetch next from @get_lo_trinh into @stt_lo_trinh, @noi_khoi_hanh, @noi_den, @tg_di_chuyen, @ma_ks
end

close @get_lo_trinh
deallocate @get_lo_trinh


-- insert into dang_ki_phong
declare @get_lich_trinh cursor

set @get_lich_trinh = cursor for (
		select * from openjson(@ds_lich_trinh) with (
			stt int 'strict $.ngay_thu',
			ten time '$.tg_bat_dau',
			sdt time '$.tg_ket_thuc',
			cccd int '$.ma_dia_diem'
		)
	)
declare @ngay_thu int
declare @tg_bat_dau time
declare @tg_ket_thuc time
declare @ma_dia_diem int

open @get_lich_trinh
fetch next from @get_lich_trinh into @ngay_thu, @tg_bat_dau, @tg_ket_thuc, @ma_dia_diem
while @@FETCH_STATUS = 0
begin
	insert into lich_trinh 
		(ma_tour, ngay_thu, tg_bat_dau, tg_ket_thuc, ma_dia_diem) values 
		(@ma_tour, @ngay_thu, @tg_bat_dau, @tg_ket_thuc, @ma_dia_diem)

	fetch next from @get_lich_trinh into @ngay_thu, @tg_bat_dau, @tg_ket_thuc, @ma_dia_diem

end

close @get_lich_trinh
deallocate @get_lich_trinh

commit tran -- Transaction Success!
end try
begin catch
if @@trancount > 0
    rollback tran --RollBack in case of Error

	DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()

	print @ErrorMessage
end catch
end
go

exec usp_tao_tour
	@ma_tour = 'tour2',
	@ten_tour  = 'Ngô',
	@so_ngay = 2,
	@gia_tien_dk = 1000,
	@ma_nv = '6992SUL6O4G669J13',
	@ds_lo_trinh = N'[{"stt": 1, "noi_khoi_hanh": 17, "noi_den": 19, "tg_di_chuyen": 5.5, "ma_ks": 1}]',
	@ds_lich_trinh =  N'[
			{"ngay_thu" : 1, "tg_bat_dau": "7:00", "tg_ket_thuc": "8:00", "ma_dia_diem": 8},
			{"ngay_thu" : 2, "tg_bat_dau": "7:00", "tg_ket_thuc": "8:00", "ma_dia_diem": 8}
		]'

--select code from PROVINCES

--select top (10) * from ADDRESSES