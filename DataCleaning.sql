
-- I will be cleaning the data in this excel file using SQL queries
select *
from PortfolioProject..HousingDating;


--------------
-- Standardizing the date format to remove the time
select saledate, convert(date, saledate)
from PortfolioProject..HousingDating;

/* This query did not update the table, so we will use another command ALTER TABLE
update HousingDating
set saledate = convert(date, saledate);
*/

alter table HousingDating
add saleDateFixed date;

update HousingDating
set saleDateFixed = convert(date, saledate);

select saleDateFixed
from PortfolioProject..HousingDating;

/* remove the original saleDate column so that we are left with saleDateFixed */


---------------

/* Populate ("fill in missing data") property address data

Notice that the same parcleID will have the same PropertyAddress,
so if the PropertyAddress is missing, we can fill it in with what is already known for a parcelID

Join the table to itself so that we can compare rows that are missing using ISNULL
*/
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..HousingDating a
	join PortfolioProject..HousingDating b
		on a.ParcelID = b.ParcelID and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is null;

Update a
set propertyaddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..HousingDating a
	join PortfolioProject..HousingDating b
		on a.ParcelID = b.ParcelID and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is null;


---------------------
/* Slicing address into individual columns (address, city, state)


*/
select PropertyAddress
from PortfolioProject..HousingDating;

/* substring(PropertyAddress, 1, CHARINDEX(' ,', PropertyAddress)) means looking at the first value in the property address
until it reaches the comma, but we don't want to include the comma*/
select 
	substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as address,
	substring(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as city
from PortfolioProject..HousingDating;

alter table HousingDating
add propAddressSplit nvarchar(255);

update HousingDating
set propAddressSplit = substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

alter table HousingDating
add propCitySplit nvarchar(255);

update HousingDating
set propCitySplit = substring(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));

select PropertyAddress, propAddressSplit, propCitySplit
from PortfolioProject..HousingDating;

/* OwnerAddress has address, city, AND state included 
Instead of using substring, we will use PARSENAME by replacing periods with commas

Note: parsename only looks for periods
*/

select 
	parsename(replace(owneraddress, ',', '.'), 3) as adress,
	parsename(replace(owneraddress, ',', '.'), 2) as city,
	parsename(replace(owneraddress, ',', '.'), 1) as state
from PortfolioProject..HousingDating;

alter table HousingDating
add ownerAddressSplit nvarchar(255);

alter table HousingDating
add ownerCitySplit nvarchar(255);

alter table HousingDating
add ownerStateSplit nvarchar(255);

update HousingDating
set ownerAddressSplit = parsename(replace(owneraddress, ',', '.'), 3);

update HousingDating
set ownerCitySplit = parsename(replace(owneraddress, ',', '.'), 2);

update HousingDating
set ownerStateSplit = parsename(replace(owneraddress, ',', '.'), 1);

select ownerAddress, ownerAddressSplit, ownerCitySplit, ownerStateSplit
from PortfolioProject..HousingDating;


--------------
/*  Change Y and N to Yes and No in "Sold as Vacant" field

We will first check to see the distinct entries in the field, and use a case statement to change it

*/

select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject..HousingDating
group by SoldAsVacant;

select SoldAsVacant,
	CASE
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	END
from PortfolioProject..HousingDating;

update HousingDating
set SoldAsVacant = 
	CASE
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	END;


--------------
/* Remove duplicate entries
NOTE: not typically done

*/

--CTE
with rowNumCTE as (
Select *,
	ROW_NUMBER() over (
	partition by ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			order by UniqueID) row_num
from PortfolioProject..HousingDating
)
DELETE
from rowNumCTE
where row_num > 1;

with rowNumCTE as (
Select *,
	ROW_NUMBER() over (
	partition by ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
			order by UniqueID) row_num
from PortfolioProject..HousingDating
)
select *
from rowNumCTE
where row_num > 1
order by PropertyAddress;


/* Deleting unused columns, do not do to raw data */

ALTER TABLE PortfolioProject..HousingDating
DROP COLUMN ownerAddress, PropertyAddress;