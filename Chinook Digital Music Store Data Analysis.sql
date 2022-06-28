--Question 1: Which countries have the most Invoices?
SELECT count("CustomerId") AS "number_of_invoice",
    "BillingCountry"
    FROM "Invoice"
GROUP BY "BillingCountry"
ORDER BY "number_of_invoice" DESC


/* Question 2: Which city has the best customers? 
We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns the 1 city that has the highest sum of invoice totals. 
Return both the city name and the sum of all invoice totals.*/
SELECT "BillingCity",
    sum("Total") AS "Invoice_total"
    FROM "Invoice"
GROUP BY "BillingCity"
ORDER BY "Invoice_total" DESC
LIMIT 1



/*Question 3: Who is the best customer?
The customer who has spent the most money will be declared the best customer. 
Build a query that returns the person who has spent the most money. 
Invoice, InvoiceLine, and Customer tables to retrieve this information*/
SELECT concat(a."FirstName",' ',a."LastName") AS "full_name",
    a."CustomerId",
    sum("Total") AS "money_spent"
    FROM "Customer" AS a
JOIN "Invoice" AS b ON a."CustomerId"=b."InvoiceId"
GROUP BY a."CustomerId","full_name"
ORDER BY money_spent DESC
LIMIT 1;

/***** 06. SQL: Question Set 2 *****/

/*Question 1:
Use your query to return the email, first name, last name, and Genre of all Rock Music listeners.
Return your list ordered alphabetically by email address starting with A.*/

SELECT DISTINCT "Email","FirstName","LastName"
    FROM "Customer"
JOIN "Invoice" ON "Customer"."CustomerId"= "Invoice"."CustomerId"
JOIN "InvoiceLine" ON "Invoice"."InvoiceId"= "InvoiceLine"."InvoiceId"
WHERE "TrackId" IN (
        SELECT "TrackId" FROM "Track" 
        JOIN "Genre" ON  "Track"."GenreId"= "Genre"."GenreId"
        WHERE "Genre"."Name" LIKE 'Rock'
)
ORDER BY "Customer"."Email" ASC


/*Question 2: Who is writing the rock music?
Now that we know that our customers love rock music, we can decide which musicians to invite to play at the concert.
Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands.*/

SELECT "Artist"."Name",
    count("public"."Track"."TrackId") AS "Track_count"
    FROM "Artist"
JOIN "Album" ON "Artist"."ArtistId"= "Album"."ArtistId"
JOIN "Track" ON "Album"."AlbumId" = "Track"."AlbumId"
JOIN "Genre" ON "Track"."GenreId" = "Genre"."GenreId"
WHERE "Genre"."Name" LIKE 'Rock' 
GROUP BY "Artist"."Name"
ORDER BY "Track_count" DESC
LIMIT 10;




/*Question 3
First, find which artist has earned the most according to the InvoiceLines?
Now use this artist to find which customer spent the most on this artist.
For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, Album, and Artist tables.
Notice, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, 
and then multiply this by the price for each artist.*/
WITH "best_selling_artist" AS (
        SELECT sum("Quantity" * "public"."InvoiceLine"."UnitPrice") AS "total_sales","Artist"."ArtistId","Artist"."Name"
        FROM "InvoiceLine"
        JOIN "Track" ON "InvoiceLine"."TrackId" = "Track"."TrackId"
        JOIN "Album" ON "Track"."AlbumId" = "Album"."AlbumId"
        JOIN "Artist" ON "Album"."ArtistId"= "Artist"."ArtistId"
        JOIN "Invoice" ON  "InvoiceLine"."InvoiceId" = "Invoice"."InvoiceId"
        GROUP BY "Artist"."Name","Artist"."ArtistId"
        ORDER BY "total_sales" DESC
        LIMIT 1
)

SELECT bsa."Name", sum("Quantity" *"InvoiceLine"."UnitPrice") AS "total_sales","Customer"."FirstName","Customer"."LastName"
FROM "Invoice"
JOIN "Customer" ON  "Invoice"."CustomerId" = "Customer"."CustomerId"
JOIN "InvoiceLine" ON  "InvoiceLine"."InvoiceId" = "Invoice"."InvoiceId"
JOIN "Track" ON "InvoiceLine"."TrackId" = "Track"."TrackId"
JOIN "Album" ON "Track"."AlbumId" = "Album"."AlbumId"
JOIN "best_selling_artist" AS bsa ON bsa."ArtistId" = "Album"."ArtistId"
GROUP BY 1,"Customer"."FirstName","Customer"."LastName"
ORDER BY "total_sales" DESC
LIMIT 1;

/**** 07. (Advanced) SQL: Question Set 3 *****/

/*Question 1:
We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres.*/

WITH RECURSIVE
    tbl_sales_per_country AS (
            SELECT count(*) AS "purchases_per_genre","Customer"."Country","Genre"."GenreId","Genre"."Name"
            FROM "InvoiceLine"
            JOIN "Invoice" ON  "InvoiceLine"."InvoiceId" = "Invoice"."InvoiceId"
            JOIN "Customer" ON "Invoice"."CustomerId" = "Customer"."CustomerId"
            JOIN "Track" ON "InvoiceLine"."TrackId" = "Track"."TrackId"
            JOIN "Genre" ON "Track"."GenreId" = "Genre"."GenreId"
            GROUP BY 2,3,4
            ORDER BY 2
        ),
    tbl_max_genre_per_country AS (
            SELECT max("purchases_per_genre") AS "max_genre_number",
            "Country" 
            FROM tbl_"sales_per_country"
            GROUP BY 2
            ORDER BY 2
    )
SELECT tbl_sales_per_country.*
FROM tbl_sales_per_country
JOIN tbl_max_genre_per_country ON tbl_sales_per_country."Country" = tbl_max_genre_per_country."Country"
WHERE tbl_sales_per_country."purchases_per_genre" = tbl_max_genre_per_country."max_genre_number"

/*Question 2:
Return all the track names that have a song length longer than the average song length. 
Though you could perform this with two queries. 
Imagine you wanted your query to update based on when new data is put in the database. 
Therefore, you do not want to hard code the average into your query. You only need the Track table to complete this query.
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.*/

SELECT "Name","Milliseconds"
FROM "Track"
WHERE "Milliseconds" > (
            SELECT avg("Milliseconds") 
            FROM "Track"
)
ORDER BY "Milliseconds" DESC

/*Question 3:
Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount.
You should only need to use the Customer and Invoice tables.*/
-- 
WITH RECURSIVE
    tbl_customer_with_money AS (
        SELECT "Customer"."CustomerId","FirstName","LastName","BillingCountry",sum("Total") AS total_money_spent
        FROM "Invoice"
        JOIN "Customer" ON "Customer"."CustomerId" = "Invoice"."CustomerId"
        GROUP BY 1,2,3,4
        ORDER BY 2,3 DESC
    ),
    
    tbl_max_spent AS (
        SELECT max(total_money_spent) AS "max_spent_money","BillingCountry"
        FROM tbl_customer_with_money
        GROUP BY "BillingCountry"
    )
SELECT tbl_customer_with_money.*
FROM tbl_customer_with_money
JOIN tbl_max_spent ON tbl_customer_with_money."BillingCountry" = tbl_max_spent."BillingCountry"
WHERE tbl_customer_with_money.total_money_spent = tbl_max_spent.max_spent_money
ORDER BY 1

    
    