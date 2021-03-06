USE [TLR]
GO
/****** Object:  StoredProcedure [dbo].[usp_SELECT_FileList]    Script Date: 1/5/18 1:12:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[usp_SELECT_FileList]
(
	@TimesheetTypeID int
	,@YearNumber int
)
AS

/*
Generates a list files that were exported in a given year
for a given TimesheetType (Leave or Hourly)
*/
if @TimesheetTypeID = 2
	select 
	distinct ExportFileName
	,e.DisplayName
	,d.CreatedOn
	from ExportLeaveData d
	left outer join vw_Employee e on d.CreatedBy = e.SID
	where DatePart(year, CreatedOn) = @YearNumber
	and left(ExportFileName, 1) = 'L'	--make sure to pull only salaried leave file data
	order by CreatedOn DESC

if @TimesheetTypeID = 1	
	select 
	distinct ExportFileName
	,e.DisplayName
	,d.CreatedOn
	from ExportTimeData d
	left outer join vw_Employee e on d.CreatedBy = e.SID
	where DatePart(year, CreatedOn) = @YearNumber
	
	union
	
	select 
	distinct ExportFileName
	,e.DisplayName
	,d.CreatedOn
	from ExportLeaveData d
	left outer join vw_Employee e on d.CreatedBy = e.SID
	where DatePart(year, CreatedOn) = @YearNumber
	and left(ExportFileName, 2) = 'HL'	-- pull only hourly leave file data

	order by CreatedOn DESC
