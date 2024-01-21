DROP DATABASE IF EXISTS ChinookStaging

CREATE DATABASE ChinookStaging
GO

USE ChinookStaging
GO

DROP TABLE IF EXISTS ChinookStaging.dbo.CustomerStaging;
DROP TABLE IF EXISTS ChinookStaging.dbo.TrackStaging;
DROP TABLE IF EXISTS ChinookStaging.dbo.InvoiceStaging;


--1 data from Customers


SELECT  CustomerID, Company, c.FirstName, c.LastName, c.Address, c.City, c.State, c.PostalCode, c.Country, c.Phone,c.Fax, c.Email, SupportRepId, e.FirstName as EmployeeFirstName, e.LastName as EmployeeLastName
INTO ChinookStaging.dbo.CustomerStaging
FROM Chinook.[dbo].Customer as c
INNER JOIN Chinook.dbo.Employee as e
	ON c.SupportRepId = e.EmployeeId

--2 data from Track 
 

SELECT  TrackId, Track.Name as TrackName, Album.AlbumId, Title as AlbumName, a.ArtistId,
a.Name as ArtistName, m.MediaTypeId, m.Name as MediaTypeName, g.GenreId, g.Name as GenreName, Composer, UnitPrice
INTO ChinookStaging.dbo.TrackStaging
FROM Chinook.[dbo].Track
INNER JOIN Chinook.[dbo].MediaType as m
    ON Chinook.[dbo].Track.MediaTypeId = m.MediaTypeId
INNER JOIN Chinook.[dbo].Genre as g
    ON Chinook.[dbo].Track.GenreId = g.GenreId
INNER JOIN Chinook.[dbo].Album
    ON Chinook.[dbo].Track.AlbumId = Chinook.[dbo].Album.AlbumId
INNER JOIN Chinook.[dbo].Artist as a
    ON Chinook.[dbo].Album.ArtistId = a.ArtistId


--3  data from Invoices


SELECT  Invoice.InvoiceId, TrackId, CustomerId, InvoiceDate, UnitPrice, Quantity, BillingAddress, BillingCity, BillingState, BillingCountry, BillingPostalCode, Total
INTO ChinookStaging.dbo.InvoiceStaging
FROM Chinook.[dbo].Invoice
INNER JOIN Chinook.[dbo].[InvoiceLine]
    ON Chinook.[dbo].Invoice.InvoiceId = Chinook.[dbo].InvoiceLine.InvoiceId





