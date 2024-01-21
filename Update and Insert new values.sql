USE Chinook
-- update
update Chinook.[dbo].[Customer] set 
	FirstName = 'Louis'
where [CustomerId] =1;

-- new customer
INSERT INTO Customer
 ([CustomerId], [FirstName], [LastName], [Company],
  [Address], [City]
  ,[Country], [PostalCode]
  ,[Phone],[Fax], [Email], [SupportRepId])
VALUES
 (60, 'John', 'Smith', 'Smith Company'
 ,'Dummy Address','Athens','Greece',11526
 ,'12345678901', 'xxxx', 'smith@gmail.com', 4 );

--new sale
INSERT INTO Invoice
Values (413, 60, '2023-12-21', 'Dummy Address', 'Athens', NULL, 'Greece', 11526, 0.99)

INSERT INTO InvoiceLine
Values (2241, 413, 1, 0.99, 1)

--new sale
INSERT INTO Invoice
Values (414, 1, '2023-12-21', 'Av. Brigadeiro Faria Lima, 2170', 'São José dos Campos','SP', 'Brazil', 12227-000, 0.99)

INSERT INTO InvoiceLine
Values (2242, 414, 2, 0.99, 1)

drop table [ChinookStaging].[dbo].[CustomerStaging]; 

SELECT  CustomerID, Company, c.FirstName, c.LastName, c.Address, c.City, c.State, c.PostalCode, c.Country, c.Phone,c.Fax, c.Email, SupportRepId, e.FirstName as EmployeeFirstName, e.LastName as EmployeeLastName
INTO ChinookStaging.dbo.Customer
FROM Chinook.[dbo].Customer as c
INNER JOIN Chinook.dbo.Employee as e
	ON c.SupportRepId = e.EmployeeId

USE ChinookStaging

insert into InvoiceStaging
	([InvoiceId]
      ,[CustomerId]
      ,[InvoiceDate]
      ,[TrackId]
      ,[UnitPrice]
      ,[Quantity]
      ,[Total])
select
       l.[InvoiceId]
      ,[CustomerId]
      ,[InvoiceDate]
      ,[TrackId]
      ,[UnitPrice]
      ,[Quantity]
      ,[Total]
from [Chinook].[dbo].Invoice i
	inner join [Chinook].[dbo].[InvoiceLine] l on i.InvoiceId= l.InvoiceId
where InvoiceDate>='2023-12-20';


drop table if exists [ChinookStaging].[dbo].Staging_DimCustomer;

create table [ChinookStaging].[dbo].Staging_DimCustomer (
        [CustomerKey] [int] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NULL,
	[FirstName] [nvarchar](40) NULL,
	[LastName] [nvarchar](20) NULL,
	[Company] [nvarchar](80) NULL,
	[Address] [nvarchar](70) NULL,
	[City] [nvarchar](40) NULL,
	[State] [nvarchar](40) NULL,
	[Country] [nvarchar](40) NULL,
	[PostalCode] [nvarchar](10) NULL,
	[Phone] [nvarchar](24) NULL,
	[Fax] [nvarchar](24) NULL,
	[Email] [nvarchar](60) NULL,
	[SupportRepId] [int] NULL,
	[EmployeeFirstName] [nvarchar](20) NULL,
	[EmployeeLastName] [nvarchar](20) NULL,
	[RowIsCurrent] [int] DEFAULT 1 NOT NULL,
	[RowStartDate] [date] DEFAULT '2009-01-01' NOT NULL,
	[RowEndDate] [date] DEFAULT '9999-12-31' NOT NULL,
	[RowChangeReason] [varchar](200) NULL,
);

Insert into [ChinookStaging].[dbo].Staging_DimCustomer( 
	CustomerId,FirstName ,LastName,Company,
Address,City,State,Country,PostalCode,Phone,Fax,Email,SupportRepId, EmployeeFirstName, EmployeeLastName)
	(Select CustomerId,FirstName ,LastName,Company,
         Address,City,State,Country,
         case when [PostalCode] is null then 'n/a' else [PostalCode] end,Phone,Fax,Email,SupportRepId, EmployeeFirstName, EmployeeLastName
from [ChinookStaging].[dbo].[Customer]);

USE ChinookDataWarehouse

ALTER TABLE FactInvoice DROP CONSTRAINT FK_FactDate;
 
ALTER TABLE FactInvoice DROP CONSTRAINT FK_FactTrack;
 
ALTER TABLE FactInvoice DROP CONSTRAINT FK_FactCustomer;



declare @etldate date = '2023-12-21';
INSERT INTO [ChinookDataWarehouse].[dbo].DimCustomer
 ([CustomerId],[FirstName],[LastName],[Company],[Address],[City]
      ,[State],[Country],[PostalCode],[Phone],[Fax],[Email],[SupportRepId], [EmployeeFirstName], [EmployeeLastName]
        , [RowStartDate], [RowChangeReason])
SELECT 
      [CustomerId],[FirstName],[LastName],[Company],[Address],[City]
      ,[State],[Country],[PostalCode],[Phone],[Fax],[Email],[SupportRepId], [EmployeeFirstName], [EmployeeLastName]
        , @etldate 	  ,ActionName
FROM
(
	MERGE [ChinookDataWarehouse].[dbo].DimCustomer AS target 
		USING [ChinookStaging].[dbo].Staging_DimCustomer as source
		ON target.[CustomerId] = source.[CustomerId]
	 WHEN MATCHED 	 AND 
	 source.FirstName <> target.FirstName 
	 AND target.[RowIsCurrent] = 1 
	 THEN UPDATE SET
		 target.RowIsCurrent = 0,
		 target.RowEndDate = dateadd(day, -1, @etldate),
		 target.RowChangeReason = 'UPDATED NOT CURRENT'
	 WHEN NOT MATCHED THEN
	   INSERT  (
       [CustomerId],[FirstName]
      ,[LastName],[Company],[Address],[City]
      ,[State],[Country],[PostalCode],[Phone]
      ,[Fax],[Email],[SupportRepId], [EmployeeFirstName], [EmployeeLastName],
      [RowStartDate], [RowChangeReason])
	   VALUES( source.CustomerId, source.FirstName
      ,source.LastName,source.Company,source.Address,source.City
      ,source.State,source.Country,source.PostalCode,source.Phone
      ,source.Fax,source.Email,source.SupportRepId, source.EmployeeFirstName, source.EmployeeLastName
		   ,CAST(@etldate AS Date),
		   'NEW RECORD'
	   )
	WHEN NOT MATCHED BY Source THEN
		UPDATE SET 
			Target.RowEndDate= dateadd(day, -1, @etldate )
			,target.RowIsCurrent = 0
			,Target.RowChangeReason  = 'SOFT DELETE'
	OUTPUT 
	  source.CustomerId,source.FirstName
      ,source.LastName,source.Company,source.Address,source.City
      ,source.State,source.Country,source.PostalCode,source.Phone
      ,source.Fax,source.Email,source.SupportRepId, source.EmployeeFirstName, source.EmployeeLastName
		,$Action as ActionName   
) AS Mrg
WHERE Mrg.ActionName='UPDATE'
AND [CustomerId] IS NOT NULL;

INSERT INTO [ChinookDataWarehouse].[dbo].FactInvoice(
    InvoiceId, DateKey, CustomerKey, TrackKey, InvoiceDate, UnitPrice, Quantity, Total)
SELECT i.InvoiceId, d.DateKey, c.CustomerKey, t.TrackKey, i.InvoiceDate, i.UnitPrice, i.Quantity, i.Total
FROM 
    ChinookStaging.dbo.InvoiceStaging AS i
INNER JOIN ChinookDataWarehouse.dbo.DimCustomer AS c
    ON c.CustomerId=i.CustomerId and c.RowIsCurrent=1
INNER JOIN ChinookDataWarehouse.dbo.DimTrack AS t
    ON t.TrackId=i.TrackId  and c.RowIsCurrent=1
INNER JOIN ChinookDataWarehouse.dbo.DimDate AS d
    ON d.Date=i.InvoiceDate and c.RowIsCurrent=1
WHERE InvoiceDate>='2023-12-20'