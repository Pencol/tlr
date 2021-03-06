USE [TLR]
GO
/****** Object:  StoredProcedure [dbo].[usp_SELECT_TimesheetGridData_TIME]    Script Date: 1/11/18 6:14:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[usp_SELECT_TimesheetGridData_TIME]
(
	@TimesheetID int
)

AS


--declare @TimeSheetID int
--set @TimesheetID=7521

declare @BeginDate datetime
,@EndDate datetime
,@SID char(9)
select 
@BeginDate = BeginDate
,@EndDate = EndDate 
,@SID = SID
from vw_TimeSheet ts
where ts.TimesheetID=@TimesheetID

--set @BeginDate = '1/1/2010'
--set @EndDate = '1/15/2010'

declare @CalendarStart datetime
,@CalendarEnd datetime

select top 1 @CalendarStart=OneDay
from PayrollCalendar c
where OneDay = DateAdd(day, (select ([DayOfWeek]-1) * -1 from PayrollCalendar where OneDay=@BeginDate), @BeginDate)

select top 1 @CalendarEnd=OneDay
from PayrollCalendar c
where OneDay = DateAdd(day, (select 7-[DayOfWeek] from PayrollCalendar where OneDay=@EndDate), @EndDate)


--WEEKS
select 
c.WeekOfYear as WeekNumber
,c.OneDay as FirstDay
,DATEADD(Day, 6, c.OneDay) as LastDay
,isNULL((select SUM(DateDiff(minute, EntryStartTime, EntryEndTime)-MealBreak) from vw_TimesheetEntry where TimesheetID=@TimeSheetID and EntryDate between c.OneDay and DATEADD(Day, 6, c.OneDay)), 0) as TotalMinutes
,isNULL((select SUM(Datediff(minute, EntryStartTime,EntryEndTime)-MealBreak) from vw_TimesheetEntry where TimesheetID = @TimeSheetID and EntryTypeID IS NOT NULL and EntryDate between c.OneDay and DATEADD(Day, 6, c.OneDay)), 0) as TotalLeaveMinutes
,isNULL((select SUM(DateDiff(minute, EntryStartTime, EntryEndTime)-MealBreak) from vw_TimesheetEntry where SID=@SID and EntryDate between c.OneDay and DATEADD(Day, 6, c.OneDay)), 0) as TotalWeekMinutes
from PayrollCalendar c
where c.OneDay between @CalendarStart and @CalendarEnd
and c.DayOfWeek =1
order by c.OneDay



--DAYS IN EACH WEEK and ENTRIES FOR THOSE DAYS

select 
e.SID
,c.WeekOfYear as WeekNumber
,c1.OneDay
,CASE
	when c1.OneDay between @BeginDate and @EndDate then 1
	else 0
END as InPayPeriod
,c1.SpecialDay
,c1.Description
--,c.OneDay as FirstDay
--,DATEADD(Day, 6, c.OneDay) as LastDay
,isNULL(e.TimesheetEntryID, 0) as TimesheetEntryID
,e.EntryDate
,t.EntryTypeID
,isNULL(t.Title, 'Hours') as EntryType
,e.Duration 
,dbo.uf_FormatDate(e.EntryStartTime, 'h:nn tt') as EntryStartTime
,dbo.uf_FormatDate(e.EntryEndTime, 'h:nn tt') as EntryEndTime
,isNULL(e.MealBreak, 0) as MealBreak
,e.MealBreakWaived
,isNULL(DateDiff(minute, e.EntryStartTime, e.EntryEndTime)-e.MealBreak, 0) as TotalMinutes
,isNULL(dbo.uf_GetTimesheetEntryBudgets(e.TimesheetEntryID), '') as Budgets
from vw_PayrollCalendar c
		left outer join vw_PayrollCalendar c1 on c1.OneDay>=c.OneDay and c1.OneDay <= DATEADD(Day, 6, c.OneDay)
		left outer join vw_TimesheetEntry e on e.EntryDate=c1.OneDay and e.TimesheetID=@TimeSheetID
			left outer join EntryType t on e.EntryTypeID=t.EntryTypeID
where c.OneDay between @CalendarStart and @CalendarEnd
and c.DayOfWeek =1
--and e.TimesheetID=@TimeSheetID
order by c1.OneDay, e.EntryStartTime

