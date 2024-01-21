USE ChinookDataWarehouse


INSERT INTO DimCustomer(CustomerID,Company,FirstName,LastName,Address,City,State,PostalCode,Country,Phone,Fax,Email,SupportRepId,EmployeeFirstName,EmployeeLastName)
    SELECT * FROM ChinookStaging.dbo.CustomerStaging


INSERT INTO DimTrack(TrackId,Name,AlbumId,Title,ArtistId,ArtistName,MediaTypeId,MediaTypeName,GenreId,GenreName,Composer, UnitPrice)
SELECT *FROM ChinookStaging.dbo.TrackStaging



INSERT INTO FactInvoice
SELECT InvoiceId, Datekey, CustomerKey, TrackKey,
    InvoiceDate, i.UnitPrice,
    Quantity, Total
FROM 
    ChinookStaging.dbo.InvoiceStaging AS i
INNER JOIN ChinookDataWarehouse.dbo.DimCustomer AS c
    ON c.CustomerId=i.CustomerId
INNER JOIN ChinookDataWarehouse.dbo.DimTrack AS t
    ON t.TrackId=i.TrackId
INNER JOIN ChinookDataWarehouse.dbo.DimDate AS d
    ON d.Date=i.InvoiceDate


ALTER TABLE FactInvoice ADD CONSTRAINT FK_FactTrack FOREIGN KEY (TrackKey)
    REFERENCES DimTrack(TrackKey);

ALTER TABLE FactInvoice ADD CONSTRAINT FK_FactCustomer FOREIGN KEY (CustomerKey)
    REFERENCES DimCustomer(CustomerKey);

ALTER TABLE FactInvoice ADD CONSTRAINT FK_FactDate FOREIGN KEY (DateKey)
    REFERENCES DimDate(DateKey);




